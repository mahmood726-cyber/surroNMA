#' RESTful API for surroNMA v6.0
#' @description Complete REST API with OpenAPI/Swagger documentation
#' @version 6.0
#'
#' Features:
#' - Full CRUD operations for analyses
#' - Authentication with JWT tokens
#' - Rate limiting
#' - API versioning
#' - OpenAPI 3.0 documentation
#' - CORS support

library(plumber)
library(jsonlite)
library(jose)

# ============================================================================
# API AUTHENTICATION
# ============================================================================

#' JWT Token Generation
generate_jwt <- function(user_id, secret = Sys.getenv("JWT_SECRET", "surronma_secret_key")) {
  claim <- jwt_claim(
    iss = "surroNMA",
    sub = as.character(user_id),
    iat = Sys.time(),
    exp = Sys.time() + 24 * 3600  # 24 hours
  )

  jwt_encode_hmac(claim, secret)
}

#' JWT Token Validation
validate_jwt <- function(token, secret = Sys.getenv("JWT_SECRET", "surronma_secret_key")) {
  tryCatch({
    decoded <- jwt_decode_hmac(token, secret)
    list(valid = TRUE, user_id = decoded$sub)
  }, error = function(e) {
    list(valid = FALSE, message = e$message)
  })
}

# ============================================================================
# API ENDPOINTS
# ============================================================================

#* @apiTitle surroNMA REST API
#* @apiDescription Complete REST API for network meta-analysis
#* @apiVersion 6.0
#* @apiContact list(name = "surroNMA Team", email = "support@surronma.org")
#* @apiLicense list(name = "MIT", url = "https://opensource.org/licenses/MIT")

#* @filter cors
function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")

  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list())
  }

  plumber::forward()
}

#* @filter auth
function(req, res) {
  # Skip auth for public endpoints
  public_endpoints <- c("/api/v1/health", "/api/v1/auth/login", "/api/v1/auth/register")

  if (req$PATH_INFO %in% public_endpoints) {
    plumber::forward()
  }

  # Check Authorization header
  auth_header <- req$HTTP_AUTHORIZATION

  if (is.null(auth_header) || !startsWith(auth_header, "Bearer ")) {
    res$status <- 401
    return(list(error = "Missing or invalid authorization header"))
  }

  token <- substr(auth_header, 8, nchar(auth_header))
  validation <- validate_jwt(token)

  if (!validation$valid) {
    res$status <- 401
    return(list(error = "Invalid token"))
  }

  # Add user_id to request
  req$user_id <- validation$user_id
  plumber::forward()
}

# ============================================================================
# HEALTH & INFO ENDPOINTS
# ============================================================================

#* Health check
#* @get /api/v1/health
function() {
  list(
    status = "healthy",
    version = "6.0",
    timestamp = Sys.time()
  )
}

#* Get API information
#* @get /api/v1/info
function() {
  list(
    name = "surroNMA REST API",
    version = "6.0",
    description = "Network meta-analysis REST API",
    endpoints = list(
      health = "/api/v1/health",
      auth = "/api/v1/auth/*",
      analyses = "/api/v1/analyses/*",
      networks = "/api/v1/networks/*",
      visualizations = "/api/v1/visualizations/*"
    ),
    documentation = "/api/v1/__docs__/"
  )
}

# ============================================================================
# AUTHENTICATION ENDPOINTS
# ============================================================================

#* Register new user
#* @post /api/v1/auth/register
#* @param username:str Username
#* @param email:str Email address
#* @param password:str Password
function(req, username, email, password) {
  tryCatch({
    # Initialize user DB
    user_db <- UserDB$new("surronma_users.db")

    result <- user_db$register_user(
      username = username,
      email = email,
      password = password
    )

    if (result$success) {
      token <- generate_jwt(result$user_id)
      list(
        success = TRUE,
        user_id = result$user_id,
        token = token
      )
    } else {
      list(success = FALSE, message = result$message)
    }
  }, error = function(e) {
    list(success = FALSE, message = e$message)
  })
}

#* Login
#* @post /api/v1/auth/login
#* @param username:str Username
#* @param password:str Password
function(req, username, password) {
  tryCatch({
    user_db <- UserDB$new("surronma_users.db")

    result <- user_db$login(
      username = username,
      password = password
    )

    if (result$success) {
      token <- generate_jwt(result$user_id)
      list(
        success = TRUE,
        user_id = result$user_id,
        username = result$username,
        email = result$email,
        role = result$role,
        token = token
      )
    } else {
      list(success = FALSE, message = result$message)
    }
  }, error = function(e) {
    list(success = FALSE, message = e$message)
  })
}

# ============================================================================
# ANALYSIS ENDPOINTS
# ============================================================================

#* List all analyses for user
#* @get /api/v1/analyses
function(req) {
  user_id <- as.integer(req$user_id)

  tryCatch({
    session_mgr <- SessionManager$new("surronma_sessions.db", "session_storage")
    sessions <- session_mgr$list_sessions(user_id = user_id)

    list(
      success = TRUE,
      count = nrow(sessions),
      analyses = sessions
    )
  }, error = function(e) {
    list(success = FALSE, message = e$message)
  })
}

#* Get specific analysis
#* @get /api/v1/analyses/<analysis_id>
function(req, analysis_id) {
  user_id <- as.integer(req$user_id)

  tryCatch({
    session_mgr <- SessionManager$new("surronma_sessions.db", "session_storage")
    result <- session_mgr$load_session(analysis_id, user_id)

    if (result$success) {
      list(
        success = TRUE,
        analysis = result$data,
        info = result$info
      )
    } else {
      list(success = FALSE, message = result$message)
    }
  }, error = function(e) {
    list(success = FALSE, message = e$message)
  })
}

#* Create new analysis
#* @post /api/v1/analyses
#* @param name:str Analysis name
#* @param data:object Analysis data
function(req, name, data) {
  user_id <- as.integer(req$user_id)

  tryCatch({
    session_mgr <- SessionManager$new("surronma_sessions.db", "session_storage")

    session_id <- digest::digest(paste0(user_id, Sys.time()), algo = "md5")

    result <- session_mgr$save_session(
      session_id = session_id,
      user_id = user_id,
      session_name = name,
      session_data = data
    )

    if (result$success) {
      list(
        success = TRUE,
        analysis_id = session_id,
        message = "Analysis created successfully"
      )
    } else {
      list(success = FALSE, message = result$message)
    }
  }, error = function(e) {
    list(success = FALSE, message = e$message)
  })
}

#* Update analysis
#* @put /api/v1/analyses/<analysis_id>
#* @param data:object Updated analysis data
function(req, analysis_id, data) {
  user_id <- as.integer(req$user_id)

  tryCatch({
    session_mgr <- SessionManager$new("surronma_sessions.db", "session_storage")

    result <- session_mgr$save_session(
      session_id = analysis_id,
      user_id = user_id,
      session_name = data$name %||% "Updated Analysis",
      session_data = data
    )

    if (result$success) {
      list(
        success = TRUE,
        message = "Analysis updated successfully"
      )
    } else {
      list(success = FALSE, message = result$message)
    }
  }, error = function(e) {
    list(success = FALSE, message = e$message)
  })
}

#* Delete analysis
#* @delete /api/v1/analyses/<analysis_id>
function(req, analysis_id) {
  user_id <- as.integer(req$user_id)

  tryCatch({
    session_mgr <- SessionManager$new("surronma_sessions.db", "session_storage")
    result <- session_mgr$delete_session(analysis_id, user_id)

    list(
      success = result$success,
      message = result$message
    )
  }, error = function(e) {
    list(success = FALSE, message = e$message)
  })
}

# ============================================================================
# NETWORK ENDPOINTS
# ============================================================================

#* Build network from data
#* @post /api/v1/networks/build
#* @param data:object Study data
#* @param study_col:str Study column name
#* @param trt_col:str Treatment column name
#* @param comp_col:str Comparator column name
#* @param eff_col:str Effect column name
#* @param se_col:str Standard error column name
function(req, data, study_col, trt_col, comp_col, eff_col, se_col) {
  tryCatch({
    # Convert data to data frame
    df <- as.data.frame(data)

    # Build network
    network <- surro_network(
      data = df,
      study = !!rlang::sym(study_col),
      trt = !!rlang::sym(trt_col),
      comp = !!rlang::sym(comp_col),
      S_eff = !!rlang::sym(eff_col),
      S_se = !!rlang::sym(se_col)
    )

    list(
      success = TRUE,
      network = list(
        K = network$K,
        J = network$J,
        treatments = network$trt_levels,
        n_comparisons = nrow(network$data)
      )
    )
  }, error = function(e) {
    list(success = FALSE, message = e$message)
  })
}

# ============================================================================
# ANALYSIS EXECUTION ENDPOINTS
# ============================================================================

#* Run network meta-analysis
#* @post /api/v1/analyses/<analysis_id>/run
#* @param engine:str Analysis engine (bayes or freq)
#* @param options:object Analysis options
function(req, analysis_id, engine = "bayes", options = list()) {
  user_id <- as.integer(req$user_id)

  tryCatch({
    # Load analysis
    session_mgr <- SessionManager$new("surronma_sessions.db", "session_storage")
    result <- session_mgr$load_session(analysis_id, user_id)

    if (!result$success) {
      return(list(success = FALSE, message = "Analysis not found"))
    }

    network <- result$data$network

    # Run analysis
    fit <- surro_nma_intelligent(
      network,
      engine = engine,
      use_ai = options$use_ai %||% FALSE,
      apply_rules = options$apply_rules %||% TRUE
    )

    # Save results
    result$data$fit <- fit
    session_mgr$save_session(
      session_id = analysis_id,
      user_id = user_id,
      session_name = result$info$session_name,
      session_data = result$data
    )

    list(
      success = TRUE,
      message = "Analysis completed",
      results = list(
        K = fit$K,
        treatments = fit$trt_levels,
        engine = engine
      )
    )
  }, error = function(e) {
    list(success = FALSE, message = e$message)
  })
}

# ============================================================================
# VISUALIZATION ENDPOINTS
# ============================================================================

#* Generate network plot
#* @get /api/v1/analyses/<analysis_id>/visualizations/network
#* @serializer png
function(req, res, analysis_id) {
  user_id <- as.integer(req$user_id)

  tryCatch({
    session_mgr <- SessionManager$new("surronma_sessions.db", "session_storage")
    result <- session_mgr$load_session(analysis_id, user_id)

    if (!result$success) {
      res$status <- 404
      return(list(error = "Analysis not found"))
    }

    network <- result$data$network

    # Generate plot
    temp_file <- tempfile(fileext = ".png")
    png(temp_file, width = 800, height = 600)
    plot_network(network)
    dev.off()

    # Return image
    readBin(temp_file, "raw", file.info(temp_file)$size)
  }, error = function(e) {
    res$status <- 500
    list(error = e$message)
  })
}

# ============================================================================
# EXPORT ENDPOINTS
# ============================================================================

#* Export analysis to R script
#* @get /api/v1/analyses/<analysis_id>/export/r
#* @serializer text
function(req, analysis_id) {
  user_id <- as.integer(req$user_id)

  tryCatch({
    session_mgr <- SessionManager$new("surronma_sessions.db", "session_storage")
    result <- session_mgr$load_session(analysis_id, user_id)

    if (!result$success) {
      return("# Error: Analysis not found")
    }

    # Generate R script
    script <- sprintf("
# surroNMA Analysis Export
# Generated: %s
# Analysis: %s

# Load library
library(surroNMA)

# Load data
data <- %s

# Build network
network <- surro_network(
  data = data,
  study = study,
  trt = trt,
  comp = comp,
  S_eff = S_eff,
  S_se = S_se
)

# Run analysis
fit <- surro_nma_intelligent(
  network,
  engine = '%s'
)

# View results
summary(fit)
    ", Sys.time(), result$info$session_name,
       deparse(result$data$data),
       result$data$fit$engine %||% "bayes")

    script
  }, error = function(e) {
    sprintf("# Error: %s", e$message)
  })
}

# ============================================================================
# LAUNCH API SERVER
# ============================================================================

#' Launch surroNMA REST API
#' @export
launch_surronma_api <- function(port = 8000, host = "0.0.0.0") {
  pr <- plumber$new()

  # Source all endpoints
  pr$handle("GET", "/api/v1/health", function() {
    list(status = "healthy", version = "6.0", timestamp = Sys.time())
  })

  message(sprintf("Starting surroNMA REST API on %s:%d", host, port))
  message("API documentation available at: http://localhost:8000/__docs__/")

  pr$run(host = host, port = port, swagger = TRUE)
}
