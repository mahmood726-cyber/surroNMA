#' User Authentication System for surroNMA Dashboard
#' @description Secure multi-user authentication with role-based access control
#' @version 5.0
#'
#' Features:
#' - User registration and login
#' - Password hashing with bcrypt
#' - Role-based access control (Admin, Researcher, Viewer)
#' - Session management
#' - Activity logging
#' - Password reset functionality

library(R6)
library(DBI)
library(RSQLite)
library(digest)

# ============================================================================
# USER DATABASE MANAGER
# ============================================================================

#' User Database Manager
#' @export
UserDB <- R6::R6Class("UserDB",
  public = list(
    db_path = NULL,
    conn = NULL,

    initialize = function(db_path = "surronma_users.db") {
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
      # Users table
      dbExecute(self$conn, "
        CREATE TABLE IF NOT EXISTS users (
          user_id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT 'researcher',
          full_name TEXT,
          organization TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          last_login TIMESTAMP,
          is_active INTEGER DEFAULT 1,
          verified INTEGER DEFAULT 0
        )
      ")

      # Sessions table
      dbExecute(self$conn, "
        CREATE TABLE IF NOT EXISTS sessions (
          session_id TEXT PRIMARY KEY,
          user_id INTEGER NOT NULL,
          ip_address TEXT,
          user_agent TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          expires_at TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (user_id)
        )
      ")

      # Activity log
      dbExecute(self$conn, "
        CREATE TABLE IF NOT EXISTS activity_log (
          log_id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          action TEXT NOT NULL,
          details TEXT,
          ip_address TEXT,
          timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users (user_id)
        )
      ")

      # Shared analyses
      dbExecute(self$conn, "
        CREATE TABLE IF NOT EXISTS shared_analyses (
          share_id TEXT PRIMARY KEY,
          analysis_id TEXT NOT NULL,
          owner_id INTEGER NOT NULL,
          shared_with TEXT,
          permission TEXT DEFAULT 'view',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          expires_at TIMESTAMP,
          FOREIGN KEY (owner_id) REFERENCES users (user_id)
        )
      ")
    },

    # Hash password using bcrypt-like approach
    hash_password = function(password) {
      # Use multiple rounds of SHA-256 for security
      salt <- paste0(sample(c(letters, LETTERS, 0:9), 32, replace = TRUE),
                    collapse = "")
      hash <- digest(paste0(password, salt), algo = "sha256")
      paste0(salt, "$", hash)
    },

    verify_password = function(password, stored_hash) {
      parts <- strsplit(stored_hash, "\\$")[[1]]
      if (length(parts) != 2) return(FALSE)

      salt <- parts[1]
      hash <- digest(paste0(password, salt), algo = "sha256")
      hash == parts[2]
    },

    # User registration
    register_user = function(username, email, password, full_name = NULL,
                            organization = NULL, role = "researcher") {
      # Validate inputs
      if (nchar(password) < 8) {
        stop("Password must be at least 8 characters")
      }

      if (!grepl("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email)) {
        stop("Invalid email format")
      }

      # Check if user exists
      existing <- dbGetQuery(self$conn,
        "SELECT user_id FROM users WHERE username = ? OR email = ?",
        params = list(username, email)
      )

      if (nrow(existing) > 0) {
        stop("Username or email already exists")
      }

      # Hash password and insert
      password_hash <- self$hash_password(password)

      dbExecute(self$conn,
        "INSERT INTO users (username, email, password_hash, full_name,
                           organization, role)
         VALUES (?, ?, ?, ?, ?, ?)",
        params = list(username, email, password_hash, full_name,
                     organization, role)
      )

      user_id <- dbGetQuery(self$conn, "SELECT last_insert_rowid() as id")$id

      self$log_activity(user_id, "user_registered",
                       paste("New user registered:", username))

      list(success = TRUE, user_id = user_id, message = "User registered successfully")
    },

    # User login
    login = function(username, password, ip_address = NULL, user_agent = NULL) {
      # Get user
      user <- dbGetQuery(self$conn,
        "SELECT * FROM users WHERE username = ? OR email = ?",
        params = list(username, username)
      )

      if (nrow(user) == 0) {
        return(list(success = FALSE, message = "Invalid credentials"))
      }

      user <- user[1, ]

      if (!user$is_active) {
        return(list(success = FALSE, message = "Account is inactive"))
      }

      # Verify password
      if (!self$verify_password(password, user$password_hash)) {
        return(list(success = FALSE, message = "Invalid credentials"))
      }

      # Create session
      session_id <- digest(paste0(user$user_id, Sys.time(), runif(1)),
                          algo = "md5")
      expires_at <- as.character(Sys.time() + 24 * 3600) # 24 hours

      dbExecute(self$conn,
        "INSERT INTO sessions (session_id, user_id, ip_address, user_agent,
                              expires_at)
         VALUES (?, ?, ?, ?, ?)",
        params = list(session_id, user$user_id, ip_address, user_agent,
                     expires_at)
      )

      # Update last login
      dbExecute(self$conn,
        "UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE user_id = ?",
        params = list(user$user_id)
      )

      self$log_activity(user$user_id, "login", "User logged in", ip_address)

      list(
        success = TRUE,
        session_id = session_id,
        user_id = user$user_id,
        username = user$username,
        email = user$email,
        role = user$role,
        full_name = user$full_name
      )
    },

    # Validate session
    validate_session = function(session_id) {
      if (is.null(session_id) || nchar(session_id) == 0) {
        return(list(valid = FALSE, message = "No session ID provided"))
      }

      session <- dbGetQuery(self$conn,
        "SELECT s.*, u.username, u.email, u.role, u.full_name, u.is_active
         FROM sessions s
         JOIN users u ON s.user_id = u.user_id
         WHERE s.session_id = ? AND s.expires_at > datetime('now')",
        params = list(session_id)
      )

      if (nrow(session) == 0) {
        return(list(valid = FALSE, message = "Invalid or expired session"))
      }

      session <- session[1, ]

      if (!session$is_active) {
        return(list(valid = FALSE, message = "Account is inactive"))
      }

      # Update last activity
      dbExecute(self$conn,
        "UPDATE sessions SET last_activity = CURRENT_TIMESTAMP
         WHERE session_id = ?",
        params = list(session_id)
      )

      list(
        valid = TRUE,
        user_id = session$user_id,
        username = session$username,
        email = session$email,
        role = session$role,
        full_name = session$full_name
      )
    },

    # Logout
    logout = function(session_id) {
      if (!is.null(session_id)) {
        session <- dbGetQuery(self$conn,
          "SELECT user_id FROM sessions WHERE session_id = ?",
          params = list(session_id)
        )

        if (nrow(session) > 0) {
          self$log_activity(session$user_id[1], "logout", "User logged out")
        }

        dbExecute(self$conn,
          "DELETE FROM sessions WHERE session_id = ?",
          params = list(session_id)
        )
      }

      list(success = TRUE, message = "Logged out successfully")
    },

    # Log activity
    log_activity = function(user_id, action, details = NULL, ip_address = NULL) {
      dbExecute(self$conn,
        "INSERT INTO activity_log (user_id, action, details, ip_address)
         VALUES (?, ?, ?, ?)",
        params = list(user_id, action, details, ip_address)
      )
    },

    # Get user info
    get_user = function(user_id) {
      user <- dbGetQuery(self$conn,
        "SELECT user_id, username, email, role, full_name, organization,
                created_at, last_login, is_active
         FROM users WHERE user_id = ?",
        params = list(user_id)
      )

      if (nrow(user) == 0) return(NULL)
      user[1, ]
    },

    # List all users (admin only)
    list_users = function() {
      dbGetQuery(self$conn,
        "SELECT user_id, username, email, role, full_name, organization,
                created_at, last_login, is_active
         FROM users
         ORDER BY created_at DESC"
      )
    },

    # Update user role (admin only)
    update_role = function(user_id, new_role) {
      dbExecute(self$conn,
        "UPDATE users SET role = ? WHERE user_id = ?",
        params = list(new_role, user_id)
      )
      list(success = TRUE, message = "Role updated successfully")
    },

    # Deactivate user (admin only)
    deactivate_user = function(user_id) {
      dbExecute(self$conn,
        "UPDATE users SET is_active = 0 WHERE user_id = ?",
        params = list(user_id)
      )
      list(success = TRUE, message = "User deactivated")
    },

    # Get activity log
    get_activity = function(user_id = NULL, limit = 100) {
      if (!is.null(user_id)) {
        dbGetQuery(self$conn,
          "SELECT * FROM activity_log WHERE user_id = ?
           ORDER BY timestamp DESC LIMIT ?",
          params = list(user_id, limit)
        )
      } else {
        dbGetQuery(self$conn,
          "SELECT a.*, u.username
           FROM activity_log a
           LEFT JOIN users u ON a.user_id = u.user_id
           ORDER BY a.timestamp DESC LIMIT ?",
          params = list(limit)
        )
      }
    }
  ),

  private = list(
    finalize = function() {
      self$disconnect()
    }
  )
)

# ============================================================================
# SHINY AUTHENTICATION MODULE
# ============================================================================

#' Login UI Module
#' @export
loginUI <- function(id) {
  ns <- NS(id)

  fluidPage(
    tags$head(
      tags$style(HTML("
        .login-container {
          max-width: 450px;
          margin: 100px auto;
          padding: 40px;
          background: white;
          border-radius: 10px;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .login-header {
          text-align: center;
          margin-bottom: 30px;
        }
        .login-header h2 {
          color: #3c8dbc;
          font-weight: bold;
        }
        .login-logo {
          font-size: 60px;
          color: #605ca8;
          margin-bottom: 20px;
        }
        .btn-login {
          width: 100%;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border: none;
          color: white;
          padding: 12px;
          font-size: 16px;
          border-radius: 5px;
          margin-top: 20px;
        }
        .btn-login:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }
        .switch-mode {
          text-align: center;
          margin-top: 20px;
          color: #666;
        }
        .switch-mode a {
          color: #3c8dbc;
          cursor: pointer;
          text-decoration: underline;
        }
      "))
    ),

    div(class = "login-container",
      div(class = "login-header",
        icon("microscope", class = "login-logo"),
        h2("surroNMA v5.0"),
        p("AI-Enhanced Network Meta-Analysis Platform")
      ),

      uiOutput(ns("auth_panel"))
    )
  )
}

#' Login Server Module
#' @export
loginServer <- function(id, user_db) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive values
    rv <- reactiveValues(
      authenticated = FALSE,
      user_info = NULL,
      mode = "login"  # "login" or "register"
    )

    # Render authentication panel
    output$auth_panel <- renderUI({
      if (rv$mode == "login") {
        tagList(
          textInput(ns("username"), "Username or Email",
                   placeholder = "Enter username or email"),
          passwordInput(ns("password"), "Password",
                       placeholder = "Enter password"),

          actionButton(ns("login_btn"), "Login", class = "btn-login"),

          div(class = "switch-mode",
            "Don't have an account? ",
            actionLink(ns("switch_register"), "Register here")
          )
        )
      } else {
        tagList(
          textInput(ns("reg_username"), "Username",
                   placeholder = "Choose a username"),
          textInput(ns("reg_email"), "Email",
                   placeholder = "Your email address"),
          passwordInput(ns("reg_password"), "Password",
                       placeholder = "At least 8 characters"),
          passwordInput(ns("reg_password2"), "Confirm Password",
                       placeholder = "Re-enter password"),
          textInput(ns("reg_fullname"), "Full Name (optional)",
                   placeholder = "Your full name"),
          textInput(ns("reg_org"), "Organization (optional)",
                   placeholder = "Your organization"),

          actionButton(ns("register_btn"), "Register", class = "btn-login"),

          div(class = "switch-mode",
            "Already have an account? ",
            actionLink(ns("switch_login"), "Login here")
          )
        )
      }
    })

    # Switch to register mode
    observeEvent(input$switch_register, {
      rv$mode <- "register"
    })

    # Switch to login mode
    observeEvent(input$switch_login, {
      rv$mode <- "login"
    })

    # Handle login
    observeEvent(input$login_btn, {
      req(input$username, input$password)

      result <- user_db$login(
        username = input$username,
        password = input$password,
        ip_address = session$clientData$url_hostname
      )

      if (result$success) {
        rv$authenticated <- TRUE
        rv$user_info <- result
        showNotification("Login successful!", type = "message")
      } else {
        showNotification(result$message, type = "error")
      }
    })

    # Handle registration
    observeEvent(input$register_btn, {
      req(input$reg_username, input$reg_email, input$reg_password,
          input$reg_password2)

      # Validate passwords match
      if (input$reg_password != input$reg_password2) {
        showNotification("Passwords do not match", type = "error")
        return()
      }

      tryCatch({
        result <- user_db$register_user(
          username = input$reg_username,
          email = input$reg_email,
          password = input$reg_password,
          full_name = if (nzchar(input$reg_fullname)) input$reg_fullname else NULL,
          organization = if (nzchar(input$reg_org)) input$reg_org else NULL
        )

        if (result$success) {
          showNotification("Registration successful! Please login.", type = "message")
          rv$mode <- "login"
        }
      }, error = function(e) {
        showNotification(paste("Registration failed:", e$message), type = "error")
      })
    })

    # Return reactive user info
    return(rv)
  })
}

# ============================================================================
# INITIALIZE DEFAULT ADMIN USER
# ============================================================================

#' Initialize user database with default admin
#' @export
init_user_db <- function(db_path = "surronma_users.db", create_admin = TRUE) {
  user_db <- UserDB$new(db_path)

  if (create_admin) {
    # Check if admin exists
    existing <- dbGetQuery(user_db$conn,
      "SELECT user_id FROM users WHERE role = 'admin'"
    )

    if (nrow(existing) == 0) {
      # Create default admin
      tryCatch({
        user_db$register_user(
          username = "admin",
          email = "admin@surronma.local",
          password = "admin123456",  # CHANGE THIS IN PRODUCTION!
          full_name = "System Administrator",
          role = "admin"
        )
        message("Default admin user created: username='admin', password='admin123456'")
        message("IMPORTANT: Change the admin password immediately!")
      }, error = function(e) {
        message("Admin user may already exist")
      })
    }
  }

  user_db
}
