# Installation Guide - surroNMA v2.0

## System Requirements

- **R**: Version 4.0.0 or higher
- **Operating System**: Linux, macOS, or Windows
- **RAM**: Minimum 4GB, recommended 8GB+
- **Disk Space**: 2GB for full installation with all dependencies

## Step 1: Install R Dependencies

### Core Dependencies (Required)

```r
install.packages(c(
  "R6",        # Object-oriented programming
  "Matrix",    # Matrix operations
  "MASS"       # Statistical functions
))
```

### Statistical Dependencies (Recommended)

```r
install.packages(c(
  "posterior",  # Bayesian posterior processing
  "igraph",     # Network graph analysis
  "ggplot2",    # Visualization
  "glmnet",     # Regularized regression for SI
  "pls",        # Partial least squares for SI
  "rmarkdown",  # Report generation
  "knitr"       # Document processing
))
```

### Bayesian Analysis (cmdstanr)

```r
# Install cmdstanr
install.packages("cmdstanr",
                repos = c("https://mc-stan.org/r-packages/",
                         getOption("repos")))

# Install CmdStan
library(cmdstanr)
check_cmdstan_toolchain()
install_cmdstan()

# Verify installation
cmdstan_version()
```

### AI Dependencies

```r
install.packages(c(
  "httr",       # HTTP requests to Ollama
  "jsonlite"    # JSON parsing
))
```

## Step 2: Install Ollama for AI Features

### Linux

```bash
curl https://ollama.ai/install.sh | sh
```

### macOS

```bash
# Download from https://ollama.ai
# Or use Homebrew
brew install ollama
```

### Windows

Download the installer from https://ollama.ai and run it.

### Verify Ollama Installation

```bash
ollama --version
```

## Step 3: Install Llama 3 Model

```bash
# Start Ollama service (in a separate terminal)
ollama serve

# Pull Llama 3 model (this will download ~4GB)
ollama pull llama3

# Verify model is available
ollama list
```

## Step 4: Load surroNMA

```r
# Set working directory to surroNMA folder
setwd("/path/to/surroNMA")

# Source main package
source("surroNMA")

# Source AI and rules modules
source("rules_engine.R")
source("scenarios.R")
source("llama_integration.R")
source("ai_enhanced_nma.R")
```

## Step 5: Verify Installation

```r
# Check if all core functions load
exists("surro_network")
exists("surro_nma")
exists("create_complete_rules_system")
exists("init_llama")

# Check Llama 3 connectivity
check_llama_setup()

# Should see:
# ✓ httr package installed
# ✓ Ollama service running
# ✓ X model(s) available:
#   - llama3
# ✓ Llama 3 is ready to use!
```

## Step 6: Run Quick Test

```r
# Generate test data
test_data <- simulate_surro_data(K = 5, J = 20, alpha = 0.1, beta = 0.8)

# Build network
test_net <- surro_network(
  data = test_data,
  study = study,
  trt = trt,
  comp = comp,
  S_eff = logHR_S,
  S_se = se_S,
  T_eff = logHR_T,
  T_se = se_T
)

# Run basic analysis
test_fit <- surro_nma(test_net, engine = "freq")

# If successful, you should see results
summary(test_fit)

# Test AI features
llama <- init_llama()
test_llama_connection(llama)
```

## Common Installation Issues

### Issue 1: CmdStan Installation Fails

**Solution**: Ensure you have a C++ compiler

```bash
# Linux (Ubuntu/Debian)
sudo apt-get install build-essential

# macOS
xcode-select --install

# Windows
# Install Rtools from https://cran.r-project.org/bin/windows/Rtools/
```

### Issue 2: Ollama Connection Fails

**Symptoms**: `check_llama_setup()` returns errors

**Solutions**:
```bash
# Check if Ollama is running
ps aux | grep ollama

# Start Ollama service
ollama serve &

# Check connectivity
curl http://localhost:11434/api/tags
```

### Issue 3: Llama 3 Model Not Found

```bash
# Verify model is installed
ollama list

# If not listed, install it
ollama pull llama3

# Check download progress
ollama ps
```

### Issue 4: Memory Issues with Llama 3

If you have limited RAM (< 8GB):

```bash
# Use a smaller model
ollama pull llama3:8b  # 8B parameter version
```

Then in R:
```r
llama <- init_llama(model = "llama3:8b")
```

### Issue 5: R6 Package Missing

```r
# Some older R installations may not have R6
install.packages("R6")

# Verify
library(R6)
```

## Optional Enhancements

### Install Additional SI Methods

```r
# For sl3 (Super Learner)
install.packages("sl3")
install.packages("data.table")

# For causal inference
install.packages("tmle3")
install.packages("ggdag")
```

### Install GUI Dependencies

```r
# For gWidgets GUI
install.packages("gWidgets2")
install.packages("gWidgets2RGtk2")

# For Tcl/Tk GUI (basic)
# Usually pre-installed with R
library(tcltk)
```

## Performance Optimization

### Parallel Processing

```r
# For multi-core Bayesian sampling
library(parallel)
n_cores <- detectCores() - 1
print(paste("Available cores:", n_cores))
```

### GPU Acceleration (Advanced)

If you have NVIDIA GPU:

```bash
# Install CUDA-enabled CmdStan
# See: https://mc-stan.org/docs/cmdstan-guide/parallelization.html
```

## Uninstallation

### Remove R Packages

```r
remove.packages(c("cmdstanr", "posterior", "httr", "jsonlite"))
```

### Remove Ollama

```bash
# Linux
sudo rm -rf /usr/local/bin/ollama
rm -rf ~/.ollama

# macOS
brew uninstall ollama
rm -rf ~/.ollama

# Windows
# Use Windows "Add or Remove Programs"
```

### Remove CmdStan

```r
library(cmdstanr)
uninstall_cmdstan()
```

## Getting Help

- **Documentation**: See `README.md`
- **Examples**: See `examples/` directory
- **Issues**: https://github.com/mahmood726-cyber/surroNMA/issues
- **Discussions**: https://github.com/mahmood726-cyber/surroNMA/discussions

## Next Steps

After successful installation:

1. Read the [Quick Start Guide](README.md#quick-start)
2. Explore the [Examples](examples/)
3. Review the [Vignettes](vignettes/)
4. Join the community discussions

---

**Installation complete! You're ready to use surroNMA v2.0 🎉**
