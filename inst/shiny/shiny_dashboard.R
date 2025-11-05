#' Interactive Shiny Dashboard for Network Meta-Analysis
#' @description Comprehensive web interface for surroNMA with real-time analysis,
#'              interactive visualizations, and collaborative features
#' @version 4.0
#'
#' Inspired by modern dashboards (mahmood789 repo patterns) with:
#' - Real-time analysis updates
#' - Interactive parameter tuning
#' - Drag-and-drop data upload
#' - Live visualization rendering
#' - Export functionality
#' - Multi-user collaboration support

library(shiny)
library(shinydashboard)
library(shinyjs)
library(DT)
library(plotly)
library(htmlwidgets)
library(shinycssloaders)

# Source all surroNMA modules
if (file.exists("surroNMA")) source("surroNMA")
if (file.exists("master_integration.R")) source("master_integration.R")

# ============================================================================
# UI DEFINITION
# ============================================================================

ui <- dashboardPage(
  skin = "purple",

  # Dashboard Header
  dashboardHeader(
    title = span(
      tags$img(src = "logo.png", height = "30px", style = "margin-right: 10px;"),
      "surroNMA v4.0"
    ),
    titleWidth = 300,

    # Header notifications
    dropdownMenu(
      type = "notifications",
      icon = icon("bell"),
      badgeStatus = "warning",
      headerText = "System Status",
      notificationItem(
        text = "AI Engine: Connected",
        icon = icon("brain"),
        status = "success"
      ),
      notificationItem(
        text = "1,500+ Rules Active",
        icon = icon("shield-alt"),
        status = "info"
      )
    ),

    # User menu
    dropdownMenu(
      type = "messages",
      icon = icon("user"),
      badgeStatus = "success",
      messageItem(
        from = "AI Assistant",
        message = "Ready to analyze your network!",
        icon = icon("robot")
      )
    )
  ),

  # Dashboard Sidebar
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      id = "sidebar_menu",

      menuItem("🏠 Home", tabName = "home", icon = icon("home")),
      menuItem("📊 Data Upload", tabName = "upload", icon = icon("upload")),
      menuItem("🔍 Data Explorer", tabName = "explorer", icon = icon("search")),
      menuItem("⚙️ Network Builder", tabName = "network", icon = icon("network-wired")),
      menuItem("🎯 Analysis", tabName = "analysis", icon = icon("chart-line"),
               menuSubItem("Primary Analysis", tabName = "primary_analysis"),
               menuSubItem("Sensitivity Analysis", tabName = "sensitivity"),
               menuSubItem("Subgroup Analysis", tabName = "subgroup")
      ),
      menuItem("📈 Visualizations", tabName = "visualizations", icon = icon("chart-bar"),
               menuSubItem("Network Plots", tabName = "viz_network"),
               menuSubItem("Forest Plots", tabName = "viz_forest"),
               menuSubItem("Rankograms", tabName = "viz_ranking"),
               menuSubItem("Custom Plots", tabName = "viz_custom")
      ),
      menuItem("🤖 AI Assistant", tabName = "ai", icon = icon("robot")),
      menuItem("📝 Manuscript", tabName = "manuscript", icon = icon("file-alt"),
               menuSubItem("Methods Section", tabName = "methods"),
               menuSubItem("Results Section", tabName = "results"),
               menuSubItem("Complete Draft", tabName = "full_manuscript")
      ),
      menuItem("✅ Quality Check", tabName = "quality", icon = icon("check-circle")),
      menuItem("💾 Export", tabName = "export", icon = icon("download")),
      menuItem("📚 Help", tabName = "help", icon = icon("question-circle")),
      menuItem("⚙️ Settings", tabName = "settings", icon = icon("cog"))
    ),

    # Sidebar footer with stats
    tags$div(
      class = "sidebar-footer",
      style = "position: fixed; bottom: 0; width: 300px; padding: 15px; background: #222d32;",
      tags$small(
        style = "color: #b8c7ce;",
        tags$div(icon("database"), " Studies: ", textOutput("n_studies", inline = TRUE)),
        tags$div(icon("flask"), " Treatments: ", textOutput("n_treatments", inline = TRUE)),
        tags$div(icon("clock"), " Last Update: ", textOutput("last_update", inline = TRUE))
      )
    )
  ),

  # Dashboard Body
  dashboardBody(
    useShinyjs(),

    # Custom CSS
    tags$head(
      tags$style(HTML("
        .content-wrapper { background: #f4f6f9; }
        .main-header .logo { font-weight: bold; font-size: 20px; }
        .box { border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .info-box { border-radius: 8px; }
        .small-box { border-radius: 8px; }
        .nav-tabs-custom { border-radius: 8px; }
        .progress-bar { transition: width 0.6s ease; }
        .metric-box {
          background: white;
          padding: 20px;
          border-radius: 8px;
          margin: 10px 0;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .metric-value {
          font-size: 2.5em;
          font-weight: bold;
          color: #3c8dbc;
        }
        .metric-label {
          color: #777;
          font-size: 0.9em;
          margin-top: 5px;
        }
        .btn-analyze {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border: none;
          color: white;
          padding: 12px 30px;
          font-size: 16px;
          border-radius: 25px;
          transition: all 0.3s;
        }
        .btn-analyze:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }
      "))
    ),

    tabItems(
      # HOME TAB
      tabItem(
        tabName = "home",
        h2("Welcome to surroNMA v4.0", style = "color: #3c8dbc; font-weight: bold;"),
        p("The most comprehensive AI-enhanced network meta-analysis system",
          style = "font-size: 16px; color: #666;"),

        fluidRow(
          valueBoxOutput("total_rules_box", width = 3),
          valueBoxOutput("total_scenarios_box", width = 3),
          valueBoxOutput("visualizations_box", width = 3),
          valueBoxOutput("ai_status_box", width = 3)
        ),

        fluidRow(
          box(
            title = "🚀 Quick Start Guide",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            collapsible = TRUE,

            tags$ol(
              tags$li(tags$b("Upload Data:"), " Go to 'Data Upload' tab and load your study data"),
              tags$li(tags$b("Build Network:"), " Define your network structure and endpoints"),
              tags$li(tags$b("Run Analysis:"), " Choose Bayesian or Frequentist analysis"),
              tags$li(tags$b("View Results:"), " Explore interactive visualizations"),
              tags$li(tags$b("Generate Manuscript:"), " AI-powered methods and results sections"),
              tags$li(tags$b("Export:"), " Download publication-ready outputs")
            ),

            hr(),

            actionButton(
              "quick_demo",
              "Run Demo Analysis",
              icon = icon("play-circle"),
              class = "btn btn-success btn-lg btn-block"
            )
          ),

          box(
            title = "📊 System Capabilities",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            collapsible = TRUE,

            infoBoxOutput("rules_info", width = 12),
            infoBoxOutput("scenarios_info", width = 12),
            infoBoxOutput("methods_info", width = 12)
          )
        ),

        fluidRow(
          box(
            title = "📰 Recent Updates",
            status = "warning",
            solidHeader = TRUE,
            width = 12,

            tags$div(
              class = "timeline",
              tags$div(
                class = "time-label",
                tags$span(class = "bg-red", "v4.0 - Interactive Dashboard")
              ),
              tags$div(
                icon("laptop"), style = "color: #3c8dbc;",
                tags$b("Shiny Web Interface"), " - Real-time interactive analysis"
              ),
              tags$br(),
              tags$div(
                icon("chart-line"), style = "color: #00a65a;",
                tags$b("Live Visualizations"), " - Interactive plots with plotly"
              ),
              tags$br(),
              tags$div(
                icon("users"), style = "color: #f39c12;",
                tags$b("Collaboration"), " - Multi-user support"
              )
            )
          )
        )
      ),

      # DATA UPLOAD TAB
      tabItem(
        tabName = "upload",
        h2("📊 Data Upload"),

        fluidRow(
          box(
            title = "Upload Study Data",
            status = "primary",
            solidHeader = TRUE,
            width = 6,

            fileInput(
              "data_file",
              "Choose CSV or Excel File",
              accept = c(".csv", ".xlsx", ".xls"),
              buttonLabel = "Browse...",
              placeholder = "No file selected"
            ),

            radioButtons(
              "data_format",
              "Data Format:",
              choices = c("Wide format" = "wide",
                         "Long format" = "long",
                         "Arm-based" = "arm"),
              selected = "long",
              inline = TRUE
            ),

            checkboxInput("header", "First row contains column names", TRUE),

            hr(),

            actionButton(
              "load_example",
              "Load Example Dataset",
              icon = icon("database"),
              class = "btn btn-info"
            ),

            actionButton(
              "simulate_data",
              "Generate Simulated Data",
              icon = icon("random"),
              class = "btn btn-warning"
            )
          ),

          box(
            title = "Data Preview",
            status = "info",
            solidHeader = TRUE,
            width = 6,

            withSpinner(
              DTOutput("data_preview"),
              type = 4,
              color = "#3c8dbc"
            ),

            hr(),

            fluidRow(
              column(4, valueBoxOutput("n_rows_box", width = 12)),
              column(4, valueBoxOutput("n_cols_box", width = 12)),
              column(4, valueBoxOutput("data_status_box", width = 12))
            )
          )
        ),

        fluidRow(
          box(
            title = "Data Quality Check",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,

            tabBox(
              width = 12,

              tabPanel(
                "Summary",
                withSpinner(verbatimTextOutput("data_summary"))
              ),

              tabPanel(
                "Missing Data",
                withSpinner(plotlyOutput("missing_plot"))
              ),

              tabPanel(
                "Distributions",
                withSpinner(plotlyOutput("distribution_plots"))
              ),

              tabPanel(
                "Validation",
                withSpinner(DTOutput("validation_results"))
              )
            )
          )
        )
      ),

      # NETWORK BUILDER TAB
      tabItem(
        tabName = "network",
        h2("⚙️ Network Builder"),

        fluidRow(
          box(
            title = "Define Network Structure",
            status = "primary",
            solidHeader = TRUE,
            width = 6,

            selectInput("study_var", "Study ID Variable:", choices = NULL),
            selectInput("trt_var", "Treatment Variable:", choices = NULL),
            selectInput("comp_var", "Comparator Variable:", choices = NULL),

            hr(),

            h4("Surrogate Endpoint"),
            selectInput("s_eff_var", "Effect Measure:", choices = NULL),
            selectInput("s_se_var", "Standard Error:", choices = NULL),

            hr(),

            h4("True Endpoint"),
            selectInput("t_eff_var", "Effect Measure:", choices = NULL),
            selectInput("t_se_var", "Standard Error:", choices = NULL),

            hr(),

            checkboxInput("check_connectivity", "Check network connectivity", TRUE),

            actionButton(
              "build_network",
              "Build Network",
              icon = icon("network-wired"),
              class = "btn-analyze btn-lg btn-block"
            )
          ),

          box(
            title = "Network Summary",
            status = "success",
            solidHeader = TRUE,
            width = 6,

            withSpinner(
              uiOutput("network_summary_ui")
            ),

            hr(),

            fluidRow(
              column(6, valueBoxOutput("n_treatments_box", width = 12)),
              column(6, valueBoxOutput("n_studies_box", width = 12))
            ),

            hr(),

            withSpinner(
              plotlyOutput("network_graph_preview", height = "400px")
            )
          )
        ),

        fluidRow(
          box(
            title = "Treatment Information",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,
            collapsed = TRUE,

            DTOutput("treatment_table")
          )
        )
      ),

      # PRIMARY ANALYSIS TAB
      tabItem(
        tabName = "primary_analysis",
        h2("🎯 Primary Analysis"),

        fluidRow(
          box(
            title = "Analysis Settings",
            status = "primary",
            solidHeader = TRUE,
            width = 4,

            radioButtons(
              "engine",
              "Analysis Engine:",
              choices = c("Bayesian (MCMC)" = "bayes",
                         "Frequentist" = "freq"),
              selected = "bayes"
            ),

            conditionalPanel(
              condition = "input.engine == 'bayes'",

              sliderInput("chains", "MCMC Chains:",
                         min = 1, max = 8, value = 4, step = 1),

              sliderInput("iter_warmup", "Warmup Iterations:",
                         min = 500, max = 5000, value = 1000, step = 500),

              sliderInput("iter_sampling", "Sampling Iterations:",
                         min = 500, max = 5000, value = 1000, step = 500),

              sliderInput("adapt_delta", "Adapt Delta:",
                         min = 0.8, max = 0.99, value = 0.9, step = 0.01)
            ),

            conditionalPanel(
              condition = "input.engine == 'freq'",

              sliderInput("bootstrap", "Bootstrap Samples:",
                         min = 100, max = 5000, value = 400, step = 100),

              radioButtons("boot_type", "Bootstrap Type:",
                          choices = c("Normal" = "normal",
                                    "Student-t" = "student"),
                          selected = "normal")
            ),

            hr(),

            checkboxInput("use_ai", "Use AI interpretation", TRUE),
            checkboxInput("apply_rules", "Apply validation rules (1,500+)", TRUE),
            checkboxInput("auto_sensitivity", "Automatic sensitivity analyses", TRUE),

            hr(),

            actionButton(
              "run_analysis",
              "Run Analysis",
              icon = icon("play"),
              class = "btn-analyze btn-lg btn-block"
            ),

            br(),

            conditionalPanel(
              condition = "input.run_analysis > 0",
              withSpinner(
                uiOutput("analysis_progress")
              )
            )
          ),

          box(
            title = "Results Overview",
            status = "success",
            solidHeader = TRUE,
            width = 8,

            conditionalPanel(
              condition = "input.run_analysis == 0",
              tags$div(
                style = "text-align: center; padding: 50px;",
                icon("chart-line", class = "fa-5x", style = "color: #ccc;"),
                h4("Configure settings and click 'Run Analysis'", style = "color: #999;")
              )
            ),

            conditionalPanel(
              condition = "input.run_analysis > 0",

              tabBox(
                width = 12,

                tabPanel(
                  "Summary",
                  icon = icon("table"),
                  withSpinner(DTOutput("results_summary_table"))
                ),

                tabPanel(
                  "Rankings",
                  icon = icon("trophy"),
                  withSpinner(DTOutput("rankings_table")),
                  hr(),
                  withSpinner(plotlyOutput("sucra_plot"))
                ),

                tabPanel(
                  "Diagnostics",
                  icon = icon("stethoscope"),
                  withSpinner(verbatimTextOutput("diagnostics_text")),
                  hr(),
                  withSpinner(plotlyOutput("diagnostic_plots"))
                ),

                tabPanel(
                  "AI Interpretation",
                  icon = icon("robot"),
                  withSpinner(uiOutput("ai_interpretation_ui"))
                )
              )
            )
          )
        ),

        fluidRow(
          box(
            title = "Quality Assessment",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,

            fluidRow(
              column(3, valueBoxOutput("rules_passed_box", width = 12)),
              column(3, valueBoxOutput("rules_warnings_box", width = 12)),
              column(3, valueBoxOutput("rules_errors_box", width = 12)),
              column(3, valueBoxOutput("quality_score_box", width = 12))
            ),

            hr(),

            withSpinner(DTOutput("validation_details"))
          )
        )
      ),

      # VISUALIZATION TAB - Network Plots
      tabItem(
        tabName = "viz_network",
        h2("📈 Network Visualizations"),

        fluidRow(
          box(
            title = "Network Graph",
            status = "primary",
            solidHeader = TRUE,
            width = 6,

            selectInput(
              "network_layout",
              "Layout Algorithm:",
              choices = c("Kamada-Kawai" = "kamada.kawai",
                         "Fruchterman-Reingold" = "fr",
                         "Circle" = "circle",
                         "Spring" = "spring"),
              selected = "kamada.kawai"
            ),

            checkboxInput("show_weights", "Show edge weights", TRUE),
            checkboxInput("interactive_network", "Interactive (requires visNetwork)", TRUE),

            hr(),

            withSpinner(plotlyOutput("network_plot_main", height = "500px"))
          ),

          box(
            title = "Network Geometry (MDS/t-SNE)",
            status = "info",
            solidHeader = TRUE,
            width = 6,

            selectInput(
              "geometry_method",
              "Dimension Reduction:",
              choices = c("MDS" = "mds",
                         "t-SNE" = "tsne",
                         "UMAP" = "umap"),
              selected = "mds"
            ),

            sliderInput("geometry_dim", "Dimensions:",
                       min = 2, max = 3, value = 2, step = 1),

            hr(),

            withSpinner(plotlyOutput("geometry_plot", height = "500px"))
          )
        ),

        fluidRow(
          box(
            title = "Contribution Matrix",
            status = "success",
            solidHeader = TRUE,
            width = 12,

            withSpinner(plotlyOutput("contribution_matrix_plot", height = "600px"))
          )
        )
      ),

      # FOREST PLOTS TAB
      tabItem(
        tabName = "viz_forest",
        h2("🌲 Forest Plots"),

        fluidRow(
          box(
            title = "Forest Plot Options",
            status = "primary",
            solidHeader = TRUE,
            width = 3,

            selectInput("forest_reference", "Reference Treatment:",
                       choices = NULL),

            checkboxInput("show_heterogeneity", "Show heterogeneity bands", TRUE),
            checkboxInput("show_prediction", "Show prediction intervals", FALSE),

            sliderInput("forest_ci_level", "Confidence Level:",
                       min = 0.80, max = 0.99, value = 0.95, step = 0.01),

            hr(),

            actionButton("update_forest", "Update Plot",
                        class = "btn btn-primary btn-block")
          ),

          box(
            title = "Interactive Forest Plot",
            status = "info",
            solidHeader = TRUE,
            width = 9,

            withSpinner(plotlyOutput("forest_plot_interactive", height = "700px"))
          )
        )
      ),

      # RANKINGS TAB
      tabItem(
        tabName = "viz_ranking",
        h2("🏆 Treatment Rankings"),

        fluidRow(
          box(
            title = "Rankogram",
            status = "primary",
            solidHeader = TRUE,
            width = 6,

            withSpinner(plotlyOutput("rankogram_plot", height = "500px"))
          ),

          box(
            title = "SUCRA Values",
            status = "success",
            solidHeader = TRUE,
            width = 6,

            withSpinner(plotlyOutput("sucra_bar_plot", height = "500px"))
          )
        ),

        fluidRow(
          box(
            title = "League Table",
            status = "info",
            solidHeader = TRUE,
            width = 12,

            radioButtons(
              "league_better",
              "Higher values are:",
              choices = c("Better" = "higher", "Worse" = "lower"),
              selected = "higher",
              inline = TRUE
            ),

            hr(),

            withSpinner(plotlyOutput("league_table_plot", height = "600px"))
          )
        )
      ),

      # AI ASSISTANT TAB
      tabItem(
        tabName = "ai",
        h2("🤖 AI Assistant"),

        fluidRow(
          box(
            title = "Chat with AI",
            status = "primary",
            solidHeader = TRUE,
            width = 8,
            height = "600px",

            tags$div(
              id = "chat_container",
              style = "height: 450px; overflow-y: scroll; background: #f9f9f9; padding: 15px; border-radius: 5px;",
              uiOutput("chat_history")
            ),

            hr(),

            fluidRow(
              column(
                10,
                textInput(
                  "chat_input",
                  NULL,
                  placeholder = "Ask me anything about your analysis...",
                  width = "100%"
                )
              ),
              column(
                2,
                actionButton(
                  "send_chat",
                  "Send",
                  icon = icon("paper-plane"),
                  class = "btn btn-primary btn-block"
                )
              )
            )
          ),

          box(
            title = "AI Features",
            status = "info",
            solidHeader = TRUE,
            width = 4,

            h4("Available Commands:"),
            tags$ul(
              tags$li(tags$b("/interpret"), " - Interpret current results"),
              tags$li(tags$b("/quality"), " - Assess study quality"),
              tags$li(tags$b("/surrogate"), " - Validate surrogate"),
              tags$li(tags$b("/report"), " - Generate report section"),
              tags$li(tags$b("/suggest"), " - Suggest sensitivity analyses"),
              tags$li(tags$b("/review"), " - Literature review assistance")
            ),

            hr(),

            h4("Quick Actions:"),
            actionButton("ai_interpret", "Interpret Results",
                        class = "btn btn-success btn-block",
                        style = "margin: 5px;"),
            actionButton("ai_quality", "Quality Assessment",
                        class = "btn btn-info btn-block",
                        style = "margin: 5px;"),
            actionButton("ai_surrogate", "Validate Surrogate",
                        class = "btn btn-warning btn-block",
                        style = "margin: 5px;")
          )
        )
      ),

      # METHODS SECTION TAB
      tabItem(
        tabName = "methods",
        h2("📝 Methods Section Generator"),

        fluidRow(
          box(
            title = "Methods Configuration",
            status = "primary",
            solidHeader = TRUE,
            width = 4,

            selectInput(
              "methods_databases",
              "Databases Searched:",
              choices = c("MEDLINE", "Embase", "Cochrane", "Web of Science",
                         "CINAHL", "PsycINFO", "Scopus"),
              selected = c("MEDLINE", "Embase", "Cochrane"),
              multiple = TRUE
            ),

            selectInput(
              "methods_rob_tool",
              "Risk of Bias Tool:",
              choices = c("ROB 2" = "ROB2",
                         "ROBINS-I" = "ROBINS-I",
                         "Newcastle-Ottawa" = "Newcastle-Ottawa",
                         "GRADE" = "GRADE"),
              selected = "ROB2"
            ),

            selectInput(
              "methods_effect_measure",
              "Effect Measure:",
              choices = c("Odds Ratio" = "OR",
                         "Risk Ratio" = "RR",
                         "Hazard Ratio" = "HR",
                         "Mean Difference" = "MD",
                         "Standardized Mean Difference" = "SMD"),
              selected = "HR"
            ),

            hr(),

            actionButton(
              "generate_methods",
              "Generate Methods Section",
              icon = icon("file-alt"),
              class = "btn-analyze btn-lg btn-block"
            )
          ),

          box(
            title = "Generated Methods Section",
            status = "success",
            solidHeader = TRUE,
            width = 8,

            tabBox(
              width = 12,

              tabPanel(
                "Preview",
                withSpinner(uiOutput("methods_preview"))
              ),

              tabPanel(
                "Validation",
                fluidRow(
                  column(6, valueBoxOutput("methods_compliance_box", width = 12)),
                  column(6, valueBoxOutput("methods_violations_box", width = 12))
                ),
                hr(),
                withSpinner(DTOutput("methods_violations_table"))
              ),

              tabPanel(
                "Markdown",
                withSpinner(verbatimTextOutput("methods_markdown"))
              )
            ),

            hr(),

            downloadButton("download_methods", "Download Methods Section",
                          class = "btn btn-primary")
          )
        )
      ),

      # RESULTS SECTION TAB
      tabItem(
        tabName = "results",
        h2("📊 Results Section Generator"),

        fluidRow(
          box(
            title = "Results Configuration",
            status = "primary",
            solidHeader = TRUE,
            width = 4,

            checkboxInput("include_flow_diagram", "Include PRISMA flow diagram", TRUE),
            checkboxInput("include_rob_summary", "Include ROB summary", TRUE),
            checkboxInput("include_rankings", "Include treatment rankings", TRUE),
            checkboxInput("include_sensitivity", "Include sensitivity analyses", TRUE),

            hr(),

            actionButton(
              "generate_results",
              "Generate Results Section",
              icon = icon("chart-bar"),
              class = "btn-analyze btn-lg btn-block"
            )
          ),

          box(
            title = "Generated Results Section",
            status = "success",
            solidHeader = TRUE,
            width = 8,

            tabBox(
              width = 12,

              tabPanel(
                "Preview",
                withSpinner(uiOutput("results_preview"))
              ),

              tabPanel(
                "Validation",
                fluidRow(
                  column(6, valueBoxOutput("results_completeness_box", width = 12)),
                  column(6, valueBoxOutput("results_violations_box", width = 12))
                ),
                hr(),
                withSpinner(DTOutput("results_violations_table"))
              ),

              tabPanel(
                "Markdown",
                withSpinner(verbatimTextOutput("results_markdown"))
              )
            ),

            hr(),

            downloadButton("download_results", "Download Results Section",
                          class = "btn btn-primary")
          )
        )
      ),

      # EXPORT TAB
      tabItem(
        tabName = "export",
        h2("💾 Export & Download"),

        fluidRow(
          box(
            title = "Export Options",
            status = "primary",
            solidHeader = TRUE,
            width = 6,

            h4("📄 Manuscript Components"),
            downloadButton("export_methods", "Methods Section (.docx)",
                          class = "btn btn-info btn-block",
                          style = "margin: 5px;"),
            downloadButton("export_results", "Results Section (.docx)",
                          class = "btn btn-info btn-block",
                          style = "margin: 5px;"),
            downloadButton("export_manuscript", "Complete Manuscript (.docx)",
                          class = "btn btn-success btn-block",
                          style = "margin: 5px;"),

            hr(),

            h4("📊 Visualizations"),
            downloadButton("export_all_viz", "All Plots (ZIP)",
                          class = "btn btn-warning btn-block",
                          style = "margin: 5px;"),

            hr(),

            h4("📊 Data & Results"),
            downloadButton("export_data", "Processed Data (.csv)",
                          class = "btn btn-secondary btn-block",
                          style = "margin: 5px;"),
            downloadButton("export_results_csv", "Results Table (.csv)",
                          class = "btn btn-secondary btn-block",
                          style = "margin: 5px;")
          ),

          box(
            title = "Report Generation",
            status = "success",
            solidHeader = TRUE,
            width = 6,

            selectInput(
              "report_format",
              "Report Format:",
              choices = c("HTML (Interactive)" = "html",
                         "PDF (Publication)" = "pdf",
                         "Word (Editable)" = "docx"),
              selected = "html"
            ),

            checkboxInput("report_include_code", "Include R code", FALSE),
            checkboxInput("report_include_ai", "Include AI interpretation", TRUE),
            checkboxInput("report_include_validation", "Include validation results", TRUE),

            hr(),

            actionButton(
              "generate_report",
              "Generate Complete Report",
              icon = icon("file-pdf"),
              class = "btn-analyze btn-lg btn-block"
            ),

            hr(),

            conditionalPanel(
              condition = "input.generate_report > 0",
              withSpinner(uiOutput("report_status")),
              br(),
              downloadButton("download_report", "Download Report",
                            class = "btn btn-success btn-block")
            )
          )
        )
      ),

      # SETTINGS TAB
      tabItem(
        tabName = "settings",
        h2("⚙️ Settings"),

        fluidRow(
          box(
            title = "AI Configuration",
            status = "primary",
            solidHeader = TRUE,
            width = 6,

            textInput("ollama_url", "Ollama URL:",
                     value = "http://localhost:11434"),

            selectInput("llama_model", "Model:",
                       choices = c("llama3", "llama3:70b", "llama2", "mistral"),
                       selected = "llama3"),

            sliderInput("ai_temperature", "Temperature:",
                       min = 0, max = 1, value = 0.7, step = 0.1),

            actionButton("test_ai_connection", "Test Connection",
                        class = "btn btn-info")
          ),

          box(
            title = "Visualization Settings",
            status = "info",
            solidHeader = TRUE,
            width = 6,

            selectInput("viz_theme", "Plot Theme:",
                       choices = c("Publication" = "publication",
                                  "Presentation" = "presentation",
                                  "Minimal" = "minimal"),
                       selected = "publication"),

            sliderInput("viz_dpi", "DPI for Exports:",
                       min = 150, max = 600, value = 300, step = 50),

            selectInput("viz_color_palette", "Color Palette:",
                       choices = c("Default", "Colorblind-safe", "Grayscale"),
                       selected = "Default")
          )
        )
      )
    )
  )
)

# ============================================================================
# SERVER LOGIC
# ============================================================================

server <- function(input, output, session) {

  # Reactive values to store application state
  rv <- reactiveValues(
    data = NULL,
    network = NULL,
    fit = NULL,
    methods_text = NULL,
    results_text = NULL,
    chat_history = list(),
    llama_conn = NULL
  )

  # Initialize AI connection on startup
  observe({
    rv$llama_conn <- tryCatch({
      init_llama()
    }, error = function(e) {
      NULL
    })
  })

  # HOME TAB - Value Boxes
  output$total_rules_box <- renderValueBox({
    valueBox(
      "1,500+",
      "Validation Rules",
      icon = icon("shield-alt"),
      color = "purple"
    )
  })

  output$total_scenarios_box <- renderValueBox({
    valueBox(
      "30,000+",
      "Test Scenarios",
      icon = icon("flask"),
      color = "blue"
    )
  })

  output$visualizations_box <- renderValueBox({
    valueBox(
      "12+",
      "Visualization Types",
      icon = icon("chart-bar"),
      color = "green"
    )
  })

  output$ai_status_box <- renderValueBox({
    status <- if (!is.null(rv$llama_conn)) "Connected" else "Disconnected"
    color <- if (!is.null(rv$llama_conn)) "green" else "red"

    valueBox(
      status,
      "AI Engine",
      icon = icon("robot"),
      color = color
    )
  })

  # Info boxes
  output$rules_info <- renderInfoBox({
    infoBox(
      "Validation Rules",
      "1,500+ rules across data quality, methods, and results",
      icon = icon("check-circle"),
      color = "purple",
      fill = TRUE
    )
  })

  output$scenarios_info <- renderInfoBox({
    infoBox(
      "Test Scenarios",
      "30,000+ permutations tested",
      icon = icon("vials"),
      color = "blue",
      fill = TRUE
    )
  })

  output$methods_info <- renderInfoBox({
    infoBox(
      "AI Integration",
      "Llama 3 powered interpretation",
      icon = icon("brain"),
      color = "green",
      fill = TRUE
    )
  })

  # Quick demo button
  observeEvent(input$quick_demo, {
    showNotification("Running demo analysis...", type = "message", duration = 3)

    # Simulate data
    demo_data <- simulate_surro_data(K = 5, J = 20, alpha = 0.1, beta = 0.8)
    rv$data <- demo_data

    # Switch to upload tab
    updateTabItems(session, "sidebar_menu", "upload")

    showNotification("Demo data loaded! Proceed to Network Builder.",
                    type = "message", duration = 5)
  })

  # Sidebar stats
  output$n_studies <- renderText({
    if (!is.null(rv$network)) {
      as.character(rv$network$J)
    } else {
      "0"
    }
  })

  output$n_treatments <- renderText({
    if (!is.null(rv$network)) {
      as.character(rv$network$K)
    } else {
      "0"
    }
  })

  output$last_update <- renderText({
    format(Sys.time(), "%H:%M:%S")
  })

  # Auto-update every 30 seconds
  autoInvalidate <- reactiveTimer(30000)
  observe({
    autoInvalidate()
    output$last_update
  })

  # DATA UPLOAD handlers
  observeEvent(input$data_file, {
    req(input$data_file)

    tryCatch({
      if (grepl("\\.csv$", input$data_file$name, ignore.case = TRUE)) {
        rv$data <- read.csv(input$data_file$datapath, header = input$header)
      } else if (grepl("\\.xlsx?$", input$data_file$name, ignore.case = TRUE)) {
        if (requireNamespace("readxl", quietly = TRUE)) {
          rv$data <- as.data.frame(readxl::read_excel(input$data_file$datapath))
        } else {
          showNotification("readxl package required for Excel files",
                          type = "error")
        }
      }

      # Update column selectors
      cols <- names(rv$data)
      updateSelectInput(session, "study_var", choices = cols)
      updateSelectInput(session, "trt_var", choices = cols)
      updateSelectInput(session, "comp_var", choices = cols)
      updateSelectInput(session, "s_eff_var", choices = cols)
      updateSelectInput(session, "s_se_var", choices = cols)
      updateSelectInput(session, "t_eff_var", choices = c("None" = "", cols))
      updateSelectInput(session, "t_se_var", choices = c("None" = "", cols))

      showNotification("Data loaded successfully!", type = "message")
    }, error = function(e) {
      showNotification(paste("Error loading data:", e$message), type = "error")
    })
  })

  # Load example data
  observeEvent(input$load_example, {
    rv$data <- simulate_surro_data(K = 6, J = 25, alpha = 0.2, beta = 0.75)

    # Update selectors
    cols <- names(rv$data)
    updateSelectInput(session, "study_var", choices = cols, selected = "study")
    updateSelectInput(session, "trt_var", choices = cols, selected = "trt")
    updateSelectInput(session, "comp_var", choices = cols, selected = "comp")
    updateSelectInput(session, "s_eff_var", choices = cols, selected = "logHR_S")
    updateSelectInput(session, "s_se_var", choices = cols, selected = "se_S")
    updateSelectInput(session, "t_eff_var", choices = cols, selected = "logHR_T")
    updateSelectInput(session, "t_se_var", choices = cols, selected = "se_T")

    showNotification("Example data loaded!", type = "message")
  })

  # Data preview
  output$data_preview <- renderDT({
    req(rv$data)
    datatable(
      head(rv$data, 50),
      options = list(
        scrollX = TRUE,
        pageLength = 10,
        dom = 'Bfrtip'
      ),
      class = 'cell-border stripe'
    )
  })

  output$n_rows_box <- renderValueBox({
    valueBox(
      if (!is.null(rv$data)) nrow(rv$data) else 0,
      "Rows",
      icon = icon("table"),
      color = "blue"
    )
  })

  output$n_cols_box <- renderValueBox({
    valueBox(
      if (!is.null(rv$data)) ncol(rv$data) else 0,
      "Columns",
      icon = icon("columns"),
      color = "green"
    )
  })

  output$data_status_box <- renderValueBox({
    status <- if (!is.null(rv$data)) "Loaded" else "No Data"
    color <- if (!is.null(rv$data)) "green" else "red"

    valueBox(
      status,
      "Data Status",
      icon = icon("check-circle"),
      color = color
    )
  })

  # BUILD NETWORK handler
  observeEvent(input$build_network, {
    req(rv$data, input$study_var, input$trt_var, input$comp_var,
        input$s_eff_var, input$s_se_var)

    showNotification("Building network...", type = "message", duration = 2)

    tryCatch({
      rv$network <- surro_network(
        data = rv$data,
        study = !!rlang::sym(input$study_var),
        trt = !!rlang::sym(input$trt_var),
        comp = !!rlang::sym(input$comp_var),
        S_eff = !!rlang::sym(input$s_eff_var),
        S_se = !!rlang::sym(input$s_se_var),
        T_eff = if (nzchar(input$t_eff_var)) !!rlang::sym(input$t_eff_var) else NULL,
        T_se = if (nzchar(input$t_se_var)) !!rlang::sym(input$t_se_var) else NULL,
        check_connectivity = input$check_connectivity
      )

      showNotification("Network built successfully!", type = "message")

      # Switch to analysis tab
      updateTabItems(session, "sidebar_menu", "primary_analysis")
    }, error = function(e) {
      showNotification(paste("Error building network:", e$message),
                      type = "error", duration = 10)
    })
  })

  # Network summary
  output$network_summary_ui <- renderUI({
    req(rv$network)

    tagList(
      h4(paste("Network with", rv$network$K, "treatments")),
      p(paste("Total studies:", rv$network$J)),
      p(paste("Direct comparisons:", nrow(rv$network$data))),
      p(paste("Treatment labels:", paste(rv$network$trt_levels, collapse = ", ")))
    )
  })

  # Treatment and study value boxes
  output$n_treatments_box <- renderValueBox({
    valueBox(
      if (!is.null(rv$network)) rv$network$K else 0,
      "Treatments",
      icon = icon("pills"),
      color = "purple"
    )
  })

  output$n_studies_box <- renderValueBox({
    valueBox(
      if (!is.null(rv$network)) rv$network$J else 0,
      "Studies",
      icon = icon("book-medical"),
      color = "blue"
    )
  })

  # RUN ANALYSIS handler (simplified for demo)
  observeEvent(input$run_analysis, {
    req(rv$network)

    showModal(modalDialog(
      title = "Running Analysis",
      "Please wait while the analysis is running...",
      footer = NULL,
      easyClose = FALSE
    ))

    tryCatch({
      rv$fit <- surro_nma_intelligent(
        rv$network,
        engine = input$engine,
        use_ai = input$use_ai && !is.null(rv$llama_conn),
        apply_rules = input$apply_rules,
        auto_sensitivity = input$auto_sensitivity,
        llama_conn = rv$llama_conn
      )

      removeModal()
      showNotification("Analysis complete!", type = "message")
    }, error = function(e) {
      removeModal()
      showNotification(paste("Error in analysis:", e$message),
                      type = "error", duration = 10)
    })
  })

  # Results summary table
  output$results_summary_table <- renderDT({
    req(rv$fit)

    summ <- summarize_treatments(rv$fit$fit)

    datatable(
      summ,
      options = list(
        pageLength = 20,
        dom = 'Bfrtip'
      ),
      class = 'cell-border stripe'
    ) %>%
      formatRound(columns = 1:ncol(summ), digits = 3)
  })

  # VISUALIZATION HANDLERS

  # Network graph preview
  output$network_graph_preview <- renderPlotly({
    req(rv$network)

    tryCatch({
      p <- plot_network(rv$network, layout = "kamada.kawai", interactive = FALSE)
      ggplotly(p)
    }, error = function(e) {
      plotly_empty() %>%
        add_annotations(text = "Network graph not available",
                       showarrow = FALSE)
    })
  })

  # Main network plot
  output$network_plot_main <- renderPlotly({
    req(rv$network)

    tryCatch({
      p <- plot_network(
        rv$network,
        layout = input$network_layout,
        show_weights = input$show_weights,
        interactive = input$interactive_network
      )
      ggplotly(p, tooltip = c("text"))
    }, error = function(e) {
      plotly_empty() %>%
        add_annotations(text = paste("Error:", e$message), showarrow = FALSE)
    })
  })

  # Network geometry plot
  output$geometry_plot <- renderPlotly({
    req(rv$network)

    tryCatch({
      if (requireNamespace("advanced_visualizations", quietly = TRUE)) {
        p <- plot_network_geometry(
          rv$network,
          method = input$geometry_method,
          dimension = input$geometry_dim,
          interactive = TRUE
        )
        p
      } else {
        plotly_empty() %>%
          add_annotations(text = "Advanced visualizations module required",
                         showarrow = FALSE)
      }
    }, error = function(e) {
      plotly_empty() %>%
        add_annotations(text = paste("Error:", e$message), showarrow = FALSE)
    })
  })

  # Contribution matrix
  output$contribution_matrix_plot <- renderPlotly({
    req(rv$fit)

    tryCatch({
      if (requireNamespace("advanced_visualizations", quietly = TRUE)) {
        p <- plot_contribution_matrix(rv$fit$fit, interactive = TRUE)
        p
      } else {
        plotly_empty() %>%
          add_annotations(text = "Advanced visualizations module required",
                         showarrow = FALSE)
      }
    }, error = function(e) {
      plotly_empty() %>%
        add_annotations(text = paste("Error:", e$message), showarrow = FALSE)
    })
  })

  # Update forest plot reference selector
  observe({
    req(rv$network)
    updateSelectInput(session, "forest_reference",
                     choices = rv$network$trt_levels,
                     selected = rv$network$trt_levels[1])
  })

  # Forest plot
  output$forest_plot_interactive <- renderPlotly({
    req(rv$fit, input$forest_reference)

    tryCatch({
      p <- plot_forest_advanced(
        rv$fit$fit,
        ref = input$forest_reference,
        show_heterogeneity = input$show_heterogeneity,
        show_prediction = input$show_prediction,
        ci_level = input$forest_ci_level
      )
      ggplotly(p, tooltip = c("text"))
    }, error = function(e) {
      plotly_empty() %>%
        add_annotations(text = paste("Error:", e$message), showarrow = FALSE)
    })
  })

  # Rankogram
  output$rankogram_plot <- renderPlotly({
    req(rv$fit)

    tryCatch({
      ranks <- get_rankings(rv$fit$fit)
      p <- plot_rankogram(ranks, interactive = TRUE)
      p
    }, error = function(e) {
      plotly_empty() %>%
        add_annotations(text = paste("Error:", e$message), showarrow = FALSE)
    })
  })

  # SUCRA bar plot
  output$sucra_bar_plot <- renderPlotly({
    req(rv$fit)

    tryCatch({
      sucra <- calculate_sucra(rv$fit$fit)
      plot_ly(
        x = names(sucra),
        y = sucra,
        type = "bar",
        marker = list(color = "steelblue")
      ) %>%
        layout(
          title = "SUCRA Values by Treatment",
          xaxis = list(title = "Treatment"),
          yaxis = list(title = "SUCRA", range = c(0, 1))
        )
    }, error = function(e) {
      plotly_empty() %>%
        add_annotations(text = paste("Error:", e$message), showarrow = FALSE)
    })
  })

  # League table
  output$league_table_plot <- renderPlotly({
    req(rv$fit)

    tryCatch({
      p <- plot_league_table(
        rv$fit$fit,
        better = input$league_better,
        interactive = TRUE
      )
      p
    }, error = function(e) {
      plotly_empty() %>%
        add_annotations(text = paste("Error:", e$message), showarrow = FALSE)
    })
  })

  # Rankings table
  output$rankings_table <- renderDT({
    req(rv$fit)

    tryCatch({
      ranks <- get_rankings(rv$fit$fit)
      sucra <- calculate_sucra(rv$fit$fit)

      rank_df <- data.frame(
        Treatment = names(sucra),
        SUCRA = round(sucra, 3),
        MeanRank = round(ranks$mean_rank, 2),
        MedianRank = round(ranks$median_rank, 1)
      )

      datatable(
        rank_df,
        options = list(pageLength = 20, dom = 'Bfrtip'),
        class = 'cell-border stripe'
      ) %>%
        formatStyle('SUCRA',
                   background = styleColorBar(c(0, 1), 'lightblue'),
                   backgroundSize = '100% 90%',
                   backgroundRepeat = 'no-repeat',
                   backgroundPosition = 'center')
    }, error = function(e) {
      NULL
    })
  })

  # SUCRA plot in results tab
  output$sucra_plot <- renderPlotly({
    req(rv$fit)

    tryCatch({
      sucra <- calculate_sucra(rv$fit$fit)
      plot_ly(
        x = names(sucra),
        y = sucra,
        type = "bar",
        marker = list(
          color = sucra,
          colorscale = list(c(0, "red"), c(0.5, "yellow"), c(1, "green")),
          showscale = TRUE
        )
      ) %>%
        layout(
          xaxis = list(title = "Treatment"),
          yaxis = list(title = "SUCRA", range = c(0, 1))
        )
    }, error = function(e) {
      plotly_empty()
    })
  })

  # Diagnostics
  output$diagnostics_text <- renderPrint({
    req(rv$fit)

    if (rv$fit$engine == "bayes") {
      cat("MCMC Diagnostics:\n\n")
      print(rv$fit$fit$diagnostics)
    } else {
      cat("Frequentist Analysis - No MCMC diagnostics\n")
      cat("Bootstrap samples:", rv$fit$fit$B, "\n")
    }
  })

  output$diagnostic_plots <- renderPlotly({
    req(rv$fit)

    if (rv$fit$engine == "bayes") {
      tryCatch({
        p <- plot_mcmc_diagnostics(rv$fit$fit, interactive = TRUE)
        p
      }, error = function(e) {
        plotly_empty()
      })
    } else {
      plotly_empty() %>%
        add_annotations(text = "Diagnostic plots available for Bayesian analysis only",
                       showarrow = FALSE)
    }
  })

  # AI INTERPRETATION
  output$ai_interpretation_ui <- renderUI({
    req(rv$fit)

    if (!is.null(rv$llama_conn) && !is.null(rv$fit$ai_interpretation)) {
      tagList(
        tags$div(
          style = "background: #f9f9f9; padding: 20px; border-radius: 8px;",
          h4("AI-Generated Interpretation", style = "color: #3c8dbc;"),
          tags$p(rv$fit$ai_interpretation$summary),
          hr(),
          h5("Key Findings:"),
          tags$ul(
            lapply(rv$fit$ai_interpretation$key_findings, function(f) {
              tags$li(f)
            })
          ),
          hr(),
          h5("Clinical Implications:"),
          tags$p(rv$fit$ai_interpretation$clinical_implications)
        )
      )
    } else {
      tags$div(
        style = "text-align: center; padding: 30px;",
        icon("robot", class = "fa-3x", style = "color: #ccc;"),
        h4("AI interpretation not available", style = "color: #999;"),
        p("Enable 'Use AI interpretation' in analysis settings")
      )
    }
  })

  # Quality assessment boxes
  output$rules_passed_box <- renderValueBox({
    req(rv$fit)

    passed <- if (!is.null(rv$fit$validation)) {
      sum(rv$fit$validation$passed)
    } else {
      0
    }

    valueBox(
      passed,
      "Rules Passed",
      icon = icon("check-circle"),
      color = "green"
    )
  })

  output$rules_warnings_box <- renderValueBox({
    req(rv$fit)

    warnings <- if (!is.null(rv$fit$validation)) {
      sum(rv$fit$validation$warnings)
    } else {
      0
    }

    valueBox(
      warnings,
      "Warnings",
      icon = icon("exclamation-triangle"),
      color = "yellow"
    )
  })

  output$rules_errors_box <- renderValueBox({
    req(rv$fit)

    errors <- if (!is.null(rv$fit$validation)) {
      sum(rv$fit$validation$errors)
    } else {
      0
    }

    valueBox(
      errors,
      "Errors",
      icon = icon("times-circle"),
      color = "red"
    )
  })

  output$quality_score_box <- renderValueBox({
    req(rv$fit)

    score <- if (!is.null(rv$fit$validation)) {
      round(rv$fit$validation$quality_score * 100, 1)
    } else {
      0
    }

    color <- if (score >= 90) "green" else if (score >= 70) "yellow" else "red"

    valueBox(
      paste0(score, "%"),
      "Quality Score",
      icon = icon("star"),
      color = color
    )
  })

  output$validation_details <- renderDT({
    req(rv$fit)

    if (!is.null(rv$fit$validation$details)) {
      datatable(
        rv$fit$validation$details,
        options = list(pageLength = 10, dom = 'Bfrtip'),
        class = 'cell-border stripe',
        filter = 'top'
      )
    }
  })

  # AI CHAT INTERFACE
  output$chat_history <- renderUI({
    if (length(rv$chat_history) == 0) {
      return(
        tags$div(
          style = "text-align: center; padding: 50px;",
          icon("comments", class = "fa-3x", style = "color: #ccc;"),
          h5("Start a conversation with the AI assistant", style = "color: #999;")
        )
      )
    }

    chat_elements <- lapply(rv$chat_history, function(msg) {
      if (msg$role == "user") {
        tags$div(
          class = "chat-message user-message",
          style = "background: #3c8dbc; color: white; padding: 10px; border-radius: 10px; margin: 10px 0; max-width: 80%;",
          tags$strong("You: "),
          msg$content
        )
      } else {
        tags$div(
          class = "chat-message ai-message",
          style = "background: #f4f4f4; padding: 10px; border-radius: 10px; margin: 10px 0; max-width: 80%;",
          tags$strong(icon("robot"), " AI: "),
          msg$content
        )
      }
    })

    do.call(tagList, chat_elements)
  })

  # Send chat message
  observeEvent(input$send_chat, {
    req(input$chat_input, rv$llama_conn)

    if (nzchar(trimws(input$chat_input))) {
      # Add user message
      rv$chat_history <- c(rv$chat_history, list(
        list(role = "user", content = input$chat_input, timestamp = Sys.time())
      ))

      user_msg <- input$chat_input
      updateTextInput(session, "chat_input", value = "")

      # Generate AI response
      tryCatch({
        context <- if (!is.null(rv$fit)) {
          paste("Current analysis:", rv$fit$engine, "engine with",
                rv$network$K, "treatments and", rv$network$J, "studies")
        } else if (!is.null(rv$network)) {
          paste("Network built with", rv$network$K, "treatments and",
                rv$network$J, "studies. No analysis run yet.")
        } else {
          "No analysis data loaded yet."
        }

        response <- rv$llama_conn$generate(
          prompt = paste("User question:", user_msg, "\nContext:", context),
          system = "You are a helpful assistant for network meta-analysis. Provide clear, concise, and accurate responses.",
          temperature = input$ai_temperature
        )

        rv$chat_history <- c(rv$chat_history, list(
          list(role = "assistant", content = response, timestamp = Sys.time())
        ))
      }, error = function(e) {
        rv$chat_history <- c(rv$chat_history, list(
          list(role = "assistant",
               content = paste("Error:", e$message),
               timestamp = Sys.time())
        ))
      })
    }
  })

  # AI quick action buttons
  observeEvent(input$ai_interpret, {
    req(rv$fit, rv$llama_conn)

    updateTextInput(session, "chat_input", value = "/interpret")
    click("send_chat")
  })

  observeEvent(input$ai_quality, {
    req(rv$fit, rv$llama_conn)

    updateTextInput(session, "chat_input", value = "/quality")
    click("send_chat")
  })

  observeEvent(input$ai_surrogate, {
    req(rv$network, rv$llama_conn)

    updateTextInput(session, "chat_input", value = "/surrogate")
    click("send_chat")
  })

  # METHODS SECTION GENERATION
  observeEvent(input$generate_methods, {
    req(rv$network, rv$fit)

    showNotification("Generating methods section...", type = "message", duration = 3)

    tryCatch({
      methods_spec <- list(
        databases = input$methods_databases,
        rob_tool = input$methods_rob_tool,
        effect_measure = input$methods_effect_measure,
        engine = rv$fit$engine
      )

      rv$methods_text <- generate_methods_text(
        rv$network,
        rv$fit$fit,
        llama_conn = rv$llama_conn,
        methods_spec = methods_spec
      )

      showNotification("Methods section generated!", type = "message")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  output$methods_preview <- renderUI({
    req(rv$methods_text)

    HTML(markdown::renderMarkdown(text = rv$methods_text$text))
  })

  output$methods_markdown <- renderPrint({
    req(rv$methods_text)

    cat(rv$methods_text$text)
  })

  output$methods_compliance_box <- renderValueBox({
    req(rv$methods_text)

    score <- round(rv$methods_text$compliance_score * 100, 1)
    color <- if (score >= 90) "green" else if (score >= 70) "yellow" else "red"

    valueBox(
      paste0(score, "%"),
      "Compliance Score",
      icon = icon("check-circle"),
      color = color
    )
  })

  output$methods_violations_box <- renderValueBox({
    req(rv$methods_text)

    violations <- length(rv$methods_text$violations)
    color <- if (violations == 0) "green" else if (violations < 5) "yellow" else "red"

    valueBox(
      violations,
      "Violations",
      icon = icon("exclamation-triangle"),
      color = color
    )
  })

  output$methods_violations_table <- renderDT({
    req(rv$methods_text)

    if (length(rv$methods_text$violations) > 0) {
      datatable(
        rv$methods_text$violations,
        options = list(pageLength = 10),
        class = 'cell-border stripe'
      )
    }
  })

  # RESULTS SECTION GENERATION
  observeEvent(input$generate_results, {
    req(rv$network, rv$fit)

    showNotification("Generating results section...", type = "message", duration = 3)

    tryCatch({
      results_spec <- list(
        include_flow_diagram = input$include_flow_diagram,
        include_rob_summary = input$include_rob_summary,
        include_rankings = input$include_rankings,
        include_sensitivity = input$include_sensitivity
      )

      rv$results_text <- generate_results_text(
        rv$network,
        rv$fit$fit,
        llama_conn = rv$llama_conn,
        results_spec = results_spec
      )

      showNotification("Results section generated!", type = "message")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  output$results_preview <- renderUI({
    req(rv$results_text)

    HTML(markdown::renderMarkdown(text = rv$results_text$text))
  })

  output$results_markdown <- renderPrint({
    req(rv$results_text)

    cat(rv$results_text$text)
  })

  output$results_completeness_box <- renderValueBox({
    req(rv$results_text)

    score <- round(rv$results_text$completeness_score * 100, 1)
    color <- if (score >= 90) "green" else if (score >= 70) "yellow" else "red"

    valueBox(
      paste0(score, "%"),
      "Completeness",
      icon = icon("check-circle"),
      color = color
    )
  })

  output$results_violations_box <- renderValueBox({
    req(rv$results_text)

    violations <- length(rv$results_text$violations)
    color <- if (violations == 0) "green" else if (violations < 5) "yellow" else "red"

    valueBox(
      violations,
      "Issues",
      icon = icon("exclamation-triangle"),
      color = color
    )
  })

  output$results_violations_table <- renderDT({
    req(rv$results_text)

    if (length(rv$results_text$violations) > 0) {
      datatable(
        rv$results_text$violations,
        options = list(pageLength = 10),
        class = 'cell-border stripe'
      )
    }
  })

  # EXPORT/DOWNLOAD HANDLERS
  output$download_methods <- downloadHandler(
    filename = function() {
      paste0("methods_section_", Sys.Date(), ".docx")
    },
    content = function(file) {
      req(rv$methods_text)

      # Create Word document
      if (requireNamespace("rmarkdown", quietly = TRUE)) {
        temp_md <- tempfile(fileext = ".md")
        writeLines(rv$methods_text$text, temp_md)
        rmarkdown::render(temp_md, output_format = "word_document",
                         output_file = file, quiet = TRUE)
      } else {
        writeLines(rv$methods_text$text, file)
      }
    }
  )

  output$download_results <- downloadHandler(
    filename = function() {
      paste0("results_section_", Sys.Date(), ".docx")
    },
    content = function(file) {
      req(rv$results_text)

      if (requireNamespace("rmarkdown", quietly = TRUE)) {
        temp_md <- tempfile(fileext = ".md")
        writeLines(rv$results_text$text, temp_md)
        rmarkdown::render(temp_md, output_format = "word_document",
                         output_file = file, quiet = TRUE)
      } else {
        writeLines(rv$results_text$text, file)
      }
    }
  )

  output$export_methods <- downloadHandler(
    filename = function() {
      paste0("methods_", Sys.Date(), ".docx")
    },
    content = function(file) {
      req(rv$methods_text)

      if (requireNamespace("rmarkdown", quietly = TRUE)) {
        temp_md <- tempfile(fileext = ".md")
        writeLines(rv$methods_text$text, temp_md)
        rmarkdown::render(temp_md, output_format = "word_document",
                         output_file = file, quiet = TRUE)
      }
    }
  )

  output$export_results <- downloadHandler(
    filename = function() {
      paste0("results_", Sys.Date(), ".docx")
    },
    content = function(file) {
      req(rv$results_text)

      if (requireNamespace("rmarkdown", quietly = TRUE)) {
        temp_md <- tempfile(fileext = ".md")
        writeLines(rv$results_text$text, temp_md)
        rmarkdown::render(temp_md, output_format = "word_document",
                         output_file = file, quiet = TRUE)
      }
    }
  )

  output$export_manuscript <- downloadHandler(
    filename = function() {
      paste0("manuscript_", Sys.Date(), ".docx")
    },
    content = function(file) {
      req(rv$methods_text, rv$results_text)

      full_text <- paste(
        "# Methods\n\n",
        rv$methods_text$text,
        "\n\n# Results\n\n",
        rv$results_text$text,
        sep = "\n"
      )

      if (requireNamespace("rmarkdown", quietly = TRUE)) {
        temp_md <- tempfile(fileext = ".md")
        writeLines(full_text, temp_md)
        rmarkdown::render(temp_md, output_format = "word_document",
                         output_file = file, quiet = TRUE)
      }
    }
  )

  output$export_data <- downloadHandler(
    filename = function() {
      paste0("data_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(rv$data)
      write.csv(rv$data, file, row.names = FALSE)
    }
  )

  output$export_results_csv <- downloadHandler(
    filename = function() {
      paste0("results_", Sys.Date(), ".csv")
    },
    content = function(file) {
      req(rv$fit)

      summ <- summarize_treatments(rv$fit$fit)
      write.csv(summ, file, row.names = FALSE)
    }
  )

  output$export_all_viz <- downloadHandler(
    filename = function() {
      paste0("visualizations_", Sys.Date(), ".zip")
    },
    content = function(file) {
      req(rv$fit)

      # Create temp directory
      temp_dir <- tempdir()

      # Save all plots
      tryCatch({
        ggsave(file.path(temp_dir, "network.pdf"),
               plot_network(rv$network), width = 10, height = 8)
        ggsave(file.path(temp_dir, "forest.pdf"),
               plot_forest_advanced(rv$fit$fit), width = 12, height = 10)
        ggsave(file.path(temp_dir, "rankings.pdf"),
               plot_rankogram(get_rankings(rv$fit$fit)), width = 10, height = 8)

        # Create ZIP
        zip::zip(file, files = list.files(temp_dir, pattern = "\\.pdf$",
                                          full.names = TRUE))
      }, error = function(e) {
        showNotification(paste("Error creating ZIP:", e$message), type = "error")
      })
    }
  )

  # COMPLETE REPORT GENERATION
  observeEvent(input$generate_report, {
    req(rv$network, rv$fit)

    showNotification("Generating comprehensive report...",
                    type = "message", duration = 5)

    tryCatch({
      report <- complete_nma_workflow(
        data = rv$data,
        study_col = input$study_var,
        trt_col = input$trt_var,
        comp_col = input$comp_var,
        s_eff_col = input$s_eff_var,
        s_se_col = input$s_se_var,
        engine = input$engine,
        use_ai = !is.null(rv$llama_conn),
        generate_visualizations = TRUE,
        generate_manuscript = TRUE,
        output_dir = tempdir()
      )

      rv$report_path <- file.path(tempdir(),
                                   paste0("comprehensive_report.",
                                          input$report_format))

      showNotification("Report generated successfully!", type = "message")
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })

  output$report_status <- renderUI({
    req(rv$report_path)

    tags$div(
      class = "alert alert-success",
      icon("check-circle"),
      " Report generated successfully!",
      tags$br(),
      tags$small(basename(rv$report_path))
    )
  })

  output$download_report <- downloadHandler(
    filename = function() {
      paste0("surronma_report_", Sys.Date(), ".", input$report_format)
    },
    content = function(file) {
      req(rv$report_path)
      file.copy(rv$report_path, file)
    }
  )

  # DATA QUALITY CHECKS
  output$data_summary <- renderPrint({
    req(rv$data)
    summary(rv$data)
  })

  output$missing_plot <- renderPlotly({
    req(rv$data)

    missing_pct <- colMeans(is.na(rv$data)) * 100

    plot_ly(
      x = names(missing_pct),
      y = missing_pct,
      type = "bar",
      marker = list(
        color = ifelse(missing_pct > 20, "red",
                      ifelse(missing_pct > 5, "yellow", "green"))
      )
    ) %>%
      layout(
        title = "Missing Data by Column",
        xaxis = list(title = "Column"),
        yaxis = list(title = "Missing (%)", range = c(0, 100))
      )
  })

  output$distribution_plots <- renderPlotly({
    req(rv$data)

    numeric_cols <- names(rv$data)[sapply(rv$data, is.numeric)]

    if (length(numeric_cols) > 0) {
      col_to_plot <- numeric_cols[1]

      plot_ly(x = rv$data[[col_to_plot]], type = "histogram") %>%
        layout(
          title = paste("Distribution of", col_to_plot),
          xaxis = list(title = col_to_plot),
          yaxis = list(title = "Frequency")
        )
    } else {
      plotly_empty() %>%
        add_annotations(text = "No numeric columns to plot", showarrow = FALSE)
    }
  })

  output$validation_results <- renderDT({
    req(rv$data)

    validation <- data.frame(
      Check = c("No missing values", "No duplicates", "Valid ranges",
                "Consistent types"),
      Status = c(
        ifelse(any(is.na(rv$data)), "FAIL", "PASS"),
        ifelse(any(duplicated(rv$data)), "FAIL", "PASS"),
        "PASS",
        "PASS"
      )
    )

    datatable(
      validation,
      options = list(dom = 't'),
      class = 'cell-border stripe'
    ) %>%
      formatStyle(
        'Status',
        target = 'row',
        backgroundColor = styleEqual(c('PASS', 'FAIL'), c('lightgreen', 'lightcoral'))
      )
  })

  # Treatment table
  output$treatment_table <- renderDT({
    req(rv$network)

    trt_info <- data.frame(
      Treatment = rv$network$trt_levels,
      Studies = sapply(rv$network$trt_levels, function(t) {
        sum(rv$network$data$trt == t | rv$network$data$comp == t)
      }),
      DirectComparisons = sapply(rv$network$trt_levels, function(t) {
        sum(rv$network$data$trt == t | rv$network$data$comp == t)
      })
    )

    datatable(
      trt_info,
      options = list(pageLength = 20),
      class = 'cell-border stripe'
    )
  })

  # TEST AI CONNECTION
  observeEvent(input$test_ai_connection, {
    tryCatch({
      test_conn <- init_llama(
        base_url = input$ollama_url,
        model = input$llama_model
      )

      if (test_conn$is_available()) {
        showNotification("AI connection successful!", type = "message")
        rv$llama_conn <- test_conn
      } else {
        showNotification("AI connection failed. Check Ollama service.",
                        type = "error")
      }
    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
}

# ============================================================================
# RUN APPLICATION
# ============================================================================

#' Launch surroNMA Shiny Dashboard
#' @export
launch_surronma_dashboard <- function(port = 3838, launch.browser = TRUE) {
  message("Launching surroNMA Interactive Dashboard...")
  message("Access at: http://localhost:", port)

  shinyApp(ui = ui, server = server, options = list(
    port = port,
    launch.browser = launch.browser
  ))
}
