#' Collaboration Features for surroNMA Dashboard
#' @description Share analyses, collaborate in real-time, and manage teams
#' @version 5.0
#'
#' Features:
#' - Share analyses with other users
#' - Permission management (view, edit, admin)
#' - Real-time collaborative editing
#' - Comments and annotations
#' - Activity feed
#' - Team management

library(R6)
library(DBI)
library(RSQLite)
library(jsonlite)

# ============================================================================
# COLLABORATION MANAGER
# ============================================================================

#' Collaboration Manager Class
#' @export
CollaborationManager <- R6::R6Class("CollaborationManager",
  public = list(
    db_path = NULL,
    conn = NULL,

    initialize = function(db_path = "surronma_collab.db") {
      self$db_path <- db_path
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
      # Shares table
      dbExecute(self$conn, "
        CREATE TABLE IF NOT EXISTS analysis_shares (
          share_id TEXT PRIMARY KEY,
          analysis_id TEXT NOT NULL,
          owner_id INTEGER NOT NULL,
          shared_with_id INTEGER,
          shared_with_email TEXT,
          permission TEXT NOT NULL DEFAULT 'view',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          expires_at TIMESTAMP,
          accepted INTEGER DEFAULT 0,
          message TEXT
        )
      ")

      # Comments table
      dbExecute(self$conn, "
        CREATE TABLE IF NOT EXISTS comments (
          comment_id INTEGER PRIMARY KEY AUTOINCREMENT,
          analysis_id TEXT NOT NULL,
          user_id INTEGER NOT NULL,
          parent_id INTEGER,
          content TEXT NOT NULL,
          location TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP,
          is_resolved INTEGER DEFAULT 0
        )
      ")

      # Teams table
      dbExecute(self$conn, "
        CREATE TABLE IF NOT EXISTS teams (
          team_id INTEGER PRIMARY KEY AUTOINCREMENT,
          team_name TEXT NOT NULL,
          description TEXT,
          created_by INTEGER NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ")

      # Team members table
      dbExecute(self$conn, "
        CREATE TABLE IF NOT EXISTS team_members (
          member_id INTEGER PRIMARY KEY AUTOINCREMENT,
          team_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          role TEXT NOT NULL DEFAULT 'member',
          joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (team_id) REFERENCES teams (team_id),
          UNIQUE(team_id, user_id)
        )
      ")

      # Activity feed table
      dbExecute(self$conn, "
        CREATE TABLE IF NOT EXISTS activity_feed (
          activity_id INTEGER PRIMARY KEY AUTOINCREMENT,
          analysis_id TEXT NOT NULL,
          user_id INTEGER NOT NULL,
          action TEXT NOT NULL,
          details TEXT,
          timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ")

      # Real-time edits table
      dbExecute(self$conn, "
        CREATE TABLE IF NOT EXISTS realtime_edits (
          edit_id INTEGER PRIMARY KEY AUTOINCREMENT,
          analysis_id TEXT NOT NULL,
          user_id INTEGER NOT NULL,
          edit_type TEXT NOT NULL,
          edit_data TEXT NOT NULL,
          timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          applied INTEGER DEFAULT 0
        )
      ")
    },

    # Share analysis
    share_analysis = function(analysis_id, owner_id, shared_with,
                             permission = "view", message = NULL,
                             expires_days = NULL) {
      # Generate share ID
      share_id <- digest::digest(paste0(analysis_id, shared_with, Sys.time()),
                                algo = "md5")

      expires_at <- if (!is.null(expires_days)) {
        as.character(Sys.time() + expires_days * 24 * 3600)
      } else {
        NULL
      }

      # Check if sharing with email or user ID
      if (grepl("@", shared_with)) {
        # Sharing with email
        dbExecute(self$conn,
          "INSERT INTO analysis_shares
           (share_id, analysis_id, owner_id, shared_with_email, permission,
            expires_at, message)
           VALUES (?, ?, ?, ?, ?, ?, ?)",
          params = list(share_id, analysis_id, owner_id, shared_with,
                       permission, expires_at, message)
        )
      } else {
        # Sharing with user ID
        shared_with_id <- as.integer(shared_with)
        dbExecute(self$conn,
          "INSERT INTO analysis_shares
           (share_id, analysis_id, owner_id, shared_with_id, permission,
            expires_at, message)
           VALUES (?, ?, ?, ?, ?, ?, ?)",
          params = list(share_id, analysis_id, owner_id, shared_with_id,
                       permission, expires_at, message)
        )
      }

      # Log activity
      self$log_activity(analysis_id, owner_id, "shared",
                       paste("Shared with", shared_with, "as", permission))

      list(
        success = TRUE,
        share_id = share_id,
        message = "Analysis shared successfully"
      )
    },

    # Get shares for analysis
    get_shares = function(analysis_id) {
      dbGetQuery(self$conn,
        "SELECT * FROM analysis_shares
         WHERE analysis_id = ?
         ORDER BY created_at DESC",
        params = list(analysis_id)
      )
    },

    # Get shares for user
    get_user_shares = function(user_id) {
      dbGetQuery(self$conn,
        "SELECT * FROM analysis_shares
         WHERE shared_with_id = ? OR shared_with_email IN
               (SELECT email FROM users WHERE user_id = ?)
         ORDER BY created_at DESC",
        params = list(user_id, user_id)
      )
    },

    # Check access permission
    check_access = function(analysis_id, user_id, required_permission = "view") {
      # Check if user is owner
      owner_check <- dbGetQuery(self$conn,
        "SELECT owner_id FROM analysis_sessions WHERE session_id = ?",
        params = list(analysis_id)
      )

      if (nrow(owner_check) > 0 && owner_check$owner_id == user_id) {
        return(list(
          has_access = TRUE,
          permission = "admin",
          is_owner = TRUE
        ))
      }

      # Check shares
      share <- dbGetQuery(self$conn,
        "SELECT permission FROM analysis_shares
         WHERE analysis_id = ? AND shared_with_id = ?
           AND (expires_at IS NULL OR expires_at > datetime('now'))",
        params = list(analysis_id, user_id)
      )

      if (nrow(share) == 0) {
        return(list(has_access = FALSE, is_owner = FALSE))
      }

      permission <- share$permission[1]

      # Check permission hierarchy: admin > edit > view
      permission_levels <- c("view" = 1, "edit" = 2, "admin" = 3)
      has_access <- permission_levels[permission] >= permission_levels[required_permission]

      list(
        has_access = has_access,
        permission = permission,
        is_owner = FALSE
      )
    },

    # Revoke share
    revoke_share = function(share_id, owner_id) {
      # Verify ownership
      share <- dbGetQuery(self$conn,
        "SELECT owner_id FROM analysis_shares WHERE share_id = ?",
        params = list(share_id)
      )

      if (nrow(share) == 0) {
        return(list(success = FALSE, message = "Share not found"))
      }

      if (share$owner_id != owner_id) {
        return(list(success = FALSE, message = "Access denied"))
      }

      dbExecute(self$conn,
        "DELETE FROM analysis_shares WHERE share_id = ?",
        params = list(share_id)
      )

      list(success = TRUE, message = "Share revoked successfully")
    },

    # Add comment
    add_comment = function(analysis_id, user_id, content,
                          location = NULL, parent_id = NULL) {
      dbExecute(self$conn,
        "INSERT INTO comments
         (analysis_id, user_id, content, location, parent_id)
         VALUES (?, ?, ?, ?, ?)",
        params = list(analysis_id, user_id, content, location, parent_id)
      )

      comment_id <- dbGetQuery(self$conn, "SELECT last_insert_rowid() as id")$id

      # Log activity
      self$log_activity(analysis_id, user_id, "commented",
                       substr(content, 1, 100))

      list(success = TRUE, comment_id = comment_id)
    },

    # Get comments
    get_comments = function(analysis_id, include_resolved = FALSE) {
      query <- if (include_resolved) {
        "SELECT c.*, u.username, u.full_name
         FROM comments c
         LEFT JOIN users u ON c.user_id = u.user_id
         WHERE c.analysis_id = ?
         ORDER BY c.created_at DESC"
      } else {
        "SELECT c.*, u.username, u.full_name
         FROM comments c
         LEFT JOIN users u ON c.user_id = u.user_id
         WHERE c.analysis_id = ? AND c.is_resolved = 0
         ORDER BY c.created_at DESC"
      }

      dbGetQuery(self$conn, query, params = list(analysis_id))
    },

    # Resolve comment
    resolve_comment = function(comment_id, user_id) {
      dbExecute(self$conn,
        "UPDATE comments SET is_resolved = 1, updated_at = CURRENT_TIMESTAMP
         WHERE comment_id = ?",
        params = list(comment_id)
      )

      list(success = TRUE, message = "Comment resolved")
    },

    # Create team
    create_team = function(team_name, created_by, description = NULL) {
      dbExecute(self$conn,
        "INSERT INTO teams (team_name, description, created_by)
         VALUES (?, ?, ?)",
        params = list(team_name, description, created_by)
      )

      team_id <- dbGetQuery(self$conn, "SELECT last_insert_rowid() as id")$id

      # Add creator as admin
      dbExecute(self$conn,
        "INSERT INTO team_members (team_id, user_id, role)
         VALUES (?, ?, 'admin')",
        params = list(team_id, created_by)
      )

      list(success = TRUE, team_id = team_id)
    },

    # Add team member
    add_team_member = function(team_id, user_id, role = "member") {
      tryCatch({
        dbExecute(self$conn,
          "INSERT INTO team_members (team_id, user_id, role)
           VALUES (?, ?, ?)",
          params = list(team_id, user_id, role)
        )

        list(success = TRUE, message = "Member added successfully")
      }, error = function(e) {
        list(success = FALSE, message = "Member already exists or error occurred")
      })
    },

    # Get team members
    get_team_members = function(team_id) {
      dbGetQuery(self$conn,
        "SELECT tm.*, u.username, u.email, u.full_name
         FROM team_members tm
         JOIN users u ON tm.user_id = u.user_id
         WHERE tm.team_id = ?
         ORDER BY tm.role DESC, u.username",
        params = list(team_id)
      )
    },

    # Get user teams
    get_user_teams = function(user_id) {
      dbGetQuery(self$conn,
        "SELECT t.*, tm.role
         FROM teams t
         JOIN team_members tm ON t.team_id = tm.team_id
         WHERE tm.user_id = ?
         ORDER BY t.team_name",
        params = list(user_id)
      )
    },

    # Share with team
    share_with_team = function(analysis_id, owner_id, team_id,
                              permission = "view") {
      # Get team members
      members <- dbGetQuery(self$conn,
        "SELECT user_id FROM team_members WHERE team_id = ?",
        params = list(team_id)
      )

      shared_count <- 0
      for (i in 1:nrow(members)) {
        if (members$user_id[i] != owner_id) {
          result <- self$share_analysis(
            analysis_id = analysis_id,
            owner_id = owner_id,
            shared_with = as.character(members$user_id[i]),
            permission = permission,
            message = "Shared via team"
          )
          if (result$success) shared_count <- shared_count + 1
        }
      }

      list(
        success = TRUE,
        shared_count = shared_count,
        message = paste("Shared with", shared_count, "team members")
      )
    },

    # Log activity
    log_activity = function(analysis_id, user_id, action, details = NULL) {
      dbExecute(self$conn,
        "INSERT INTO activity_feed (analysis_id, user_id, action, details)
         VALUES (?, ?, ?, ?)",
        params = list(analysis_id, user_id, action, details)
      )
    },

    # Get activity feed
    get_activity = function(analysis_id, limit = 50) {
      dbGetQuery(self$conn,
        "SELECT a.*, u.username, u.full_name
         FROM activity_feed a
         LEFT JOIN users u ON a.user_id = u.user_id
         WHERE a.analysis_id = ?
         ORDER BY a.timestamp DESC
         LIMIT ?",
        params = list(analysis_id, limit)
      )
    },

    # Real-time edit tracking
    log_edit = function(analysis_id, user_id, edit_type, edit_data) {
      edit_json <- toJSON(edit_data, auto_unbox = TRUE)

      dbExecute(self$conn,
        "INSERT INTO realtime_edits
         (analysis_id, user_id, edit_type, edit_data)
         VALUES (?, ?, ?, ?)",
        params = list(analysis_id, user_id, edit_type, edit_json)
      )

      edit_id <- dbGetQuery(self$conn, "SELECT last_insert_rowid() as id")$id

      list(success = TRUE, edit_id = edit_id)
    },

    # Get recent edits
    get_recent_edits = function(analysis_id, since_edit_id = 0) {
      edits <- dbGetQuery(self$conn,
        "SELECT e.*, u.username, u.full_name
         FROM realtime_edits e
         LEFT JOIN users u ON e.user_id = u.user_id
         WHERE e.analysis_id = ? AND e.edit_id > ?
         ORDER BY e.timestamp ASC",
        params = list(analysis_id, since_edit_id)
      )

      if (nrow(edits) > 0) {
        edits$edit_data <- lapply(edits$edit_data, fromJSON)
      }

      edits
    },

    # Get active collaborators
    get_active_collaborators = function(analysis_id, minutes = 5) {
      cutoff <- as.character(Sys.time() - minutes * 60)

      dbGetQuery(self$conn,
        "SELECT DISTINCT u.user_id, u.username, u.full_name,
                MAX(e.timestamp) as last_activity
         FROM realtime_edits e
         JOIN users u ON e.user_id = u.user_id
         WHERE e.analysis_id = ? AND e.timestamp > ?
         GROUP BY u.user_id, u.username, u.full_name
         ORDER BY last_activity DESC",
        params = list(analysis_id, cutoff)
      )
    }
  ),

  private = list(
    finalize = function() {
      self$disconnect()
    }
  )
)

# ============================================================================
# SHINY COLLABORATION MODULE
# ============================================================================

#' Collaboration UI
#' @export
collaborationUI <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      # Share panel
      box(
        title = "Share Analysis",
        status = "primary",
        solidHeader = TRUE,
        width = 6,

        fluidRow(
          column(8,
            textInput(ns("share_with"), "Share with (username or email)",
                     placeholder = "Enter username or email")
          ),
          column(4,
            selectInput(ns("share_permission"), "Permission",
                       choices = c("View" = "view",
                                  "Edit" = "edit",
                                  "Admin" = "admin"),
                       selected = "view")
          )
        ),

        textAreaInput(ns("share_message"), "Message (optional)",
                     placeholder = "Add a message for the recipient",
                     rows = 2),

        sliderInput(ns("share_expires"), "Expires in (days)",
                   min = 1, max = 365, value = 30, step = 1),

        actionButton(ns("share_btn"), "Share",
                    icon = icon("share-alt"),
                    class = "btn btn-success btn-block"),

        hr(),

        h5("Current Shares"),
        DTOutput(ns("shares_table"))
      ),

      # Comments panel
      box(
        title = "Comments & Discussion",
        status = "info",
        solidHeader = TRUE,
        width = 6,

        textAreaInput(ns("comment_text"), "Add Comment",
                     placeholder = "Write your comment here...",
                     rows = 3),

        actionButton(ns("add_comment"), "Post Comment",
                    icon = icon("comment"),
                    class = "btn btn-primary"),

        hr(),

        uiOutput(ns("comments_display"))
      )
    ),

    fluidRow(
      # Teams panel
      box(
        title = "Teams",
        status = "warning",
        solidHeader = TRUE,
        width = 6,

        actionButton(ns("create_team"), "Create New Team",
                    icon = icon("users"),
                    class = "btn btn-success"),

        hr(),

        DTOutput(ns("teams_table"))
      ),

      # Activity feed
      box(
        title = "Activity Feed",
        status = "success",
        solidHeader = TRUE,
        width = 6,
        collapsible = TRUE,

        tags$div(
          id = ns("activity_feed"),
          style = "height: 400px; overflow-y: auto;",
          uiOutput(ns("activity_display"))
        )
      )
    ),

    fluidRow(
      # Active collaborators
      box(
        title = "Active Collaborators",
        status = "primary",
        solidHeader = TRUE,
        width = 12,

        uiOutput(ns("active_users"))
      )
    )
  )
}

#' Collaboration Server
#' @export
collaborationServer <- function(id, collab_manager, user_id, analysis_id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Share analysis
    observeEvent(input$share_btn, {
      req(input$share_with, analysis_id())

      result <- collab_manager$share_analysis(
        analysis_id = analysis_id(),
        owner_id = user_id(),
        shared_with = input$share_with,
        permission = input$share_permission,
        message = input$share_message,
        expires_days = input$share_expires
      )

      if (result$success) {
        showNotification("Analysis shared successfully!", type = "message")
        updateTextInput(session, "share_with", value = "")
        updateTextAreaInput(session, "share_message", value = "")
      } else {
        showNotification(result$message, type = "error")
      }
    })

    # Shares table
    output$shares_table <- renderDT({
      req(analysis_id())

      shares <- collab_manager$get_shares(analysis_id())

      if (nrow(shares) > 0) {
        display_data <- shares[, c("shared_with_email", "shared_with_id",
                                   "permission", "created_at", "expires_at")]

        datatable(
          display_data,
          selection = "single",
          options = list(pageLength = 5),
          class = 'cell-border stripe'
        )
      } else {
        datatable(data.frame(Message = "No shares yet"))
      }
    })

    # Add comment
    observeEvent(input$add_comment, {
      req(input$comment_text, analysis_id())

      if (nchar(trimws(input$comment_text)) > 0) {
        result <- collab_manager$add_comment(
          analysis_id = analysis_id(),
          user_id = user_id(),
          content = input$comment_text
        )

        if (result$success) {
          showNotification("Comment added!", type = "message")
          updateTextAreaInput(session, "comment_text", value = "")
        } else {
          showNotification("Error adding comment", type = "error")
        }
      }
    })

    # Display comments
    output$comments_display <- renderUI({
      req(analysis_id())

      comments <- collab_manager$get_comments(analysis_id())

      if (nrow(comments) == 0) {
        return(tags$p("No comments yet", style = "color: #999;"))
      }

      comment_elements <- lapply(1:nrow(comments), function(i) {
        c <- comments[i, ]
        tags$div(
          class = "comment",
          style = "background: #f9f9f9; padding: 15px; border-radius: 5px; margin: 10px 0;",
          tags$div(
            tags$strong(if (!is.na(c$full_name)) c$full_name else c$username),
            tags$small(
              style = "color: #666; margin-left: 10px;",
              format(as.POSIXct(c$created_at), "%Y-%m-%d %H:%M")
            )
          ),
          tags$p(style = "margin: 10px 0;", c$content),
          tags$div(
            actionLink(ns(paste0("resolve_", c$comment_id)), "Resolve",
                      style = "color: #3c8dbc;")
          )
        )
      })

      do.call(tagList, comment_elements)
    })

    # Activity feed
    output$activity_display <- renderUI({
      req(analysis_id())

      activities <- collab_manager$get_activity(analysis_id(), limit = 20)

      if (nrow(activities) == 0) {
        return(tags$p("No activity yet", style = "color: #999;"))
      }

      activity_elements <- lapply(1:nrow(activities), function(i) {
        a <- activities[i, ]
        icon_name <- switch(a$action,
          "shared" = "share-alt",
          "commented" = "comment",
          "edited" = "edit",
          "viewed" = "eye",
          "file")

        tags$div(
          class = "activity-item",
          style = "padding: 10px 0; border-bottom: 1px solid #eee;",
          icon(icon_name, style = "color: #3c8dbc; margin-right: 10px;"),
          tags$strong(if (!is.na(a$full_name)) a$full_name else a$username),
          " ", a$action,
          if (!is.na(a$details)) tags$small(paste(" -", a$details)) else NULL,
          tags$br(),
          tags$small(
            style = "color: #999;",
            format(as.POSIXct(a$timestamp), "%Y-%m-%d %H:%M")
          )
        )
      })

      do.call(tagList, activity_elements)
    })

    # Active collaborators
    output$active_users <- renderUI({
      req(analysis_id())

      # Update every 30 seconds
      invalidateLater(30000)

      users <- collab_manager$get_active_collaborators(analysis_id(), minutes = 5)

      if (nrow(users) == 0) {
        return(tags$p("No active collaborators", style = "color: #999;"))
      }

      user_badges <- lapply(1:nrow(users), function(i) {
        u <- users[i, ]
        tags$span(
          class = "badge badge-success",
          style = "margin: 5px; padding: 8px 12px; font-size: 14px;",
          icon("circle", style = "color: #00ff00; margin-right: 5px;"),
          if (!is.na(u$full_name)) u$full_name else u$username
        )
      })

      do.call(tagList, user_badges)
    })
  })
}
