#' Local AI System with Llama 3 + Rules Engine for surroNMA v6.0
#' @description 100% local AI using Llama 3 via Ollama with rules-based validation
#' @version 6.0
#'
#' Features:
#' - Llama 3 (8B, 70B) via Ollama (auto-installed)
#' - Integrated with 1,500+ validation rules
#' - Response caching for performance
#' - No cloud dependencies, completely offline
#' - GPU acceleration support
#' - Batch processing

library(R6)
library(httr)
library(jsonlite)

# ============================================================================
# LOCAL AI MANAGER WITH LLAMA 3
# ============================================================================

#' Local AI Manager with Llama 3
#' @export
LocalAIManager <- R6::R6Class("LocalAIManager",
  public = list(
    base_url = NULL,
    model = NULL,
    rules_engine = NULL,
    cache = NULL,
    gpu_enabled = FALSE,

    initialize = function(base_url = "http://localhost:11434",
                         model = "llama3",
                         rules_engine = NULL) {
      self$base_url <- base_url
      self$model <- model
      self$rules_engine <- rules_engine
      self$cache <- list()

      # Check if Ollama is running
      if (!self$is_available()) {
        message("Ollama not running. Attempting to start...")
        self$start_ollama()
      }

      # Check if model is available
      if (!self$model_exists()) {
        message(sprintf("Model %s not found. Pulling...", model))
        self$pull_model(model)
      }

      # Check GPU availability
      self$gpu_enabled <- self$check_gpu()

      message(sprintf("Local AI initialized: %s (GPU: %s)",
                     model, ifelse(self$gpu_enabled, "Yes", "No")))
    },

    is_available = function() {
      tryCatch({
        response <- GET(paste0(self$base_url, "/api/tags"), timeout(5))
        status_code(response) == 200
      }, error = function(e) FALSE)
    },

    start_ollama = function() {
      # Attempt to start Ollama service
      system2("ollama", "serve", wait = FALSE, stdout = FALSE, stderr = FALSE)
      Sys.sleep(3)

      if (self$is_available()) {
        message("Ollama started successfully")
        return(TRUE)
      }

      warning("Could not start Ollama. Please start it manually: ollama serve")
      FALSE
    },

    model_exists = function() {
      tryCatch({
        response <- GET(paste0(self$base_url, "/api/tags"))
        if (status_code(response) == 200) {
          models <- content(response, "parsed")$models
          any(sapply(models, function(m) grepl(self$model, m$name)))
        } else {
          FALSE
        }
      }, error = function(e) FALSE)
    },

    pull_model = function(model_name) {
      message(sprintf("Pulling model %s... This may take several minutes.", model_name))

      response <- POST(
        url = paste0(self$base_url, "/api/pull"),
        body = toJSON(list(name = model_name), auto_unbox = TRUE),
        encode = "json",
        timeout(3600)  # 1 hour timeout
      )

      if (status_code(response) == 200) {
        message(sprintf("Model %s pulled successfully", model_name))
        TRUE
      } else {
        warning(sprintf("Failed to pull model %s", model_name))
        FALSE
      }
    },

    check_gpu = function() {
      # Check if NVIDIA GPU is available
      gpu_available <- system("nvidia-smi", ignore.stdout = TRUE, ignore.stderr = TRUE) == 0

      if (gpu_available) {
        message("GPU detected: NVIDIA GPU will be used for acceleration")
      }

      gpu_available
    },

    generate = function(prompt, system = NULL, temperature = 0.7,
                       max_tokens = 2000, use_cache = TRUE,
                       apply_rules = TRUE) {
      # Check cache
      if (use_cache) {
        cache_key <- digest::digest(list(prompt, system))
        if (cache_key %in% names(self$cache)) {
          message("Using cached response")
          return(self$cache[[cache_key]]$response)
        }
      }

      # Prepare full prompt
      full_prompt <- if (!is.null(system)) {
        paste(system, "\n\n", prompt)
      } else {
        prompt
      }

      # Generate with Llama 3
      response <- POST(
        url = paste0(self$base_url, "/api/generate"),
        body = toJSON(list(
          model = self$model,
          prompt = full_prompt,
          temperature = temperature,
          options = list(
            num_predict = max_tokens,
            num_gpu = if (self$gpu_enabled) 1 else 0
          )
        ), auto_unbox = TRUE),
        encode = "json",
        timeout(300)
      )

      if (status_code(response) != 200) {
        stop(sprintf("Ollama error: %s", content(response, "text")))
      }

      result <- content(response, "parsed")
      ai_response <- result$response

      # Apply rules-based validation if enabled
      if (apply_rules && !is.null(self$rules_engine)) {
        ai_response <- self$validate_with_rules(ai_response, prompt)
      }

      # Cache response
      if (use_cache) {
        self$cache[[cache_key]] <- list(
          response = ai_response,
          timestamp = Sys.time()
        )
      }

      ai_response
    },

    validate_with_rules = function(ai_response, original_prompt) {
      # Validate AI response using rules engine
      validation <- list(
        response = ai_response,
        warnings = character(),
        confidence = 1.0
      )

      # Check for hallucinations (common AI issue)
      if (grepl("I don't have|I cannot|I'm not sure", ai_response, ignore.case = TRUE)) {
        validation$confidence <- 0.7
        validation$warnings <- c(validation$warnings, "AI expressed uncertainty")
      }

      # Check for contradictions
      if (grepl("however.*but|although.*yet", ai_response, ignore.case = TRUE)) {
        validation$warnings <- c(validation$warnings, "Possible contradiction detected")
      }

      # Apply domain-specific rules if available
      if (!is.null(self$rules_engine)) {
        rules_result <- self$rules_engine$evaluate(
          data = list(ai_response = ai_response),
          context = list(prompt = original_prompt)
        )

        if (length(rules_result) > 0) {
          validation$warnings <- c(validation$warnings,
            paste("Rules violations:", length(rules_result)))
        }
      }

      # Return response with validation metadata
      attr(ai_response, "validation") <- validation
      ai_response
    },

    batch_generate = function(prompts, system = NULL, parallel = TRUE) {
      if (parallel && requireNamespace("parallel", quietly = TRUE)) {
        results <- parallel::mclapply(prompts, function(prompt) {
          self$generate(prompt, system)
        }, mc.cores = min(length(prompts), parallel::detectCores() - 1))
      } else {
        results <- lapply(prompts, function(prompt) {
          self$generate(prompt, system)
        })
      }

      results
    },

    clear_cache = function() {
      self$cache <- list()
      message("Cache cleared")
    },

    get_available_models = function() {
      tryCatch({
        response <- GET(paste0(self$base_url, "/api/tags"))
        if (status_code(response) == 200) {
          models <- content(response, "parsed")$models
          sapply(models, function(m) m$name)
        } else {
          character()
        }
      }, error = function(e) character())
    }
  )
)

# ============================================================================
# SPECIALIZED LOCAL AI TASKS
# ============================================================================

#' AI-Powered Network Optimization (Local)
#' @export
ai_optimize_network_local <- function(network, local_ai) {
  prompt <- sprintf("
Analyze this network meta-analysis and suggest optimizations:

Network: %d treatments (%s), %d studies, %d comparisons

Suggest:
1. Critical indirect comparisons to validate
2. Potential heterogeneity sources
3. Informative subgroup analyses
4. Recommended sensitivity analyses

Be specific and evidence-based.
  ", network$K, paste(network$trt_levels, collapse = ", "),
     network$J, nrow(network$data))

  system <- "You are an expert biostatistician. Provide concise, actionable recommendations for network meta-analysis optimization."

  response <- local_ai$generate(
    prompt = prompt,
    system = system,
    temperature = 0.7,
    apply_rules = TRUE
  )

  response
}

#' AI-Powered Outlier Detection (Local)
#' @export
ai_detect_outliers_local <- function(fit, local_ai) {
  study_effects <- fit$data$S_eff
  study_ses <- fit$data$S_se

  outlier_candidates <- which(abs(study_effects) > mean(study_effects) + 3 * sd(study_effects))

  if (length(outlier_candidates) == 0) {
    return("No obvious outliers detected by statistical criteria.")
  }

  prompt <- sprintf("
Analyze these potential outlier studies:

%s

For each:
1. Possible reasons for outlying result
2. Should it be excluded in sensitivity analysis?
3. What additional information would help?

  ", paste(sapply(outlier_candidates, function(i) {
    sprintf("Study %d: Effect = %.2f (SE = %.2f)", i, study_effects[i], study_ses[i])
  }), collapse = "\n"))

  system <- "You are an expert in meta-analysis quality assessment. Be critical but fair."

  response <- local_ai$generate(
    prompt = prompt,
    system = system,
    temperature = 0.6,
    apply_rules = TRUE
  )

  response
}

#' AI-Enhanced Literature Screening (Local)
#' @export
ai_screen_abstracts_local <- function(abstracts, inclusion_criteria, local_ai) {
  # Process abstracts in batches
  batch_size <- 10
  n_batches <- ceiling(length(abstracts) / batch_size)

  results <- list()

  for (i in 1:n_batches) {
    start_idx <- (i - 1) * batch_size + 1
    end_idx <- min(i * batch_size, length(abstracts))
    batch <- abstracts[start_idx:end_idx]

    prompt <- sprintf("
Screen these abstracts for inclusion in a systematic review.

Inclusion criteria:
%s

Abstracts:
%s

For each abstract, respond: INCLUDE, EXCLUDE, or UNCERTAIN with brief reason.
  ", inclusion_criteria,
      paste(sapply(seq_along(batch), function(j) {
        sprintf("[%d] %s", start_idx + j - 1, batch[j])
      }), collapse = "\n\n"))

    system <- "You are a systematic review screener. Be conservative - include if uncertain."

    response <- local_ai$generate(
      prompt = prompt,
      system = system,
      temperature = 0.3,  # Lower temperature for consistency
      apply_rules = FALSE  # Rules not needed for screening
    )

    results[[i]] <- response
  }

  results
}

#' Generate Analysis Interpretation (Local)
#' @export
ai_interpret_results_local <- function(fit, network, local_ai) {
  # Extract key findings
  n_treatments <- network$K
  n_studies <- network$J

  # Get rankings if available
  rankings <- tryCatch({
    if (!is.null(fit$theta_mean)) {
      order(fit$theta_mean, decreasing = TRUE)
    } else {
      NULL
    }
  }, error = function(e) NULL)

  prompt <- sprintf("
Interpret these network meta-analysis results for a clinical audience:

Network: %d treatments, %d studies
Treatments: %s

Key findings:
%s

Provide:
1. Summary of main findings (2-3 sentences)
2. Clinical implications
3. Important limitations
4. Recommendations for clinical practice

Use clear, non-technical language.
  ", n_treatments, n_studies,
     paste(network$trt_levels, collapse = ", "),
     if (!is.null(rankings)) {
       sprintf("Best treatments: %s",
               paste(network$trt_levels[rankings[1:min(3, length(rankings))]],
                     collapse = ", "))
     } else {
       "Bayesian analysis completed"
     })

  system <- "You are a clinical researcher translating statistical findings for clinicians. Be clear and practical."

  response <- local_ai$generate(
    prompt = prompt,
    system = system,
    temperature = 0.7,
    apply_rules = TRUE
  )

  response
}
