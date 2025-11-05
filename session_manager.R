#' Session Persistence Manager for surroNMA Dashboard
#' @description Save, load, and manage analysis sessions
#' @version 5.0
#'
#' Features:
#' - Save complete analysis states (data, network, fit, results)
#' - Load previous sessions
#' - Auto-save functionality
#' - Session versioning
#' - Export/import sessions
#' - Session metadata and tagging

library(R6)
library(DBI)
library(RSQLite)

# ============================================================================
# SESSION MANAGER
# ============================================================================

#' Session Manager Class
#' @export
SessionManager <- R6::R6Class("SessionManager",
  public = list(
    db_path = NULL,
    conn = NULL,
    storage_dir = NULL,

    initialize = function(db_path = "surronma_sessions.db",
                         storage_dir = "session_storage") {
      self$db_path <- db_path
      self$storage_dir <- storage_dir

      # Create storage directory
      if (!dir.exists(storage_dir)) {
        dir.create(storage_dir, recursive = TRUE)
      }

      self$connect()
      self$create_tables()
    },

    connect = function() {
      self$conn <- dbConnect(SQLite(), self$db_path)
    },

    disconnect = function() {
      if (!is.null(self$conn)) {
        dbDisconnect(self$conn)
      }
    },

    create_tables = function() {
      # Sessions table
      dbExecute(self$conn, "
        CREATE TABLE IF NOT EXISTS analysis_sessions (
          session_id TEXT PRIMARY KEY,
          user_id INTEGER NOT NULL,
          session_name TEXT NOT NULL,
          description TEXT,
          tags TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          last_accessed TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          version INTEGER DEFAULT 1,
          is_public INTEGER DEFAULT 0,
          file_path TEXT NOT NULL,
          file_size INTEGER,
          data_checksum TEXT,
          metadata TEXT
        )
      ")

      # Session versions table
      dbExecute(self$conn, "
        CREATE TABLE IF NOT EXISTS session_versions (
          version_id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id TEXT NOT NULL,
          version_number INTEGER NOT NULL,
          file_path TEXT NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          changes_summary TEXT,
          FOREIGN KEY (session_id) REFERENCES analysis_sessions (session_id)
        )
      ")

      # Auto-saves table
      dbExecute(self$conn, "
        CREATE TABLE IF NOT EXISTS auto_saves (
          autosave_id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id TEXT NOT NULL,
          file_path TEXT NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (session_id) REFERENCES analysis_sessions (session_id)
        )
      ")
    },

    # Save analysis session
    save_session = function(session_id, user_id, session_name,
                           session_data, description = NULL,
                           tags = NULL, is_public = FALSE) {
      # Generate unique file name
      file_name <- paste0(session_id, "_v", Sys.time() %>%
                         as.numeric() %>% as.integer(), ".rds")
      file_path <- file.path(self$storage_dir, file_name)

      # Save session data to RDS
      tryCatch({
        saveRDS(session_data, file_path, compress = "xz")

        file_size <- file.info(file_path)$size
        data_checksum <- digest::digest(file_path, file = TRUE)

        # Prepare metadata
        metadata <- list(
          n_treatments = if (!is.null(session_data$network)) session_data$network$K else NA,
          n_studies = if (!is.null(session_data$network)) session_data$network$J else NA,
          engine = if (!is.null(session_data$fit)) session_data$fit$engine else NA,
          has_ai = !is.null(session_data$fit$ai_interpretation),
          timestamp = Sys.time()
        )
        metadata_json <- jsonlite::toJSON(metadata, auto_unbox = TRUE)

        # Check if session exists
        existing <- dbGetQuery(self$conn,
          "SELECT session_id FROM analysis_sessions WHERE session_id = ?",
          params = list(session_id)
        )

        if (nrow(existing) > 0) {
          # Update existing session
          dbExecute(self$conn,
            "UPDATE analysis_sessions
             SET session_name = ?, description = ?, tags = ?,
                 updated_at = CURRENT_TIMESTAMP, version = version + 1,
                 file_path = ?, file_size = ?, data_checksum = ?,
                 metadata = ?
             WHERE session_id = ?",
            params = list(session_name, description, tags, file_path,
                         file_size, data_checksum, metadata_json, session_id)
          )

          # Get new version number
          version <- dbGetQuery(self$conn,
            "SELECT version FROM analysis_sessions WHERE session_id = ?",
            params = list(session_id)
          )$version

          # Save version
          dbExecute(self$conn,
            "INSERT INTO session_versions
             (session_id, version_number, file_path, changes_summary)
             VALUES (?, ?, ?, ?)",
            params = list(session_id, version, file_path, "Manual save")
          )
        } else {
          # Insert new session
          dbExecute(self$conn,
            "INSERT INTO analysis_sessions
             (session_id, user_id, session_name, description, tags,
              is_public, file_path, file_size, data_checksum, metadata)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            params = list(session_id, user_id, session_name, description,
                         tags, as.integer(is_public), file_path, file_size,
                         data_checksum, metadata_json)
          )
        }

        list(
          success = TRUE,
          message = "Session saved successfully",
          session_id = session_id,
          file_path = file_path
        )
      }, error = function(e) {
        list(success = FALSE, message = paste("Error saving session:", e$message))
      })
    },

    # Load analysis session
    load_session = function(session_id, user_id = NULL) {
      # Get session info
      query <- if (!is.null(user_id)) {
        "SELECT * FROM analysis_sessions
         WHERE session_id = ? AND (user_id = ? OR is_public = 1)"
      } else {
        "SELECT * FROM analysis_sessions WHERE session_id = ?"
      }

      session_info <- if (!is.null(user_id)) {
        dbGetQuery(self$conn, query, params = list(session_id, user_id))
      } else {
        dbGetQuery(self$conn, query, params = list(session_id))
      }

      if (nrow(session_info) == 0) {
        return(list(success = FALSE, message = "Session not found or access denied"))
      }

      session_info <- session_info[1, ]

      # Load session data
      tryCatch({
        if (!file.exists(session_info$file_path)) {
          return(list(success = FALSE, message = "Session file not found"))
        }

        session_data <- readRDS(session_info$file_path)

        # Update last accessed
        dbExecute(self$conn,
          "UPDATE analysis_sessions SET last_accessed = CURRENT_TIMESTAMP
           WHERE session_id = ?",
          params = list(session_id)
        )

        list(
          success = TRUE,
          data = session_data,
          info = session_info,
          message = "Session loaded successfully"
        )
      }, error = function(e) {
        list(success = FALSE, message = paste("Error loading session:", e$message))
      })
    },

    # Auto-save session
    auto_save = function(session_id, user_id, session_data) {
      file_name <- paste0(session_id, "_autosave_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".rds")
      file_path <- file.path(self$storage_dir, "autosaves", file_name)

      # Create autosaves directory
      autosave_dir <- file.path(self$storage_dir, "autosaves")
      if (!dir.exists(autosave_dir)) {
        dir.create(autosave_dir, recursive = TRUE)
      }

      tryCatch({
        saveRDS(session_data, file_path, compress = "xz")

        dbExecute(self$conn,
          "INSERT INTO auto_saves (session_id, file_path)
           VALUES (?, ?)",
          params = list(session_id, file_path)
        )

        # Clean old auto-saves (keep last 10)
        old_saves <- dbGetQuery(self$conn,
          "SELECT autosave_id, file_path FROM auto_saves
           WHERE session_id = ?
           ORDER BY created_at DESC
           LIMIT -1 OFFSET 10",
          params = list(session_id)
        )

        if (nrow(old_saves) > 0) {
          for (i in 1:nrow(old_saves)) {
            if (file.exists(old_saves$file_path[i])) {
              file.remove(old_saves$file_path[i])
            }
            dbExecute(self$conn,
              "DELETE FROM auto_saves WHERE autosave_id = ?",
              params = list(old_saves$autosave_id[i])
            )
          }
        }

        list(success = TRUE, message = "Auto-save completed")
      }, error = function(e) {
        list(success = FALSE, message = paste("Auto-save failed:", e$message))
      })
    },

    # List user sessions
    list_sessions = function(user_id = NULL, include_public = TRUE) {
      query <- if (!is.null(user_id)) {
        if (include_public) {
          "SELECT * FROM analysis_sessions
           WHERE user_id = ? OR is_public = 1
           ORDER BY updated_at DESC"
        } else {
          "SELECT * FROM analysis_sessions
           WHERE user_id = ?
           ORDER BY updated_at DESC"
        }
      } else {
        "SELECT * FROM analysis_sessions
         WHERE is_public = 1
         ORDER BY updated_at DESC"
      }

      if (!is.null(user_id)) {
        dbGetQuery(self$conn, query, params = list(user_id))
      } else {
        dbGetQuery(self$conn, query)
      }
    },

    # Delete session
    delete_session = function(session_id, user_id) {
      # Check ownership
      session <- dbGetQuery(self$conn,
        "SELECT user_id, file_path FROM analysis_sessions
         WHERE session_id = ?",
        params = list(session_id)
      )

      if (nrow(session) == 0) {
        return(list(success = FALSE, message = "Session not found"))
      }

      if (session$user_id != user_id) {
        return(list(success = FALSE, message = "Access denied"))
      }

      # Delete file
      if (file.exists(session$file_path)) {
        file.remove(session$file_path)
      }

      # Delete versions
      versions <- dbGetQuery(self$conn,
        "SELECT file_path FROM session_versions WHERE session_id = ?",
        params = list(session_id)
      )

      for (i in 1:nrow(versions)) {
        if (file.exists(versions$file_path[i])) {
          file.remove(versions$file_path[i])
        }
      }

      # Delete from database
      dbExecute(self$conn,
        "DELETE FROM session_versions WHERE session_id = ?",
        params = list(session_id)
      )
      dbExecute(self$conn,
        "DELETE FROM auto_saves WHERE session_id = ?",
        params = list(session_id)
      )
      dbExecute(self$conn,
        "DELETE FROM analysis_sessions WHERE session_id = ?",
        params = list(session_id)
      )

      list(success = TRUE, message = "Session deleted successfully")
    },

    # Export session
    export_session = function(session_id, user_id, export_path) {
      result <- self$load_session(session_id, user_id)

      if (!result$success) {
        return(result)
      }

      tryCatch({
        # Create export package
        export_data <- list(
          session_data = result$data,
          session_info = result$info,
          exported_at = Sys.time(),
          exported_by = user_id,
          version = "5.0"
        )

        saveRDS(export_data, export_path, compress = "xz")

        list(
          success = TRUE,
          message = "Session exported successfully",
          export_path = export_path
        )
      }, error = function(e) {
        list(success = FALSE, message = paste("Export failed:", e$message))
      })
    },

    # Import session
    import_session = function(import_path, user_id, new_session_name = NULL) {
      tryCatch({
        # Load export package
        export_data <- readRDS(import_path)

        # Generate new session ID
        session_id <- digest::digest(paste0(user_id, Sys.time(), runif(1)),
                                    algo = "md5")

        # Use imported or new name
        session_name <- if (!is.null(new_session_name)) {
          new_session_name
        } else {
          paste("Imported:", export_data$session_info$session_name)
        }

        # Save as new session
        result <- self$save_session(
          session_id = session_id,
          user_id = user_id,
          session_name = session_name,
          session_data = export_data$session_data,
          description = paste("Imported on", Sys.time()),
          tags = "imported"
        )

        if (result$success) {
          result$message <- "Session imported successfully"
          result$session_id <- session_id
        }

        result
      }, error = function(e) {
        list(success = FALSE, message = paste("Import failed:", e$message))
      })
    },

    # Search sessions
    search_sessions = function(user_id, query = NULL, tags = NULL) {
      base_query <- "SELECT * FROM analysis_sessions WHERE user_id = ?"
      params <- list(user_id)

      if (!is.null(query)) {
        base_query <- paste(base_query,
          "AND (session_name LIKE ? OR description LIKE ?)")
        search_pattern <- paste0("%", query, "%")
        params <- c(params, list(search_pattern, search_pattern))
      }

      if (!is.null(tags)) {
        base_query <- paste(base_query, "AND tags LIKE ?")
        params <- c(params, list(paste0("%", tags, "%")))
      }

      base_query <- paste(base_query, "ORDER BY updated_at DESC")

      do.call(dbGetQuery, c(list(self$conn, base_query), params))
    }
  ),

  private = list(
    finalize = function() {
      self$disconnect()
    }
  )
)

# ============================================================================
# SHINY SESSION MODULE
# ============================================================================

#' Session Management UI
#' @export
sessionManagementUI <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      box(
        title = "Session Management",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        fluidRow(
          column(4,
            textInput(ns("session_name"), "Session Name",
                     placeholder = "Enter session name")
          ),
          column(4,
            textInput(ns("session_tags"), "Tags (comma-separated)",
                     placeholder = "e.g., cardiology, 2025")
          ),
          column(4,
            checkboxInput(ns("is_public"), "Make public", FALSE)
          )
        ),

        fluidRow(
          column(12,
            textAreaInput(ns("session_description"), "Description",
                         placeholder = "Optional description",
                         rows = 2)
          )
        ),

        fluidRow(
          column(3,
            actionButton(ns("save_session"), "Save Session",
                        icon = icon("save"),
                        class = "btn btn-success btn-block")
          ),
          column(3,
            actionButton(ns("load_session"), "Load Session",
                        icon = icon("folder-open"),
                        class = "btn btn-primary btn-block")
          ),
          column(3,
            downloadButton(ns("export_session"), "Export Session",
                          class = "btn btn-info btn-block")
          ),
          column(3,
            fileInput(ns("import_file"), "Import Session",
                     accept = ".rds", buttonLabel = "Import",
                     placeholder = "Select .rds file")
          )
        ),

        hr(),

        h4("Saved Sessions"),
        DTOutput(ns("sessions_table"))
      )
    )
  )
}

#' Session Management Server
#' @export
sessionManagementServer <- function(id, session_manager, user_id, rv) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Current session ID
    current_session_id <- reactiveVal(
      digest::digest(paste0(user_id(), Sys.time()), algo = "md5")
    )

    # Auto-save every 5 minutes
    observe({
      invalidateLater(5 * 60 * 1000)  # 5 minutes

      if (!is.null(rv$network) || !is.null(rv$fit)) {
        session_data <- list(
          data = rv$data,
          network = rv$network,
          fit = rv$fit,
          methods_text = rv$methods_text,
          results_text = rv$results_text
        )

        session_manager$auto_save(
          session_id = current_session_id(),
          user_id = user_id(),
          session_data = session_data
        )
      }
    })

    # Save session
    observeEvent(input$save_session, {
      req(input$session_name)

      session_data <- list(
        data = rv$data,
        network = rv$network,
        fit = rv$fit,
        methods_text = rv$methods_text,
        results_text = rv$results_text,
        chat_history = rv$chat_history
      )

      result <- session_manager$save_session(
        session_id = current_session_id(),
        user_id = user_id(),
        session_name = input$session_name,
        session_data = session_data,
        description = input$session_description,
        tags = input$session_tags,
        is_public = input$is_public
      )

      if (result$success) {
        showNotification("Session saved successfully!", type = "message")
      } else {
        showNotification(result$message, type = "error")
      }
    })

    # Load session
    observeEvent(input$load_session, {
      req(input$sessions_table_rows_selected)

      sessions <- session_manager$list_sessions(user_id = user_id())
      selected_row <- input$sessions_table_rows_selected[1]
      session_id <- sessions$session_id[selected_row]

      result <- session_manager$load_session(session_id, user_id())

      if (result$success) {
        rv$data <- result$data$data
        rv$network <- result$data$network
        rv$fit <- result$data$fit
        rv$methods_text <- result$data$methods_text
        rv$results_text <- result$data$results_text
        rv$chat_history <- result$data$chat_history

        current_session_id(session_id)
        showNotification("Session loaded successfully!", type = "message")
      } else {
        showNotification(result$message, type = "error")
      }
    })

    # Export session
    output$export_session <- downloadHandler(
      filename = function() {
        paste0("surronma_session_", current_session_id(), "_",
               format(Sys.time(), "%Y%m%d"), ".rds")
      },
      content = function(file) {
        session_data <- list(
          data = rv$data,
          network = rv$network,
          fit = rv$fit,
          methods_text = rv$methods_text,
          results_text = rv$results_text
        )

        result <- session_manager$export_session(
          session_id = current_session_id(),
          user_id = user_id(),
          export_path = file
        )

        if (!result$success) {
          showNotification(result$message, type = "error")
        }
      }
    )

    # Import session
    observeEvent(input$import_file, {
      req(input$import_file)

      result <- session_manager$import_session(
        import_path = input$import_file$datapath,
        user_id = user_id()
      )

      if (result$success) {
        showNotification("Session imported successfully!", type = "message")
      } else {
        showNotification(result$message, type = "error")
      }
    })

    # Sessions table
    output$sessions_table <- renderDT({
      sessions <- session_manager$list_sessions(user_id = user_id())

      if (nrow(sessions) > 0) {
        # Parse metadata
        sessions$n_treatments <- sapply(sessions$metadata, function(m) {
          tryCatch({
            jsonlite::fromJSON(m)$n_treatments
          }, error = function(e) NA)
        })

        sessions$n_studies <- sapply(sessions$metadata, function(m) {
          tryCatch({
            jsonlite::fromJSON(m)$n_studies
          }, error = function(e) NA)
        })

        display_data <- sessions[, c("session_name", "description", "tags",
                                     "n_treatments", "n_studies",
                                     "updated_at", "version")]

        datatable(
          display_data,
          selection = "single",
          options = list(pageLength = 10),
          class = 'cell-border stripe'
        )
      } else {
        datatable(data.frame(Message = "No saved sessions"))
      }
    })
  })
}
