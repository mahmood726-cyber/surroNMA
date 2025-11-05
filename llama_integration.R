#' surroNMA Llama 3 Integration - AI-Enhanced Network Meta-Analysis
#' @description Local Ollama-based LLM integration for automated analysis,
#'              interpretation, and quality assessment using Llama 3
#' @version 2.0

# ============================================================================
# LLAMA 3 CONNECTION MANAGER
# ============================================================================

#' Ollama connection class
#' @export
OllamaConnection <- R6::R6Class("OllamaConnection",
  public = list(
    base_url = "http://localhost:11434",
    model = "llama3",
    timeout = 300,

    initialize = function(base_url = "http://localhost:11434",
                         model = "llama3",
                         timeout = 300) {
      self$base_url <- base_url
      self$model <- model
      self$timeout <- timeout
    },

    is_available = function() {
      tryCatch({
        if (!requireNamespace("httr", quietly = TRUE)) {
          message("httr package required. Install with: install.packages('httr')")
          return(FALSE)
        }
        response <- httr::GET(paste0(self$base_url, "/api/tags"),
                            httr::timeout(5))
        httr::status_code(response) == 200
      }, error = function(e) {
        FALSE
      })
    },

    generate = function(prompt, system = NULL, temperature = 0.7,
                       max_tokens = 2000, stream = FALSE) {
      if (!self$is_available()) {
        stop("Ollama is not available. Please start Ollama service and ensure model is installed.")
      }

      if (!requireNamespace("httr", quietly = TRUE)) {
        stop("httr package required")
      }
      if (!requireNamespace("jsonlite", quietly = TRUE)) {
        stop("jsonlite package required")
      }

      body <- list(
        model = self$model,
        prompt = prompt,
        stream = stream,
        options = list(
          temperature = temperature,
          num_predict = max_tokens
        )
      )

      if (!is.null(system)) {
        body$system <- system
      }

      response <- httr::POST(
        paste0(self$base_url, "/api/generate"),
        body = jsonlite::toJSON(body, auto_unbox = TRUE),
        httr::content_type_json(),
        httr::timeout(self$timeout)
      )

      if (httr::status_code(response) != 200) {
        stop(sprintf("Ollama API error: %d", httr::status_code(response)))
      }

      result <- httr::content(response, "text", encoding = "UTF-8")
      parsed <- jsonlite::fromJSON(result)

      list(
        response = parsed$response,
        model = parsed$model,
        created_at = parsed$created_at,
        done = parsed$done
      )
    },

    chat = function(messages, temperature = 0.7, max_tokens = 2000) {
      if (!self$is_available()) {
        stop("Ollama is not available")
      }

      if (!requireNamespace("httr", quietly = TRUE)) {
        stop("httr package required")
      }
      if (!requireNamespace("jsonlite", quietly = TRUE)) {
        stop("jsonlite package required")
      }

      body <- list(
        model = self$model,
        messages = messages,
        stream = FALSE,
        options = list(
          temperature = temperature,
          num_predict = max_tokens
        )
      )

      response <- httr::POST(
        paste0(self$base_url, "/api/chat"),
        body = jsonlite::toJSON(body, auto_unbox = TRUE),
        httr::content_type_json(),
        httr::timeout(self$timeout)
      )

      if (httr::status_code(response) != 200) {
        stop(sprintf("Ollama API error: %d", httr::status_code(response)))
      }

      result <- httr::content(response, "text", encoding = "UTF-8")
      parsed <- jsonlite::fromJSON(result)

      list(
        message = parsed$message,
        model = parsed$model,
        done = parsed$done
      )
    }
  )
)

# ============================================================================
# AI-ENHANCED ANALYSIS FUNCTIONS
# ============================================================================

#' Initialize Llama 3 for surroNMA
#' @export
init_llama <- function(base_url = "http://localhost:11434",
                       model = "llama3") {
  conn <- OllamaConnection$new(base_url = base_url, model = model)

  if (!conn$is_available()) {
    message("\n⚠️  Ollama is not available!")
    message("To use AI-enhanced features:")
    message("1. Install Ollama: https://ollama.ai")
    message("2. Start Ollama service: ollama serve")
    message("3. Pull Llama 3: ollama pull llama3")
    message("4. Run this function again\n")
    return(invisible(NULL))
  }

  message("✓ Llama 3 connected successfully via Ollama")
  conn
}

#' AI-powered study data extraction
#' @export
llama_extract_study_data <- function(text, llama_conn) {
  if (is.null(llama_conn)) {
    stop("Llama connection required. Run init_llama() first.")
  }

  system_prompt <- "You are an expert in clinical trial data extraction. Extract structured data from study descriptions including: treatments, sample sizes, endpoints, effect sizes, and standard errors. Provide output in JSON format."

  prompt <- sprintf("Extract meta-analysis data from this study description:\n\n%s\n\nProvide structured JSON output with fields: study_id, treatments, n, surrogate_effect, surrogate_se, true_effect, true_se", text)

  result <- llama_conn$generate(prompt, system = system_prompt, temperature = 0.3)

  tryCatch({
    jsonlite::fromJSON(result$response)
  }, error = function(e) {
    message("Could not parse JSON response")
    result$response
  })
}

#' AI-powered quality assessment
#' @export
llama_assess_quality <- function(study_data, llama_conn) {
  if (is.null(llama_conn)) {
    stop("Llama connection required")
  }

  system_prompt <- "You are an expert in assessing the quality and risk of bias in clinical trials. Evaluate studies using Cochrane Risk of Bias criteria."

  # Prepare study summary
  study_summary <- sprintf(
    "Studies: %d\nTreatments: %d\nTotal comparisons: %d\nMissing data: %.1f%%",
    length(unique(study_data$study)),
    length(unique(c(study_data$trt, study_data$comp))),
    nrow(study_data),
    sum(is.na(study_data$T_eff)) / nrow(study_data) * 100
  )

  prompt <- sprintf("Assess the quality and potential biases in this network meta-analysis:\n\n%s\n\nProvide detailed assessment covering: risk of bias, publication bias, heterogeneity concerns, and overall confidence in results.", study_summary)

  result <- llama_conn$generate(prompt, system = system_prompt, temperature = 0.5)

  list(
    assessment = result$response,
    timestamp = Sys.time()
  )
}

#' AI-powered interpretation of results
#' @export
llama_interpret_results <- function(fit, llama_conn, clinical_context = NULL) {
  if (is.null(llama_conn)) {
    stop("Llama connection required")
  }

  # Extract key results
  summary_stats <- summarize_treatments(fit)
  ranks <- compute_ranks(fit)

  results_text <- sprintf(
    "Network Meta-Analysis Results:\n\n" %+%
    "Engine: %s\n" %+%
    "Number of treatments: %d\n" %+%
    "Number of studies: %d\n\n" %+%
    "Treatment Effects (relative to reference):\n%s\n\n" %+%
    "SUCRA Rankings:\n%s",
    fit$engine,
    fit$net$K,
    fit$net$J,
    paste(capture.output(print(summary_stats)), collapse = "\n"),
    paste(names(sort(ranks$sucra, decreasing = TRUE)), collapse = " > ")
  )

  if (!is.null(clinical_context)) {
    results_text <- paste0(results_text, "\n\nClinical Context: ", clinical_context)
  }

  system_prompt <- "You are an expert clinical researcher and biostatistician. Interpret network meta-analysis results for clinical and regulatory audiences. Focus on clinical significance, certainty of evidence, and practical implications."

  prompt <- sprintf("%s\n\nProvide a comprehensive interpretation including:\n1. Clinical significance of findings\n2. Certainty and limitations\n3. Practical implications\n4. Recommendations for decision-makers", results_text)

  result <- llama_conn$generate(prompt, system = system_prompt, temperature = 0.6, max_tokens = 3000)

  list(
    interpretation = result$response,
    summary_stats = summary_stats,
    rankings = ranks,
    timestamp = Sys.time()
  )
}

#' AI-powered report generation
#' @export
llama_generate_report <- function(fit, llama_conn, report_type = "clinical") {
  if (is.null(llama_conn)) {
    stop("Llama connection required")
  }

  report_types <- list(
    clinical = "Create a comprehensive clinical report for healthcare providers",
    regulatory = "Create a regulatory submission document following ICH guidelines",
    hta = "Create a health technology assessment report for reimbursement decision",
    academic = "Create an academic manuscript following PRISMA-NMA guidelines"
  )

  system_prompt <- report_types[[report_type]]
  if (is.null(system_prompt)) {
    stop("Invalid report_type. Choose: clinical, regulatory, hta, or academic")
  }

  # Gather comprehensive results
  summary_stats <- summarize_treatments(fit)
  ranks <- compute_ranks(fit)
  diag <- surrogacy_diagnostics(fit)

  data_summary <- sprintf(
    "Network Structure:\n" %+%
    "- Treatments: %d (%s)\n" %+%
    "- Studies: %d\n" %+%
    "- Comparisons: %d\n\n" %+%
    "Results:\n%s\n\n" %+%
    "Surrogacy Parameters:\n" %+%
    "- Alpha: %.3f\n" %+%
    "- Beta: %.3f\n" %+%
    "- STE: %.3f\n\n" %+%
    "Rankings (SUCRA): %s",
    fit$net$K,
    paste(fit$net$trt_levels, collapse = ", "),
    fit$net$J,
    nrow(fit$net$data),
    paste(capture.output(print(summary_stats)), collapse = "\n"),
    diag$alpha["mean"],
    diag$beta["mean"],
    diag$STE$summary["mean"],
    paste(names(sort(ranks$sucra, decreasing = TRUE)), collapse = " > ")
  )

  prompt <- sprintf("%s\n\nData:\n%s", system_prompt, data_summary)

  result <- llama_conn$generate(prompt, system = system_prompt,
                                temperature = 0.5, max_tokens = 4000)

  list(
    report = result$response,
    report_type = report_type,
    timestamp = Sys.time()
  )
}

#' AI-powered inconsistency explanation
#' @export
llama_explain_inconsistency <- function(fit, inconsistency_results, llama_conn) {
  if (is.null(llama_conn)) {
    stop("Llama connection required")
  }

  system_prompt <- "You are an expert in network meta-analysis inconsistency. Explain potential sources of inconsistency and recommend appropriate sensitivity analyses."

  incons_summary <- sprintf(
    "Inconsistency Analysis Results:\n" %+%
    "Chi-squared statistic: %.2f\n" %+%
    "Degrees of freedom: %d\n" %+%
    "P-value: %.4f",
    inconsistency_results$stat,
    inconsistency_results$df,
    inconsistency_results$p
  )

  prompt <- sprintf("%s\n\nExplain:\n1. What this means clinically\n2. Potential sources\n3. How to address it\n4. Impact on conclusions", incons_summary)

  result <- llama_conn$generate(prompt, system = system_prompt, temperature = 0.6)

  list(
    explanation = result$response,
    inconsistency_results = inconsistency_results,
    timestamp = Sys.time()
  )
}

#' AI-powered surrogate validation
#' @export
llama_validate_surrogate <- function(fit, llama_conn, clinical_context = NULL) {
  if (is.null(llama_conn)) {
    stop("Llama connection required")
  }

  diag <- surrogacy_diagnostics(fit)

  system_prompt <- "You are an expert in surrogate endpoint validation. Assess the strength of surrogacy relationships using statistical and clinical criteria."

  surrogate_summary <- sprintf(
    "Surrogacy Analysis:\n" %+%
    "Alpha: %.3f [%.3f, %.3f]\n" %+%
    "Beta: %.3f [%.3f, %.3f]\n" %+%
    "STE: %.3f [%.3f, %.3f]\n" %+%
    "R-squared: %.3f",
    diag$alpha["mean"], diag$alpha["q025"], diag$alpha["q975"],
    diag$beta["mean"], diag$beta["q025"], diag$beta["q975"],
    diag$STE$summary["mean"], diag$STE$summary["q025"], diag$STE$summary["q975"],
    diag$beta["mean"]^2
  )

  if (!is.null(clinical_context)) {
    surrogate_summary <- paste0(surrogate_summary, "\n\nClinical Context: ", clinical_context)
  }

  prompt <- sprintf("%s\n\nProvide validation assessment:\n1. Strength of surrogacy (Prentice criteria)\n2. Clinical plausibility\n3. Regulatory acceptability\n4. Recommendations", surrogate_summary)

  result <- llama_conn$generate(prompt, system = system_prompt,
                                temperature = 0.5, max_tokens = 2500)

  list(
    validation = result$response,
    diagnostics = diag,
    timestamp = Sys.time()
  )
}

#' AI-powered literature review assistant
#' @export
llama_review_literature <- function(abstracts, llama_conn) {
  if (is.null(llama_conn)) {
    stop("Llama connection required")
  }

  system_prompt <- "You are an expert systematic reviewer. Screen abstracts for inclusion in a network meta-analysis, extract key data, and assess relevance."

  results <- list()

  for (i in seq_along(abstracts)) {
    prompt <- sprintf(
      "Screen this abstract for a network meta-analysis:\n\n%s\n\n" %+%
      "Provide:\n" %+%
      "1. Include/Exclude decision with justification\n" %+%
      "2. Key data elements (if applicable)\n" %+%
      "3. Quality concerns",
      abstracts[i]
    )

    result <- llama_conn$generate(prompt, system = system_prompt, temperature = 0.3)

    results[[i]] <- list(
      abstract_id = i,
      screening_result = result$response
    )

    # Rate limiting
    Sys.sleep(0.5)
  }

  list(
    screening_results = results,
    n_abstracts = length(abstracts),
    timestamp = Sys.time()
  )
}

#' AI-powered sensitivity analysis suggestions
#' @export
llama_suggest_sensitivity_analyses <- function(fit, llama_conn) {
  if (is.null(llama_conn)) {
    stop("Llama connection required")
  }

  system_prompt <- "You are an expert in network meta-analysis methodology. Recommend appropriate sensitivity analyses based on data characteristics and potential biases."

  data_characteristics <- sprintf(
    "Network Characteristics:\n" %+%
    "- Treatments: %d\n" %+%
    "- Studies: %d\n" %+%
    "- Missing outcome data: %.1f%%\n" %+%
    "- Multi-arm trials: present\n" %+%
    "- Heterogeneity: moderate\n" %+%
    "- Star network topology: %s",
    fit$net$K,
    fit$net$J,
    sum(is.na(fit$net$T_eff)) / length(fit$net$T_eff) * 100,
    "yes"  # simplified
  )

  prompt <- sprintf("%s\n\nRecommend specific sensitivity analyses addressing:\n1. Structural assumptions\n2. Statistical model choices\n3. Data quality concerns\n4. Prior specifications (if Bayesian)", data_characteristics)

  result <- llama_conn$generate(prompt, system = system_prompt,
                                temperature = 0.6, max_tokens = 2500)

  list(
    recommendations = result$response,
    timestamp = Sys.time()
  )
}

# ============================================================================
# BATCH PROCESSING WITH LLAMA
# ============================================================================

#' Process multiple analyses with AI assistance
#' @export
llama_batch_analysis <- function(fits, llama_conn, analyses = c("interpret", "validate")) {
  if (is.null(llama_conn)) {
    stop("Llama connection required")
  }

  results <- list()

  for (i in seq_along(fits)) {
    fit <- fits[[i]]
    fit_results <- list(fit_id = i)

    if ("interpret" %in% analyses) {
      fit_results$interpretation <- llama_interpret_results(fit, llama_conn)
      Sys.sleep(1)
    }

    if ("validate" %in% analyses) {
      fit_results$validation <- llama_validate_surrogate(fit, llama_conn)
      Sys.sleep(1)
    }

    results[[i]] <- fit_results
  }

  list(
    results = results,
    n_analyses = length(fits),
    timestamp = Sys.time()
  )
}

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

#' Check Ollama installation and model availability
#' @export
check_llama_setup <- function() {
  message("\n=== Llama 3 Setup Check ===\n")

  # Check if httr is installed
  if (!requireNamespace("httr", quietly = TRUE)) {
    message("✗ httr package not installed")
    message("  Install with: install.packages('httr')")
    return(invisible(FALSE))
  }
  message("✓ httr package installed")

  # Check Ollama service
  conn <- OllamaConnection$new()
  if (!conn$is_available()) {
    message("✗ Ollama service not available")
    message("  1. Install: https://ollama.ai")
    message("  2. Start: ollama serve")
    return(invisible(FALSE))
  }
  message("✓ Ollama service running")

  # Try to list models
  tryCatch({
    response <- httr::GET(paste0(conn$base_url, "/api/tags"))
    models <- jsonlite::fromJSON(httr::content(response, "text", encoding = "UTF-8"))

    if ("models" %in% names(models) && nrow(models$models) > 0) {
      message(sprintf("✓ %d model(s) available:", nrow(models$models)))
      for (i in seq_len(nrow(models$models))) {
        message(sprintf("  - %s", models$models$name[i]))
      }

      if ("llama3" %in% models$models$name || any(grepl("llama3", models$models$name))) {
        message("\n✓ Llama 3 is ready to use!")
        return(invisible(TRUE))
      } else {
        message("\n✗ Llama 3 not found")
        message("  Install with: ollama pull llama3")
        return(invisible(FALSE))
      }
    } else {
      message("✗ No models found")
      message("  Install Llama 3: ollama pull llama3")
      return(invisible(FALSE))
    }
  }, error = function(e) {
    message("✗ Error checking models: ", e$message)
    return(invisible(FALSE))
  })
}

#' Quick test of Llama connection
#' @export
test_llama_connection <- function(llama_conn = NULL) {
  if (is.null(llama_conn)) {
    llama_conn <- init_llama()
    if (is.null(llama_conn)) {
      return(invisible(FALSE))
    }
  }

  message("Testing Llama 3 connection...")

  result <- llama_conn$generate(
    "Respond with 'OK' if you can receive this message.",
    temperature = 0.1,
    max_tokens = 10
  )

  if (!is.null(result$response)) {
    message("✓ Llama 3 responded successfully!")
    message(sprintf("Response: %s", result$response))
    return(invisible(TRUE))
  } else {
    message("✗ No response from Llama 3")
    return(invisible(FALSE))
  }
}
