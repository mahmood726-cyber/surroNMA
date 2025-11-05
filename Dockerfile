# surroNMA Dashboard - Production Docker Image
# Version 5.0

FROM rocker/r-ver:4.3.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml2-dev \
    libpq-dev \
    libsqlite3-dev \
    libgit2-dev \
    libssh2-1-dev \
    libssl-dev \
    zlib1g-dev \
    pandoc \
    pandoc-citeproc \
    texlive-latex-base \
    texlive-fonts-recommended \
    texlive-latex-extra \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install cmdstan for Bayesian analysis
RUN wget https://github.com/stan-dev/cmdstan/releases/download/v2.33.1/cmdstan-2.33.1.tar.gz \
    && tar -xzf cmdstan-2.33.1.tar.gz \
    && cd cmdstan-2.33.1 \
    && make build \
    && cd .. \
    && rm cmdstan-2.33.1.tar.gz

ENV CMDSTAN=/cmdstan-2.33.1

# Install R packages
RUN R -e "install.packages(c('shiny', 'shinydashboard', 'shinyjs', 'DT', \
    'plotly', 'ggplot2', 'dplyr', 'tidyr', 'R6', 'jsonlite', \
    'httr', 'digest', 'markdown', 'rmarkdown', 'knitr', \
    'RSQLite', 'DBI', 'readxl', 'writexl', 'zip', 'htmlwidgets', \
    'shinycssloaders', 'visNetwork', 'igraph', 'metafor', \
    'netmeta', 'gemtc', 'coda', 'ggraph', 'patchwork', \
    'RColorBrewer', 'viridis', 'Rtsne', 'umap', 'Matrix', \
    'MASS', 'mvtnorm', 'MCMCpack', 'BH', 'RcppEigen'), \
    repos='https://cloud.r-project.org/')"

# Install cmdstanr
RUN R -e "install.packages('cmdstanr', repos = c('https://mc-stan.org/r-packages/', getOption('repos')))" \
    && R -e "cmdstanr::check_cmdstan_toolchain(fix = TRUE)"

# Install Ollama for AI features (optional)
RUN curl -fsSL https://ollama.com/install.sh | sh

# Create app directory
RUN mkdir -p /app /data
WORKDIR /app

# Copy surroNMA files
COPY surroNMA /app/surroNMA
COPY *.R /app/
COPY DESCRIPTION /app/

# Create necessary directories
RUN mkdir -p /data/session_storage \
    /data/session_storage/autosaves \
    /data/databases \
    /data/uploads

# Set permissions
RUN chmod -R 755 /app \
    && chmod -R 777 /data

# Expose Shiny port
EXPOSE 3838

# Expose Ollama port (for AI features)
EXPOSE 11434

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:3838/ || exit 1

# Create startup script
RUN echo '#!/bin/bash\n\
\n\
# Start Ollama in background (optional)\n\
if [ "$ENABLE_AI" = "true" ]; then\n\
  ollama serve &\n\
  sleep 5\n\
  # Pull llama3 model if not exists\n\
  ollama pull llama3 &\n\
fi\n\
\n\
# Start Shiny app\n\
R -e "source(\"/app/launch_dashboard.R\")" \n\
' > /app/start.sh && chmod +x /app/start.sh

# Create launch script
RUN echo 'library(shiny)\n\
\n\
# Set working directory\n\
setwd("/app")\n\
\n\
# Source all modules\n\
source("surroNMA")\n\
source("auth_system.R")\n\
source("session_manager.R")\n\
source("collaboration.R")\n\
source("rules_engine.R")\n\
source("scenarios.R")\n\
source("llama_integration.R")\n\
source("ai_enhanced_nma.R")\n\
source("advanced_visualizations.R")\n\
source("advanced_viz_2025.R")\n\
source("methods_generator.R")\n\
source("results_generator.R")\n\
source("master_integration.R")\n\
source("realtime_collab.R")\n\
source("shiny_dashboard_v5.R")\n\
\n\
# Initialize databases\n\
message("Initializing databases...")\n\
user_db <- init_user_db("/data/databases/surronma_users.db")\n\
session_mgr <- SessionManager$new("/data/databases/surronma_sessions.db", "/data/session_storage")\n\
collab_mgr <- CollaborationManager$new("/data/databases/surronma_collab.db")\n\
\n\
# Launch dashboard\n\
message("Launching surroNMA Dashboard v5.0...")\n\
message("Access at: http://localhost:3838")\n\
\n\
runApp(appDir = "/app", \n\
       host = "0.0.0.0", \n\
       port = 3838, \n\
       launch.browser = FALSE)\n\
' > /app/launch_dashboard.R

# Environment variables
ENV SHINY_LOG_STDERR=1
ENV SHINY_LOG_LEVEL=INFO
ENV ENABLE_AI=false
ENV DATA_DIR=/data

# Run startup script
CMD ["/app/start.sh"]
