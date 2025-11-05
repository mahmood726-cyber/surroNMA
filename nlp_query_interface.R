#' Natural Language Query Interface for surroNMA v7.0
#' @description Ask questions in plain English and get answers from your NMA
#' @version 7.0
#'
#' Features:
#' - Natural language understanding
#' - Query parsing and intent recognition
#' - Automatic analysis execution
#' - Conversational follow-up questions
#' - Multi-turn dialogue support
#' - Context-aware responses

library(R6)

# ============================================================================
# NLP QUERY ENGINE
# ============================================================================

#' Natural Language Query Engine
#' @export
NLPQueryEngine <- R6::R6Class("NLPQueryEngine",
  public = list(
    local_ai = NULL,
    context = NULL,
    conversation_history = NULL,
    network = NULL,
    fit = NULL,

    initialize = function(local_ai = NULL, network = NULL, fit = NULL) {
      if (is.null(local_ai)) {
        # Initialize local AI if not provided
        if (requireNamespace("httr", quietly = TRUE)) {
          self$local_ai <- LocalAIManager$new(model = "llama3")
        }
      } else {
        self$local_ai <- local_ai
      }

      self$network <- network
      self$fit <- fit
      self$context <- list()
      self$conversation_history <- list()

      message("NLP Query Engine initialized")
    },

    # Main query processing function
    query = function(question, auto_execute = TRUE) {
      message(sprintf("\nUser: %s", question))

      # Add to conversation history
      self$conversation_history <- append(
        self$conversation_history,
        list(list(role = "user", content = question, timestamp = Sys.time()))
      )

      # Parse query intent
      intent <- self$parse_intent(question)

      # Generate response based on intent
      response <- switch(intent$type,
        "analysis" = self$handle_analysis_query(question, intent, auto_execute),
        "visualization" = self$handle_visualization_query(question, intent, auto_execute),
        "comparison" = self$handle_comparison_query(question, intent),
        "interpretation" = self$handle_interpretation_query(question, intent),
        "methodology" = self$handle_methodology_query(question, intent),
        "data" = self$handle_data_query(question, intent),
        "help" = self$handle_help_query(question),
        self$handle_general_query(question)
      )

      # Add response to history
      self$conversation_history <- append(
        self$conversation_history,
        list(list(role = "assistant", content = response, timestamp = Sys.time()))
      )

      message(sprintf("\nAssistant: %s", response$text))

      response
    },

    # Parse user intent from natural language
    parse_intent = function(question) {
      q_lower <- tolower(question)

      intent <- list(
        type = "general",
        action = NULL,
        entities = list(),
        confidence = 0.5
      )

      # Analysis queries
      if (grepl("run|perform|execute|conduct|do.*analysis", q_lower)) {
        intent$type <- "analysis"
        intent$action <- if (grepl("bayesian", q_lower)) "bayesian" else "frequentist"
        intent$confidence <- 0.9
      }

      # Visualization queries
      else if (grepl("plot|visualize|show|display|graph|chart", q_lower)) {
        intent$type <- "visualization"

        if (grepl("forest", q_lower)) intent$action <- "forest"
        else if (grepl("network", q_lower)) intent$action <- "network"
        else if (grepl("funnel", q_lower)) intent$action <- "funnel"
        else if (grepl("rankogram", q_lower)) intent$action <- "rankogram"
        else intent$action <- "auto"

        intent$confidence <- 0.85
      }

      # Comparison queries
      else if (grepl("compare|difference|better|versus|vs", q_lower)) {
        intent$type <- "comparison"
        intent$entities$treatments <- private$extract_treatment_names(question)
        intent$confidence <- 0.8
      }

      # Interpretation queries
      else if (grepl("what does|explain|interpret|mean|significance", q_lower)) {
        intent$type <- "interpretation"
        intent$confidence <- 0.75
      }

      # Methodology queries
      else if (grepl("how|method|approach|technique|algorithm", q_lower)) {
        intent$type <- "methodology"
        intent$confidence <- 0.7
      }

      # Data queries
      else if (grepl("data|studies|sample|observations", q_lower)) {
        intent$type <- "data"
        intent$confidence <- 0.8
      }

      # Help queries
      else if (grepl("help|guidance|tutorial|example", q_lower)) {
        intent$type <- "help"
        intent$confidence <- 0.9
      }

      intent
    },

    # Handle analysis queries
    handle_analysis_query = function(question, intent, auto_execute) {
      if (is.null(self$network)) {
        return(list(
          text = "I don't have any data loaded yet. Please provide network data first.",
          action = NULL,
          code = NULL
        ))
      }

      # Determine analysis type
      engine <- if (!is.null(intent$action)) intent$action else "bayes"

      # Generate analysis code
      code <- sprintf("fit <- surro_nma_intelligent(network, engine = '%s')", engine)

      if (auto_execute) {
        message(sprintf("Executing: %s", code))

        tryCatch({
          fit <- surro_nma_intelligent(self$network, engine = engine)
          self$fit <- fit

          # Generate summary
          summary_text <- private$generate_analysis_summary(fit)

          list(
            text = sprintf("Analysis completed successfully using %s approach.\n\n%s",
                          engine, summary_text),
            action = "analysis_complete",
            result = fit,
            code = code
          )
        }, error = function(e) {
          list(
            text = sprintf("Analysis failed: %s", e$message),
            action = "error",
            error = e$message,
            code = code
          )
        })
      } else {
        list(
          text = sprintf("To run the analysis, execute:\n```r\n%s\n```", code),
          action = "analysis_suggested",
          code = code
        )
      }
    },

    # Handle visualization queries
    handle_visualization_query = function(question, intent, auto_execute) {
      if (is.null(self$network) && is.null(self$fit)) {
        return(list(
          text = "I need network data or analysis results to create visualizations.",
          action = NULL
        ))
      }

      viz_type <- intent$action

      # Generate visualization code
      code <- switch(viz_type,
        "forest" = "plot_forest(fit)",
        "network" = "plot_network(network)",
        "funnel" = "plot_funnel(fit)",
        "rankogram" = "plot_rankogram(fit)",
        "auto" = "plot_network(network); plot_forest(fit)"
      )

      if (auto_execute) {
        message(sprintf("Creating visualization: %s", viz_type))

        tryCatch({
          if (viz_type == "network" || viz_type == "auto") {
            plot_network(self$network)
          }
          if (viz_type == "forest" || viz_type == "auto") {
            if (!is.null(self$fit)) plot_forest(self$fit)
          }
          if (viz_type == "funnel" && !is.null(self$fit)) {
            plot_funnel(self$fit)
          }
          if (viz_type == "rankogram" && !is.null(self$fit)) {
            plot_rankogram(self$fit)
          }

          list(
            text = sprintf("%s plot created successfully.", viz_type),
            action = "visualization_complete",
            code = code
          )
        }, error = function(e) {
          list(
            text = sprintf("Visualization failed: %s", e$message),
            action = "error",
            error = e$message
          )
        })
      } else {
        list(
          text = sprintf("To create the visualization, execute:\n```r\n%s\n```", code),
          action = "visualization_suggested",
          code = code
        )
      }
    },

    # Handle comparison queries
    handle_comparison_query = function(question, intent) {
      if (is.null(self$fit)) {
        return(list(
          text = "I need analysis results to compare treatments. Please run the analysis first.",
          action = NULL
        ))
      }

      treatments <- intent$entities$treatments

      if (length(treatments) < 2) {
        # Ask AI to interpret which treatments to compare
        if (!is.null(self$local_ai)) {
          prompt <- sprintf(
            "Based on this network meta-analysis question: '%s'\n\nAvailable treatments: %s\n\nWhich treatments should be compared?",
            question,
            paste(self$network$trt_levels, collapse = ", ")
          )

          ai_response <- self$local_ai$generate(
            prompt = prompt,
            temperature = 0.3
          )

          # Extract treatment names from AI response
          treatments <- private$extract_treatment_names(ai_response)
        }
      }

      if (length(treatments) >= 2) {
        # Perform comparison
        comparison <- private$compare_treatments(treatments[1], treatments[2])

        list(
          text = comparison$summary,
          action = "comparison_complete",
          result = comparison
        )
      } else {
        list(
          text = "Please specify which treatments you'd like to compare.",
          action = "clarification_needed"
        )
      }
    },

    # Handle interpretation queries
    handle_interpretation_query = function(question, intent) {
      if (is.null(self$fit)) {
        return(list(
          text = "I need analysis results to provide interpretation. Please run the analysis first.",
          action = NULL
        ))
      }

      # Use AI to generate interpretation
      if (!is.null(self$local_ai)) {
        prompt <- sprintf(
          "User question: %s\n\nNetwork meta-analysis results:\n- %d treatments: %s\n- %d studies\n- %d comparisons\n\nProvide a clear interpretation for a clinical audience.",
          question,
          self$network$K,
          paste(self$network$trt_levels, collapse = ", "),
          self$network$J,
          nrow(self$network$data)
        )

        interpretation <- self$local_ai$generate(
          prompt = prompt,
          system = "You are a biostatistician explaining results to clinicians. Be clear and practical.",
          temperature = 0.7
        )

        list(
          text = interpretation,
          action = "interpretation_complete"
        )
      } else {
        list(
          text = "AI interpretation not available. Local AI not configured.",
          action = "error"
        )
      }
    },

    # Handle methodology queries
    handle_methodology_query = function(question, intent) {
      # Use AI to explain methodology
      if (!is.null(self$local_ai)) {
        prompt <- sprintf(
          "User question about network meta-analysis methodology: %s\n\nProvide a clear, accurate explanation.",
          question
        )

        explanation <- self$local_ai$generate(
          prompt = prompt,
          system = "You are a statistical methodologist. Explain concepts clearly with examples.",
          temperature = 0.5
        )

        list(
          text = explanation,
          action = "methodology_explained"
        )
      } else {
        list(
          text = "AI explanation not available. Please refer to the documentation.",
          action = "error"
        )
      }
    },

    # Handle data queries
    handle_data_query = function(question, intent) {
      if (is.null(self$network)) {
        return(list(
          text = "No data loaded yet.",
          action = NULL
        ))
      }

      summary <- sprintf(
        "Network data summary:\n- %d treatments: %s\n- %d studies\n- %d comparisons\n- Mean effect: %.3f (SD: %.3f)",
        self$network$K,
        paste(self$network$trt_levels, collapse = ", "),
        self$network$J,
        nrow(self$network$data),
        mean(self$network$data$S_eff, na.rm = TRUE),
        sd(self$network$data$S_eff, na.rm = TRUE)
      )

      list(
        text = summary,
        action = "data_summary",
        data = list(
          K = self$network$K,
          J = self$network$J,
          treatments = self$network$trt_levels
        )
      )
    },

    # Handle help queries
    handle_help_query = function(question) {
      help_text <- "
I can help you with:

1. **Running analyses**: 'Run a Bayesian analysis', 'Perform frequentist NMA'
2. **Creating visualizations**: 'Show network plot', 'Create forest plot'
3. **Comparing treatments**: 'Compare treatment A vs B', 'Which is better?'
4. **Interpreting results**: 'What do these results mean?', 'Explain the findings'
5. **Methodology questions**: 'How does NMA work?', 'What is inconsistency?'
6. **Data queries**: 'Show me the data', 'How many studies?'

Just ask your question in plain English!
      "

      list(
        text = help_text,
        action = "help_provided"
      )
    },

    # Handle general queries
    handle_general_query = function(question) {
      # Use AI for general queries
      if (!is.null(self$local_ai)) {
        context_info <- ""
        if (!is.null(self$network)) {
          context_info <- sprintf(
            "\n\nCurrent context: Network with %d treatments and %d studies.",
            self$network$K, self$network$J
          )
        }

        prompt <- sprintf(
          "User question: %s%s\n\nProvide a helpful response.",
          question, context_info
        )

        response <- self$local_ai$generate(
          prompt = prompt,
          system = "You are a helpful assistant for network meta-analysis.",
          temperature = 0.7
        )

        list(
          text = response,
          action = "general_response"
        )
      } else {
        list(
          text = "I'm not sure how to help with that. Try asking about analysis, visualization, or interpretation.",
          action = "unclear"
        )
      }
    },

    # Get conversation history
    get_history = function(n = NULL) {
      if (is.null(n)) {
        self$conversation_history
      } else {
        tail(self$conversation_history, n)
      }
    },

    # Clear conversation history
    clear_history = function() {
      self$conversation_history <- list()
      message("Conversation history cleared")
    },

    # Update context
    update_context = function(network = NULL, fit = NULL) {
      if (!is.null(network)) self$network <- network
      if (!is.null(fit)) self$fit <- fit
    }
  )
)

# Private helper functions
private <- new.env()

private$extract_treatment_names <- function(text) {
  # Simple pattern matching for treatment names
  # In production, use NER (Named Entity Recognition)

  # Common patterns
  patterns <- c(
    "treatment ([A-Z][a-z]+)",
    "drug ([A-Z][a-z]+)",
    "([A-Z][a-z]+) (vs|versus) ([A-Z][a-z]+)"
  )

  treatments <- character()

  for (pattern in patterns) {
    matches <- gregexpr(pattern, text, perl = TRUE)
    if (length(matches[[1]]) > 0 && matches[[1]][1] != -1) {
      treatments <- c(treatments, regmatches(text, matches)[[1]])
    }
  }

  unique(treatments)
}

private$generate_analysis_summary <- function(fit) {
  sprintf(
    "Key findings:\n- %d treatments analyzed\n- Convergence: %s\n- Method: %s",
    fit$K,
    ifelse(!is.null(fit$rhat) && all(fit$rhat < 1.1), "Good", "Check required"),
    fit$engine
  )
}

private$compare_treatments <- function(trt1, trt2) {
  # Placeholder for treatment comparison logic
  list(
    summary = sprintf("Comparison between %s and %s", trt1, trt2),
    treatments = c(trt1, trt2)
  )
}

# ============================================================================
# CONVENIENCE FUNCTIONS
# ============================================================================

#' Ask a question in natural language
#' @export
ask <- function(question, network = NULL, fit = NULL, auto_execute = TRUE) {
  # Create or get global NLP engine
  if (!exists(".nlp_engine", envir = .GlobalEnv)) {
    .GlobalEnv$.nlp_engine <- NLPQueryEngine$new(network = network, fit = fit)
  } else {
    # Update context if provided
    if (!is.null(network) || !is.null(fit)) {
      .GlobalEnv$.nlp_engine$update_context(network = network, fit = fit)
    }
  }

  .GlobalEnv$.nlp_engine$query(question, auto_execute = auto_execute)
}

#' Interactive chat session
#' @export
chat <- function(network = NULL, fit = NULL) {
  nlp_engine <- NLPQueryEngine$new(network = network, fit = fit)

  cat("surroNMA Chat Interface\n")
  cat("Type 'exit' to quit, 'help' for assistance\n\n")

  while (TRUE) {
    question <- readline("You: ")

    if (tolower(question) %in% c("exit", "quit", "q")) {
      cat("Goodbye!\n")
      break
    }

    if (nchar(question) == 0) next

    response <- nlp_engine$query(question, auto_execute = TRUE)
    cat("\n")
  }

  invisible(nlp_engine)
}

# ============================================================================
# EXAMPLE QUERIES
# ============================================================================

#' Example queries for demonstration
#' @export
nlp_examples <- function() {
  examples <- list(
    analysis = c(
      "Run a Bayesian analysis",
      "Perform a frequentist network meta-analysis",
      "Execute the analysis using MCMC"
    ),
    visualization = c(
      "Show me the network plot",
      "Create a forest plot",
      "Display a rankogram",
      "Generate all visualizations"
    ),
    comparison = c(
      "Compare treatment A versus treatment B",
      "Which treatment is better?",
      "What's the difference between drug X and drug Y?"
    ),
    interpretation = c(
      "What do these results mean?",
      "Explain the findings",
      "What is the clinical significance?",
      "Interpret the heterogeneity"
    ),
    methodology = c(
      "How does network meta-analysis work?",
      "What is inconsistency?",
      "Explain the Bayesian approach",
      "What are the assumptions?"
    ),
    data = c(
      "Show me the data summary",
      "How many studies are included?",
      "What treatments are in the network?",
      "What's the sample size?"
    )
  )

  cat("Example queries you can ask:\n\n")

  for (category in names(examples)) {
    cat(sprintf("%s:\n", toupper(category)))
    for (ex in examples[[category]]) {
      cat(sprintf("  - %s\n", ex))
    }
    cat("\n")
  }

  invisible(examples)
}
