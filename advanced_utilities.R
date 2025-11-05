#' Advanced Utility Functions for surroNMA v8.0+
#' @description Enhanced utilities inspired by mahmood726-cyber patterns
#' @version 8.1
#'
#' Patterns from mahmood726-cyber repositories:
#' - Advanced reactive programming
#' - Real-time updates
#' - Performance optimization
#' - Elegant error handling
#' - Data pipeline utilities

library(R6)

# ============================================================================
# ADVANCED REACTIVE PROGRAMMING PATTERNS
# ============================================================================

#' Advanced Reactive State Manager
#' @description Sophisticated state management for Shiny apps
#' @export
ReactiveStateManager <- R6::R6Class("ReactiveStateManager",
  public = list(
    states = NULL,
    history = NULL,
    max_history = 50,

    initialize = function(initial_state = list()) {
      self$states <- reactiveValues()
      self$history <- list()

      # Set initial state
      for (key in names(initial_state)) {
        self$states[[key]] <- initial_state[[key]]
      }
    },

    # Set state with history tracking
    set = function(key, value, track_history = TRUE) {
      old_value <- self$states[[key]]
      self$states[[key]] <- value

      if (track_history && !is.null(old_value)) {
        self$history <- append(self$history, list(list(
          timestamp = Sys.time(),
          key = key,
          old_value = old_value,
          new_value = value
        )))

        # Limit history size
        if (length(self$history) > self$max_history) {
          self$history <- tail(self$history, self$max_history)
        }
      }
    },

    # Get state
    get = function(key, default = NULL) {
      value <- self$states[[key]]
      if (is.null(value)) return(default)
      value
    },

    # Undo last change
    undo = function() {
      if (length(self$history) == 0) {
        message("No history to undo")
        return(NULL)
      }

      last_change <- tail(self$history, 1)[[1]]
      self$states[[last_change$key]] <- last_change$old_value
      self$history <- head(self$history, -1)

      message(sprintf("Undid change to '%s'", last_change$key))
      last_change
    },

    # Get change history
    get_history = function(n = 10) {
      tail(self$history, n)
    },

    # Clear all state
    reset = function(confirm = TRUE) {
      if (confirm) {
        for (key in names(self$states)) {
          self$states[[key]] <- NULL
        }
        self$history <- list()
        message("State reset complete")
      }
    }
  )
)

# ============================================================================
# REAL-TIME UPDATE MANAGER
# ============================================================================

#' Real-Time Update Manager
#' @description Manages WebSocket-like real-time updates
#' @export
RealtimeUpdateManager <- R6::R6Class("RealtimeUpdateManager",
  public = list(
    update_queue = NULL,
    subscribers = NULL,
    update_interval = 500,  # milliseconds

    initialize = function(update_interval = 500) {
      self$update_queue <- list()
      self$subscribers <- list()
      self$update_interval <- update_interval
    },

    # Subscribe to updates
    subscribe = function(id, callback) {
      self$subscribers[[id]] <- callback
      message(sprintf("Subscribed: %s", id))
    },

    # Unsubscribe from updates
    unsubscribe = function(id) {
      self$subscribers[[id]] <- NULL
      message(sprintf("Unsubscribed: %s", id))
    },

    # Publish update
    publish = function(event, data) {
      update <- list(
        timestamp = Sys.time(),
        event = event,
        data = data
      )

      # Add to queue
      self$update_queue <- append(self$update_queue, list(update))

      # Notify subscribers
      private$notify_subscribers(update)
    },

    # Get pending updates
    get_updates = function(since = NULL) {
      if (is.null(since)) {
        return(self$update_queue)
      }

      Filter(function(u) u$timestamp > since, self$update_queue)
    },

    # Clear old updates
    prune = function(keep_last = 100) {
      if (length(self$update_queue) > keep_last) {
        self$update_queue <- tail(self$update_queue, keep_last)
      }
    }
  ),

  private = list(
    notify_subscribers = function(update) {
      for (id in names(self$subscribers)) {
        callback <- self$subscribers[[id]]
        tryCatch({
          callback(update)
        }, error = function(e) {
          warning(sprintf("Subscriber %s callback failed: %s", id, e$message))
        })
      }
    }
  )
)

# ============================================================================
# PERFORMANCE MONITOR
# ============================================================================

#' Performance Monitor with Benchmarking
#' @export
PerformanceBenchmark <- R6::R6Class("PerformanceBenchmark",
  public = list(
    timings = NULL,

    initialize = function() {
      self$timings <- data.frame(
        operation = character(),
        duration_ms = numeric(),
        timestamp = character(),
        stringsAsFactors = FALSE
      )
    },

    # Time an operation
    time = function(operation_name, expr) {
      start_time <- Sys.time()

      result <- tryCatch({
        force(expr)
      }, error = function(e) {
        message(sprintf("Operation '%s' failed: %s", operation_name, e$message))
        NULL
      })

      end_time <- Sys.time()
      duration_ms <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000

      # Record timing
      self$timings <- rbind(self$timings, data.frame(
        operation = operation_name,
        duration_ms = duration_ms,
        timestamp = as.character(Sys.time()),
        stringsAsFactors = FALSE
      ))

      message(sprintf("✓ %s: %.2f ms", operation_name, duration_ms))

      result
    },

    # Get statistics
    get_stats = function() {
      if (nrow(self$timings) == 0) {
        return(NULL)
      }

      stats <- aggregate(duration_ms ~ operation,
                        data = self$timings,
                        FUN = function(x) c(
                          mean = mean(x),
                          median = median(x),
                          min = min(x),
                          max = max(x),
                          sd = sd(x),
                          n = length(x)
                        ))

      stats
    },

    # Compare operations
    compare = function(operations = NULL) {
      if (is.null(operations)) {
        operations <- unique(self$timings$operation)
      }

      subset_data <- self$timings[self$timings$operation %in% operations, ]

      if (nrow(subset_data) == 0) {
        message("No data for specified operations")
        return(NULL)
      }

      # Plot comparison
      par(mar = c(10, 5, 4, 2))
      boxplot(duration_ms ~ operation,
              data = subset_data,
              las = 2,
              col = rainbow(length(operations)),
              main = "Performance Comparison",
              ylab = "Duration (ms)")

      invisible(subset_data)
    },

    # Export report
    export_report = function(file = "performance_report.csv") {
      write.csv(self$timings, file, row.names = FALSE)
      message(sprintf("Performance report saved to: %s", file))
    }
  )
)

# ============================================================================
# DATA PIPELINE UTILITIES
# ============================================================================

#' Smart Data Loader with Validation
#' @export
SmartDataLoader <- R6::R6Class("SmartDataLoader",
  public = list(
    data = NULL,
    metadata = NULL,
    validation_rules = NULL,

    initialize = function() {
      self$validation_rules <- list()
    },

    # Load data with automatic format detection
    load = function(source, format = "auto") {
      message(sprintf("Loading data from: %s", source))

      # Auto-detect format
      if (format == "auto") {
        format <- private$detect_format(source)
      }

      # Load based on format
      self$data <- switch(format,
        "csv" = read.csv(source, stringsAsFactors = FALSE),
        "tsv" = read.delim(source, stringsAsFactors = FALSE),
        "excel" = readxl::read_excel(source),
        "rds" = readRDS(source),
        "json" = jsonlite::fromJSON(source),
        stop(sprintf("Unsupported format: %s", format))
      )

      # Store metadata
      self$metadata <- list(
        source = source,
        format = format,
        nrow = nrow(self$data),
        ncol = ncol(self$data),
        columns = names(self$data),
        loaded_at = Sys.time()
      )

      message(sprintf("✓ Loaded %d rows × %d columns",
                     self$metadata$nrow,
                     self$metadata$ncol))

      # Auto-validate
      self$validate()

      invisible(self$data)
    },

    # Add validation rule
    add_rule = function(name, condition, message) {
      self$validation_rules[[name]] <- list(
        condition = condition,
        message = message
      )
    },

    # Validate data
    validate = function() {
      if (is.null(self$data)) {
        warning("No data to validate")
        return(FALSE)
      }

      issues <- character()

      # Built-in validations
      if (any(duplicated(self$data))) {
        issues <- c(issues, "Duplicate rows detected")
      }

      if (any(is.na(self$data))) {
        na_count <- sum(is.na(self$data))
        issues <- c(issues, sprintf("%d missing values detected", na_count))
      }

      # Custom validations
      for (rule_name in names(self$validation_rules)) {
        rule <- self$validation_rules[[rule_name]]

        if (!rule$condition(self$data)) {
          issues <- c(issues, sprintf("%s: %s", rule_name, rule$message))
        }
      }

      # Report
      if (length(issues) > 0) {
        warning("Validation issues found:")
        for (issue in issues) {
          message(sprintf("  ⚠ %s", issue))
        }
        return(FALSE)
      } else {
        message("✓ All validations passed")
        return(TRUE)
      }
    },

    # Quick summary
    summary = function() {
      if (is.null(self$data)) {
        message("No data loaded")
        return(NULL)
      }

      cat("=== Data Summary ===\n")
      cat(sprintf("Source: %s\n", self$metadata$source))
      cat(sprintf("Format: %s\n", self$metadata$format))
      cat(sprintf("Dimensions: %d × %d\n", self$metadata$nrow, self$metadata$ncol))
      cat(sprintf("Loaded: %s\n", self$metadata$loaded_at))
      cat("\nColumns:\n")
      print(str(self$data, max.level = 1))
    }
  ),

  private = list(
    detect_format = function(source) {
      ext <- tools::file_ext(source)

      switch(tolower(ext),
        "csv" = "csv",
        "tsv" = "tsv",
        "txt" = "tsv",
        "xlsx" = "excel",
        "xls" = "excel",
        "rds" = "rds",
        "json" = "json",
        "csv"  # default
      )
    }
  )
)

# ============================================================================
# ELEGANT ERROR HANDLING
# ============================================================================

#' Safe Execution Wrapper
#' @export
safe_execute <- function(expr,
                        on_error = NULL,
                        on_warning = NULL,
                        silent = FALSE,
                        retry = 0,
                        retry_delay = 1) {

  attempts <- 0
  max_attempts <- retry + 1

  while (attempts < max_attempts) {
    attempts <- attempts + 1

    result <- tryCatch({
      withCallingHandlers({
        force(expr)
      }, warning = function(w) {
        if (!silent) {
          message(sprintf("⚠ Warning: %s", w$message))
        }
        if (!is.null(on_warning)) {
          on_warning(w)
        }
      })
    }, error = function(e) {
      if (!silent) {
        message(sprintf("✗ Error (attempt %d/%d): %s",
                       attempts, max_attempts, e$message))
      }

      if (attempts < max_attempts) {
        message(sprintf("  Retrying in %d seconds...", retry_delay))
        Sys.sleep(retry_delay)
        return(NULL)  # Trigger retry
      }

      if (!is.null(on_error)) {
        return(on_error(e))
      }

      stop(e)
    })

    if (!is.null(result) || attempts >= max_attempts) {
      break
    }
  }

  result
}

# ============================================================================
# PROGRESS TRACKER WITH ETA
# ============================================================================

#' Advanced Progress Tracker
#' @export
AdvancedProgress <- R6::R6Class("AdvancedProgress",
  public = list(
    total = 0,
    current = 0,
    start_time = NULL,
    description = "",
    width = 50,

    initialize = function(total, description = "Processing") {
      self$total <- total
      self$current <- 0
      self$start_time <- Sys.time()
      self$description <- description

      self$render()
    },

    # Update progress
    tick = function(n = 1, message = NULL) {
      self$current <- min(self$current + n, self$total)
      self$render(message)
    },

    # Render progress bar
    render = function(message = NULL) {
      pct <- self$current / self$total
      filled <- round(self$width * pct)

      # Calculate ETA
      elapsed <- difftime(Sys.time(), self$start_time, units = "secs")
      rate <- self$current / as.numeric(elapsed)
      remaining <- (self$total - self$current) / rate

      # Format time
      eta_str <- if (is.finite(remaining)) {
        sprintf("ETA: %s", private$format_time(remaining))
      } else {
        "ETA: calculating..."
      }

      # Build bar
      bar <- sprintf("[%s%s]",
                    paste(rep("=", filled), collapse = ""),
                    paste(rep(" ", self$width - filled), collapse = ""))

      # Build status line
      status <- sprintf("\r%s %s %.1f%% (%d/%d) %s",
                       self$description,
                       bar,
                       pct * 100,
                       self$current,
                       self$total,
                       eta_str)

      if (!is.null(message)) {
        status <- sprintf("%s | %s", status, message)
      }

      cat(status)

      if (self$current >= self$total) {
        cat("\n✓ Complete!\n")
      }

      flush.console()
    },

    # Mark as complete
    done = function() {
      self$current <- self$total
      self$render()
    }
  ),

  private = list(
    format_time = function(seconds) {
      if (seconds < 60) {
        return(sprintf("%.0fs", seconds))
      } else if (seconds < 3600) {
        return(sprintf("%.0fm %.0fs", seconds %/% 60, seconds %% 60))
      } else {
        hours <- seconds %/% 3600
        minutes <- (seconds %% 3600) %/% 60
        return(sprintf("%.0fh %.0fm", hours, minutes))
      }
    }
  )
)

# ============================================================================
# CONVENIENCE FUNCTIONS
# ============================================================================

#' Create a smart progress tracker
#' @export
progress <- function(total, description = "Processing") {
  AdvancedProgress$new(total, description)
}

#' Benchmark multiple functions
#' @export
benchmark_functions <- function(..., times = 10) {
  funcs <- list(...)
  func_names <- as.character(substitute(list(...)))[-1]

  results <- data.frame(
    function_name = character(),
    mean_ms = numeric(),
    median_ms = numeric(),
    min_ms = numeric(),
    max_ms = numeric(),
    stringsAsFactors = FALSE
  )

  for (i in seq_along(funcs)) {
    func <- funcs[[i]]
    name <- func_names[i]

    timings <- numeric(times)

    for (j in 1:times) {
      start <- Sys.time()
      func()
      end <- Sys.time()
      timings[j] <- as.numeric(difftime(end, start, units = "secs")) * 1000
    }

    results <- rbind(results, data.frame(
      function_name = name,
      mean_ms = mean(timings),
      median_ms = median(timings),
      min_ms = min(timings),
      max_ms = max(timings),
      stringsAsFactors = FALSE
    ))
  }

  results
}

#' Memoization wrapper
#' @export
memoize <- function(f) {
  cache <- new.env(parent = emptyenv())

  function(...) {
    key <- digest::digest(list(...))

    if (exists(key, envir = cache)) {
      return(get(key, envir = cache))
    }

    result <- f(...)
    assign(key, result, envir = cache)
    result
  }
}
