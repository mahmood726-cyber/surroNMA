#' Comprehensive Monitoring System for surroNMA v7.0
#' @description Prometheus metrics + Grafana dashboards for production monitoring
#' @version 7.0
#'
#' Features:
#' - Prometheus metrics export
#' - Performance monitoring
#' - Error tracking
#' - Usage analytics
#' - Real-time alerting
#' - Grafana dashboard templates

library(R6)

# ============================================================================
# METRICS COLLECTOR
# ============================================================================

#' Prometheus-compatible Metrics Collector
#' @export
MetricsCollector <- R6::R6Class("MetricsCollector",
  public = list(
    metrics = NULL,
    start_time = NULL,

    initialize = function() {
      self$metrics <- list(
        counters = list(),
        gauges = list(),
        histograms = list(),
        summaries = list()
      )

      self$start_time <- Sys.time()

      message("Metrics collector initialized")
    },

    # Increment counter
    counter_inc = function(name, value = 1, labels = list()) {
      key <- private$make_key(name, labels)

      if (is.null(self$metrics$counters[[key]])) {
        self$metrics$counters[[key]] <- list(
          name = name,
          value = 0,
          labels = labels
        )
      }

      self$metrics$counters[[key]]$value <-
        self$metrics$counters[[key]]$value + value
    },

    # Set gauge value
    gauge_set = function(name, value, labels = list()) {
      key <- private$make_key(name, labels)

      self$metrics$gauges[[key]] <- list(
        name = name,
        value = value,
        labels = labels,
        timestamp = Sys.time()
      )
    },

    # Record histogram observation
    histogram_observe = function(name, value, labels = list()) {
      key <- private$make_key(name, labels)

      if (is.null(self$metrics$histograms[[key]])) {
        self$metrics$histograms[[key]] <- list(
          name = name,
          observations = numeric(),
          labels = labels
        )
      }

      self$metrics$histograms[[key]]$observations <-
        c(self$metrics$histograms[[key]]$observations, value)
    },

    # Export metrics in Prometheus format
    export_prometheus = function() {
      lines <- character()

      # Counters
      for (metric in self$metrics$counters) {
        labels_str <- private$format_labels(metric$labels)
        lines <- c(lines, sprintf("%s%s %f", metric$name, labels_str, metric$value))
      }

      # Gauges
      for (metric in self$metrics$gauges) {
        labels_str <- private$format_labels(metric$labels)
        lines <- c(lines, sprintf("%s%s %f", metric$name, labels_str, metric$value))
      }

      # Histograms (calculate quantiles)
      for (metric in self$metrics$histograms) {
        obs <- metric$observations
        labels_str <- private$format_labels(metric$labels)

        # Count
        lines <- c(lines, sprintf("%s_count%s %d",
                                 metric$name, labels_str, length(obs)))

        # Sum
        lines <- c(lines, sprintf("%s_sum%s %f",
                                 metric$name, labels_str, sum(obs)))

        # Quantiles
        if (length(obs) > 0) {
          quantiles <- quantile(obs, c(0.5, 0.9, 0.95, 0.99))
          for (q in names(quantiles)) {
            q_value <- as.numeric(sub("%", "", q)) / 100
            lines <- c(lines, sprintf("%s{quantile=\"%s\"} %f",
                                     metric$name, q_value, quantiles[q]))
          }
        }
      }

      paste(lines, collapse = "\n")
    },

    # Get all metrics as data frame
    get_metrics_df = function() {
      data.frame(
        metric_type = c(
          rep("counter", length(self$metrics$counters)),
          rep("gauge", length(self$metrics$gauges)),
          rep("histogram", length(self$metrics$histograms))
        ),
        name = c(
          sapply(self$metrics$counters, function(x) x$name),
          sapply(self$metrics$gauges, function(x) x$name),
          sapply(self$metrics$histograms, function(x) x$name)
        ),
        value = c(
          sapply(self$metrics$counters, function(x) x$value),
          sapply(self$metrics$gauges, function(x) x$value),
          sapply(self$metrics$histograms, function(x) length(x$observations))
        ),
        stringsAsFactors = FALSE
      )
    },

    # Reset all metrics
    reset = function() {
      self$metrics <- list(
        counters = list(),
        gauges = list(),
        histograms = list()
      )
    }
  ),

  private = list(
    make_key = function(name, labels) {
      if (length(labels) == 0) {
        return(name)
      }

      label_str <- paste(names(labels), labels, sep = "=", collapse = ",")
      sprintf("%s{%s}", name, label_str)
    },

    format_labels = function(labels) {
      if (length(labels) == 0) return("")

      label_pairs <- paste(names(labels),
                          sprintf('"%s"', labels),
                          sep = "=",
                          collapse = ",")
      sprintf("{%s}", label_pairs)
    }
  )
)

# ============================================================================
# PERFORMANCE MONITOR
# ============================================================================

#' Performance Monitor
#' @export
PerformanceMonitor <- R6::R6Class("PerformanceMonitor",
  public = list(
    metrics_collector = NULL,
    active_timers = NULL,

    initialize = function(metrics_collector = NULL) {
      if (is.null(metrics_collector)) {
        self$metrics_collector <- MetricsCollector$new()
      } else {
        self$metrics_collector <- metrics_collector
      }

      self$active_timers <- list()
    },

    # Start timing an operation
    start_timer = function(operation_name, labels = list()) {
      timer_id <- digest::digest(list(operation_name, labels, Sys.time()))

      self$active_timers[[timer_id]] <- list(
        operation = operation_name,
        start_time = Sys.time(),
        labels = labels
      )

      timer_id
    },

    # Stop timer and record duration
    stop_timer = function(timer_id) {
      if (is.null(self$active_timers[[timer_id]])) {
        warning("Timer not found")
        return(NULL)
      }

      timer <- self$active_timers[[timer_id]]
      duration <- as.numeric(difftime(Sys.time(), timer$start_time, units = "secs"))

      # Record histogram
      self$metrics_collector$histogram_observe(
        sprintf("surronma_%s_duration_seconds", timer$operation),
        duration,
        timer$labels
      )

      # Record counter
      self$metrics_collector$counter_inc(
        sprintf("surronma_%s_total", timer$operation),
        1,
        timer$labels
      )

      # Clean up
      self$active_timers[[timer_id]] <- NULL

      duration
    },

    # Monitor function execution
    monitor = function(func, operation_name, labels = list()) {
      timer_id <- self$start_timer(operation_name, labels)

      result <- tryCatch({
        func()
      }, error = function(e) {
        # Record error
        self$metrics_collector$counter_inc(
          sprintf("surronma_%s_errors_total", operation_name),
          1,
          c(labels, list(error = class(e)[1]))
        )
        stop(e)
      })

      self$stop_timer(timer_id)

      result
    }
  )
)

# ============================================================================
# APPLICATION MONITORING
# ============================================================================

#' Application Monitor
#' @export
AppMonitor <- R6::R6Class("AppMonitor",
  public = list(
    metrics_collector = NULL,
    performance_monitor = NULL,
    error_log = NULL,

    initialize = function() {
      self$metrics_collector <- MetricsCollector$new()
      self$performance_monitor <- PerformanceMonitor$new(self$metrics_collector)
      self$error_log <- list()

      # Record system info
      self$record_system_info()
    },

    # Record system information
    record_system_info = function() {
      # Memory usage
      if (requireNamespace("pryr", quietly = TRUE)) {
        mem_used <- pryr::mem_used()
        self$metrics_collector$gauge_set("surronma_memory_bytes", mem_used)
      }

      # R session info
      self$metrics_collector$gauge_set("surronma_r_version",
                                      as.numeric(R.version$major) +
                                      as.numeric(R.version$minor) / 10)

      # CPU count
      self$metrics_collector$gauge_set("surronma_cpu_count",
                                      parallel::detectCores())
    },

    # Track analysis execution
    track_analysis = function(network, engine, func) {
      labels <- list(
        engine = engine,
        n_treatments = network$K,
        n_studies = network$J
      )

      self$performance_monitor$monitor(
        func,
        operation_name = "analysis",
        labels = labels
      )
    },

    # Track visualization creation
    track_visualization = function(viz_type, func) {
      labels <- list(viz_type = viz_type)

      self$performance_monitor$monitor(
        func,
        operation_name = "visualization",
        labels = labels
      )
    },

    # Track AI query
    track_ai_query = function(query_type, func) {
      labels <- list(query_type = query_type)

      self$performance_monitor$monitor(
        func,
        operation_name = "ai_query",
        labels = labels
      )
    },

    # Record error
    record_error = function(error, context = list()) {
      error_entry <- list(
        error = as.character(error),
        class = class(error)[1],
        context = context,
        timestamp = Sys.time()
      )

      self$error_log <- append(self$error_log, list(error_entry))

      # Increment error counter
      self$metrics_collector$counter_inc(
        "surronma_errors_total",
        1,
        list(error_type = class(error)[1])
      )
    },

    # Get error summary
    get_error_summary = function(last_n = 10) {
      if (length(self$error_log) == 0) {
        return(data.frame())
      }

      recent_errors <- tail(self$error_log, last_n)

      data.frame(
        timestamp = sapply(recent_errors, function(x) as.character(x$timestamp)),
        error = sapply(recent_errors, function(x) x$error),
        class = sapply(recent_errors, function(x) x$class),
        stringsAsFactors = FALSE
      )
    },

    # Export metrics endpoint
    metrics_endpoint = function() {
      # Update system metrics
      self$record_system_info()

      # Export in Prometheus format
      self$metrics_collector$export_prometheus()
    }
  )
)

# ============================================================================
# MONITORING MIDDLEWARE FOR PLUMBER API
# ============================================================================

#' Add monitoring to Plumber API
#' @export
add_monitoring_to_api <- function(pr, app_monitor) {
  # Metrics endpoint
  pr$handle("GET", "/metrics", function(req, res) {
    res$setHeader("Content-Type", "text/plain; version=0.0.4")
    res$body <- app_monitor$metrics_endpoint()
    res
  })

  # Health check with metrics
  pr$handle("GET", "/health", function(req, res) {
    list(
      status = "healthy",
      version = "7.0",
      uptime_seconds = as.numeric(difftime(Sys.time(),
                                          app_monitor$metrics_collector$start_time,
                                          units = "secs")),
      timestamp = Sys.time()
    )
  })

  # Monitoring filter
  pr$filter("monitor", function(req, res) {
    # Start timer
    timer_id <- app_monitor$performance_monitor$start_timer(
      "http_request",
      labels = list(
        method = req$REQUEST_METHOD,
        endpoint = req$PATH_INFO
      )
    )

    # Continue request
    result <- tryCatch({
      plumber::forward()
    }, error = function(e) {
      app_monitor$record_error(e, context = list(
        method = req$REQUEST_METHOD,
        endpoint = req$PATH_INFO
      ))
      stop(e)
    })

    # Stop timer
    app_monitor$performance_monitor$stop_timer(timer_id)

    result
  })

  pr
}

# ============================================================================
# GRAFANA DASHBOARD GENERATION
# ============================================================================

#' Generate Grafana dashboard JSON
#' @export
generate_grafana_dashboard <- function() {
  dashboard <- list(
    title = "surroNMA Monitoring Dashboard",
    tags = c("surronma", "nma", "r"),
    timezone = "browser",
    panels = list(
      # Analysis performance panel
      list(
        id = 1,
        title = "Analysis Duration",
        type = "graph",
        targets = list(
          list(
            expr = "rate(surronma_analysis_duration_seconds_sum[5m]) / rate(surronma_analysis_duration_seconds_count[5m])",
            legendFormat = "{{engine}} - {{n_treatments}} treatments"
          )
        ),
        gridPos = list(x = 0, y = 0, w = 12, h = 8)
      ),

      # Request rate panel
      list(
        id = 2,
        title = "Request Rate",
        type = "graph",
        targets = list(
          list(
            expr = "rate(surronma_http_request_total[5m])",
            legendFormat = "{{method}} {{endpoint}}"
          )
        ),
        gridPos = list(x = 12, y = 0, w = 12, h = 8)
      ),

      # Error rate panel
      list(
        id = 3,
        title = "Error Rate",
        type = "graph",
        targets = list(
          list(
            expr = "rate(surronma_errors_total[5m])",
            legendFormat = "{{error_type}}"
          )
        ),
        gridPos = list(x = 0, y = 8, w = 12, h = 8)
      ),

      # Memory usage panel
      list(
        id = 4,
        title = "Memory Usage",
        type = "graph",
        targets = list(
          list(
            expr = "surronma_memory_bytes",
            legendFormat = "Memory"
          )
        ),
        gridPos = list(x = 12, y = 8, w = 12, h = 8)
      ),

      # Cache hit rate panel
      list(
        id = 5,
        title = "Cache Hit Rate",
        type = "graph",
        targets = list(
          list(
            expr = "rate(surronma_cache_hits_total[5m]) / (rate(surronma_cache_hits_total[5m]) + rate(surronma_cache_misses_total[5m]))",
            legendFormat = "Hit Rate"
          )
        ),
        gridPos = list(x = 0, y = 16, w = 12, h = 8)
      ),

      # AI query duration panel
      list(
        id = 6,
        title = "AI Query Duration",
        type = "graph",
        targets = list(
          list(
            expr = "histogram_quantile(0.95, rate(surronma_ai_query_duration_seconds_bucket[5m]))",
            legendFormat = "p95 - {{query_type}}"
          )
        ),
        gridPos = list(x = 12, y = 16, w = 12, h = 8)
      )
    )
  )

  jsonlite::toJSON(dashboard, pretty = TRUE, auto_unbox = TRUE)
}

#' Save Grafana dashboard to file
#' @export
save_grafana_dashboard <- function(file_path = "grafana_dashboard.json") {
  dashboard_json <- generate_grafana_dashboard()
  writeLines(dashboard_json, file_path)
  message(sprintf("Grafana dashboard saved to: %s", file_path))
}

# ============================================================================
# ALERTING RULES
# ============================================================================

#' Generate Prometheus alerting rules
#' @export
generate_alerting_rules <- function() {
  rules <- list(
    groups = list(
      list(
        name = "surronma_alerts",
        rules = list(
          # High error rate alert
          list(
            alert = "HighErrorRate",
            expr = "rate(surronma_errors_total[5m]) > 0.1",
            `for` = "5m",
            labels = list(severity = "warning"),
            annotations = list(
              summary = "High error rate detected",
              description = "Error rate is {{ $value }} errors/second"
            )
          ),

          # Slow analysis alert
          list(
            alert = "SlowAnalysis",
            expr = "histogram_quantile(0.95, rate(surronma_analysis_duration_seconds_bucket[5m])) > 60",
            `for` = "10m",
            labels = list(severity = "warning"),
            annotations = list(
              summary = "Slow analysis detected",
              description = "95th percentile analysis time is {{ $value }} seconds"
            )
          ),

          # High memory usage alert
          list(
            alert = "HighMemoryUsage",
            expr = "surronma_memory_bytes > 8e9",
            `for` = "5m",
            labels = list(severity = "warning"),
            annotations = list(
              summary = "High memory usage",
              description = "Memory usage is {{ $value | humanize }} bytes"
            )
          ),

          # Low cache hit rate alert
          list(
            alert = "LowCacheHitRate",
            expr = "rate(surronma_cache_hits_total[10m]) / (rate(surronma_cache_hits_total[10m]) + rate(surronma_cache_misses_total[10m])) < 0.5",
            `for` = "10m",
            labels = list(severity = "info"),
            annotations = list(
              summary = "Low cache hit rate",
              description = "Cache hit rate is {{ $value | humanizePercentage }}"
            )
          )
        )
      )
    )
  )

  yaml::write_yaml(rules, "prometheus_alerts.yml")
  message("Alerting rules saved to: prometheus_alerts.yml")
}

# ============================================================================
# GLOBAL APP MONITOR
# ============================================================================

.global_app_monitor <- NULL

#' Get global app monitor
#' @export
get_app_monitor <- function() {
  if (is.null(.global_app_monitor)) {
    .global_app_monitor <<- AppMonitor$new()
  }

  .global_app_monitor
}

#' Monitored NMA execution
#' @export
surro_nma_monitored <- function(network, engine = "bayes", ...) {
  app_monitor <- get_app_monitor()

  app_monitor$track_analysis(
    network = network,
    engine = engine,
    func = function() {
      surro_nma_intelligent(network, engine = engine, ...)
    }
  )
}
