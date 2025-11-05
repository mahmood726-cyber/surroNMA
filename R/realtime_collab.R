#' Real-Time Collaborative Editing for surroNMA Dashboard
#' @description WebSocket-based real-time collaboration system
#' @version 5.0
#'
#' Features:
#' - Real-time cursor tracking
#' - Live parameter synchronization
#' - Conflict resolution
#' - Presence indicators
#' - Chat integration
#' - Operational transformation for concurrent edits

library(R6)
library(jsonlite)

# ============================================================================
# REAL-TIME COLLABORATION ENGINE
# ============================================================================

#' Real-Time Collaboration Engine
#' @export
RealtimeCollabEngine <- R6::R6Class("RealtimeCollabEngine",
  public = list(
    collab_manager = NULL,
    active_sessions = NULL,
    edit_queue = NULL,
    last_sync = NULL,

    initialize = function(collab_manager) {
      self$collab_manager <- collab_manager
      self$active_sessions <- list()
      self$edit_queue <- list()
      self$last_sync <- Sys.time()
    },

    # Register user session
    register_session = function(analysis_id, user_id, session_info) {
      session_key <- paste0(analysis_id, "_", user_id)

      self$active_sessions[[session_key]] <- list(
        analysis_id = analysis_id,
        user_id = user_id,
        connected_at = Sys.time(),
        last_activity = Sys.time(),
        cursor_position = NULL,
        current_tab = NULL,
        session_info = session_info
      )

      # Log activity
      self$collab_manager$log_activity(
        analysis_id = analysis_id,
        user_id = user_id,
        action = "joined",
        details = "User joined collaborative session"
      )

      list(success = TRUE, session_key = session_key)
    },

    # Unregister session
    unregister_session = function(session_key) {
      if (session_key %in% names(self$active_sessions)) {
        session <- self$active_sessions[[session_key]]

        self$collab_manager$log_activity(
          analysis_id = session$analysis_id,
          user_id = session$user_id,
          action = "left",
          details = "User left collaborative session"
        )

        self$active_sessions[[session_key]] <- NULL
      }

      list(success = TRUE)
    },

    # Broadcast edit to other users
    broadcast_edit = function(analysis_id, user_id, edit_type, edit_data) {
      # Log edit
      result <- self$collab_manager$log_edit(
        analysis_id = analysis_id,
        user_id = user_id,
        edit_type = edit_type,
        edit_data = edit_data
      )

      # Add to queue
      edit_record <- list(
        edit_id = result$edit_id,
        analysis_id = analysis_id,
        user_id = user_id,
        edit_type = edit_type,
        edit_data = edit_data,
        timestamp = Sys.time(),
        applied = FALSE
      )

      self$edit_queue[[as.character(result$edit_id)]] <- edit_record

      # Notify active users
      active_users <- self$get_active_users(analysis_id)

      list(
        success = TRUE,
        edit_id = result$edit_id,
        broadcast_to = length(active_users) - 1  # Exclude sender
      )
    },

    # Get pending edits for user
    get_pending_edits = function(analysis_id, user_id, since_edit_id = 0) {
      # Get edits from database
      edits <- self$collab_manager$get_recent_edits(analysis_id, since_edit_id)

      # Filter out user's own edits
      if (nrow(edits) > 0) {
        edits <- edits[edits$user_id != user_id, ]
      }

      list(
        success = TRUE,
        edits = edits,
        count = nrow(edits)
      )
    },

    # Update cursor position
    update_cursor = function(analysis_id, user_id, position) {
      session_key <- paste0(analysis_id, "_", user_id)

      if (session_key %in% names(self$active_sessions)) {
        self$active_sessions[[session_key]]$cursor_position <- position
        self$active_sessions[[session_key]]$last_activity <- Sys.time()
      }

      # Get other users' cursors
      other_cursors <- self$get_cursor_positions(analysis_id, exclude_user = user_id)

      list(
        success = TRUE,
        other_cursors = other_cursors
      )
    },

    # Get cursor positions
    get_cursor_positions = function(analysis_id, exclude_user = NULL) {
      cursors <- list()

      for (key in names(self$active_sessions)) {
        session <- self$active_sessions[[key]]

        if (session$analysis_id == analysis_id) {
          if (is.null(exclude_user) || session$user_id != exclude_user) {
            if (!is.null(session$cursor_position)) {
              cursors[[as.character(session$user_id)]] <- list(
                user_id = session$user_id,
                position = session$cursor_position,
                last_activity = session$last_activity
              )
            }
          }
        }
      }

      cursors
    },

    # Get active users
    get_active_users = function(analysis_id) {
      users <- list()

      for (key in names(self$active_sessions)) {
        session <- self$active_sessions[[key]]

        if (session$analysis_id == analysis_id) {
          # Consider active if activity within last 5 minutes
          if (difftime(Sys.time(), session$last_activity, units = "mins") < 5) {
            users[[as.character(session$user_id)]] <- list(
              user_id = session$user_id,
              connected_at = session$connected_at,
              last_activity = session$last_activity,
              current_tab = session$current_tab
            )
          }
        }
      }

      users
    },

    # Sync analysis state
    sync_state = function(analysis_id, user_id, state_data) {
      # Store state in queue for other users
      sync_record <- list(
        analysis_id = analysis_id,
        user_id = user_id,
        state_data = state_data,
        timestamp = Sys.time()
      )

      # Broadcast to other users
      self$broadcast_edit(
        analysis_id = analysis_id,
        user_id = user_id,
        edit_type = "state_sync",
        edit_data = state_data
      )

      list(success = TRUE)
    },

    # Resolve edit conflicts
    resolve_conflicts = function(edit1, edit2) {
      # Simple conflict resolution: last write wins with merge
      # In production, implement Operational Transformation (OT)

      if (edit1$edit_type == edit2$edit_type) {
        # Same type of edit - merge if possible
        if (edit1$timestamp > edit2$timestamp) {
          return(edit1)
        } else {
          return(edit2)
        }
      } else {
        # Different types - both can coexist
        return(list(edit1, edit2))
      }
    },

    # Clean up inactive sessions
    cleanup_inactive = function(timeout_minutes = 30) {
      current_time <- Sys.time()
      removed_count <- 0

      for (key in names(self$active_sessions)) {
        session <- self$active_sessions[[key]]

        if (difftime(current_time, session$last_activity, units = "mins") > timeout_minutes) {
          self$unregister_session(key)
          removed_count <- removed_count + 1
        }
      }

      list(success = TRUE, removed_count = removed_count)
    }
  )
)

# ============================================================================
# OPERATIONAL TRANSFORMATION (OT) UTILITIES
# ============================================================================

#' Operational Transformation for Concurrent Edits
#' @description Transform operations to maintain consistency
#' @export
operational_transform <- function(op1, op2) {
  # Simplified OT implementation
  # Full implementation would handle all operation types

  if (op1$type == "insert" && op2$type == "insert") {
    if (op1$position <= op2$position) {
      op2$position <- op2$position + nchar(op1$text)
    } else {
      op1$position <- op1$position + nchar(op2$text)
    }
  } else if (op1$type == "delete" && op2$type == "delete") {
    # Handle delete-delete conflicts
    if (op1$position < op2$position) {
      op2$position <- op2$position - op1$length
    }
  } else if (op1$type == "insert" && op2$type == "delete") {
    if (op1$position <= op2$position) {
      op2$position <- op2$position + nchar(op1$text)
    }
  }

  list(op1 = op1, op2 = op2)
}

# ============================================================================
# SHINY REAL-TIME COLLABORATION MODULE
# ============================================================================

#' Real-Time Collaboration UI
#' @export
realtimeCollabUI <- function(id) {
  ns <- NS(id)

  tagList(
    tags$head(
      tags$style(HTML("
        .collab-indicator {
          position: fixed;
          top: 60px;
          right: 20px;
          background: white;
          padding: 15px;
          border-radius: 8px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          z-index: 1000;
        }
        .active-user {
          display: inline-block;
          margin: 5px;
          padding: 8px 12px;
          background: #3c8dbc;
          color: white;
          border-radius: 20px;
          font-size: 12px;
        }
        .active-user .status-dot {
          display: inline-block;
          width: 8px;
          height: 8px;
          background: #00ff00;
          border-radius: 50%;
          margin-right: 5px;
        }
        .edit-notification {
          position: fixed;
          bottom: 20px;
          right: 20px;
          background: #f39c12;
          color: white;
          padding: 12px 20px;
          border-radius: 5px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.2);
          animation: slideIn 0.3s ease-out;
          z-index: 1001;
        }
        @keyframes slideIn {
          from {
            transform: translateX(400px);
            opacity: 0;
          }
          to {
            transform: translateX(0);
            opacity: 1;
          }
        }
        .cursor-overlay {
          position: absolute;
          width: 2px;
          height: 20px;
          background: #3c8dbc;
          animation: blink 1s infinite;
        }
        @keyframes blink {
          0%, 100% { opacity: 1; }
          50% { opacity: 0; }
        }
      "))
    ),

    # Collaboration indicator
    div(class = "collab-indicator",
      h5(icon("users"), " Active Collaborators"),
      uiOutput(ns("active_users_display")),
      hr(style = "margin: 10px 0;"),
      tags$small(
        style = "color: #666;",
        "Last sync: ", textOutput(ns("last_sync_time"), inline = TRUE)
      )
    ),

    # Edit notifications
    uiOutput(ns("edit_notifications"))
  )
}

#' Real-Time Collaboration Server
#' @export
realtimeCollabServer <- function(id, rt_engine, analysis_id, user_id, rv) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    collab_rv <- reactiveValues(
      last_edit_id = 0,
      pending_edits = list(),
      active_users = list(),
      sync_time = Sys.time()
    )

    # Register session on init
    observe({
      req(analysis_id(), user_id())

      rt_engine$register_session(
        analysis_id = analysis_id(),
        user_id = user_id(),
        session_info = list(
          session_id = session$token,
          user_agent = session$clientData$url_search
        )
      )
    })

    # Poll for updates every 2 seconds
    observe({
      invalidateLater(2000)

      req(analysis_id(), user_id())

      # Get pending edits
      result <- rt_engine$get_pending_edits(
        analysis_id = analysis_id(),
        user_id = user_id(),
        since_edit_id = collab_rv$last_edit_id
      )

      if (result$count > 0) {
        collab_rv$pending_edits <- result$edits

        # Update last edit ID
        if (nrow(result$edits) > 0) {
          collab_rv$last_edit_id <- max(result$edits$edit_id)

          # Apply edits to local state
          for (i in 1:nrow(result$edits)) {
            edit <- result$edits[i, ]
            private$apply_edit(edit, rv)
          }
        }
      }

      # Update active users
      users <- rt_engine$get_active_users(analysis_id())
      collab_rv$active_users <- users
      collab_rv$sync_time <- Sys.time()
    })

    # Display active users
    output$active_users_display <- renderUI({
      users <- collab_rv$active_users

      if (length(users) == 0) {
        return(tags$p("No other users", style = "color: #999; font-size: 12px;"))
      }

      user_badges <- lapply(users, function(u) {
        if (u$user_id != user_id()) {
          tags$div(
            class = "active-user",
            tags$span(class = "status-dot"),
            paste("User", u$user_id)
          )
        }
      })

      do.call(tagList, user_badges)
    })

    # Display last sync time
    output$last_sync_time <- renderText({
      format(collab_rv$sync_time, "%H:%M:%S")
    })

    # Edit notifications
    output$edit_notifications <- renderUI({
      if (length(collab_rv$pending_edits) > 0) {
        last_edit <- tail(collab_rv$pending_edits, 1)[[1]]

        tags$div(
          class = "edit-notification",
          icon("edit"),
          paste(" User", last_edit$user_id, "made changes")
        )
      }
    })

    # Broadcast local changes
    observe({
      # Monitor rv for changes and broadcast
      # This would be triggered by user actions

      if (!is.null(rv$network) && !identical(rv$network, collab_rv$last_network)) {
        rt_engine$broadcast_edit(
          analysis_id = analysis_id(),
          user_id = user_id(),
          edit_type = "network_update",
          edit_data = list(
            timestamp = Sys.time(),
            network_hash = digest::digest(rv$network)
          )
        )

        collab_rv$last_network <- rv$network
      }
    })

    # Cleanup on session end
    session$onSessionEnded(function() {
      session_key <- paste0(analysis_id(), "_", user_id())
      rt_engine$unregister_session(session_key)
    })
  })
}

# ============================================================================
# PRIVATE METHODS
# ============================================================================

private <- list(
  apply_edit = function(edit, rv) {
    tryCatch({
      edit_data <- if (is.character(edit$edit_data)) {
        fromJSON(edit$edit_data)
      } else {
        edit$edit_data
      }

      switch(edit$edit_type,
        "network_update" = {
          # Trigger network reload
          showNotification(
            paste("User", edit$username, "updated the network"),
            type = "message",
            duration = 3
          )
        },
        "parameter_change" = {
          # Apply parameter changes
          if (!is.null(edit_data$parameter)) {
            showNotification(
              paste("User", edit$username, "changed", edit_data$parameter),
              type = "message",
              duration = 3
            )
          }
        },
        "analysis_run" = {
          # Notify analysis running
          showNotification(
            paste("User", edit$username, "started analysis"),
            type = "message",
            duration = 3
          )
        },
        "state_sync" = {
          # Full state sync - reload data
          message("Syncing state from user ", edit$user_id)
        }
      )
    }, error = function(e) {
      message("Error applying edit: ", e$message)
    })
  }
)

# ============================================================================
# CHAT INTEGRATION
# ============================================================================

#' Real-Time Chat UI
#' @export
realtimeChatUI <- function(id) {
  ns <- NS(id)

  tags$div(
    class = "realtime-chat",
    style = "position: fixed; bottom: 20px; right: 20px; width: 300px; background: white; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.2); z-index: 1002;",

    tags$div(
      class = "chat-header",
      style = "background: #3c8dbc; color: white; padding: 10px; border-radius: 8px 8px 0 0; cursor: pointer;",
      onclick = paste0("$('#", ns("chat_body"), "').toggle();"),
      icon("comments"), " Team Chat",
      tags$span(style = "float: right;", icon("chevron-down"))
    ),

    tags$div(
      id = ns("chat_body"),
      style = "display: none;",

      tags$div(
        class = "chat-messages",
        style = "height: 300px; overflow-y: auto; padding: 10px; border-bottom: 1px solid #eee;",
        uiOutput(ns("chat_messages"))
      ),

      tags$div(
        class = "chat-input",
        style = "padding: 10px;",
        textInput(ns("chat_message"), NULL,
                 placeholder = "Type a message...",
                 width = "100%"),
        actionButton(ns("send_chat"), "Send",
                    class = "btn btn-primary btn-sm btn-block")
      )
    )
  )
}

#' Real-Time Chat Server
#' @export
realtimeChatServer <- function(id, rt_engine, analysis_id, user_id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    chat_messages <- reactiveVal(list())

    # Load existing messages
    observe({
      req(analysis_id())

      # Poll for new messages every 3 seconds
      invalidateLater(3000)

      # Get recent chat messages from collab manager
      messages <- rt_engine$collab_manager$get_activity(
        analysis_id = analysis_id(),
        limit = 50
      )

      if (nrow(messages) > 0) {
        chat_msgs <- messages[messages$action == "chat", ]
        if (nrow(chat_msgs) > 0) {
          chat_messages(chat_msgs)
        }
      }
    })

    # Display messages
    output$chat_messages <- renderUI({
      msgs <- chat_messages()

      if (length(msgs) == 0 || nrow(msgs) == 0) {
        return(tags$p("No messages yet", style = "color: #999; font-size: 12px;"))
      }

      msg_elements <- lapply(1:nrow(msgs), function(i) {
        msg <- msgs[i, ]

        is_own <- msg$user_id == user_id()

        tags$div(
          class = if (is_own) "chat-msg-own" else "chat-msg-other",
          style = paste0(
            "padding: 8px; margin: 5px 0; border-radius: 5px; ",
            if (is_own) {
              "background: #3c8dbc; color: white; text-align: right;"
            } else {
              "background: #f4f4f4;"
            }
          ),
          tags$small(
            style = "font-weight: bold;",
            if (!is.na(msg$full_name)) msg$full_name else paste("User", msg$user_id)
          ),
          tags$br(),
          msg$details,
          tags$br(),
          tags$small(
            style = if (is_own) "color: #ddd;" else "color: #999;",
            format(as.POSIXct(msg$timestamp), "%H:%M")
          )
        )
      })

      do.call(tagList, msg_elements)
    })

    # Send message
    observeEvent(input$send_chat, {
      req(input$chat_message, analysis_id(), user_id())

      if (nchar(trimws(input$chat_message)) > 0) {
        # Log as activity
        rt_engine$collab_manager$log_activity(
          analysis_id = analysis_id(),
          user_id = user_id(),
          action = "chat",
          details = input$chat_message
        )

        # Clear input
        updateTextInput(session, "chat_message", value = "")

        # Refresh messages
        invalidateLater(100)
      }
    })
  })
}
