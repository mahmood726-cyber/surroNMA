# surroNMA v2.0: AI-Enhanced Surrogate Network Meta-Analysis

**Advanced Surrogate NMA with Llama 3 AI Integration, 500+ Rules-Based Validation, and 10,000+ Test Scenarios**

## 🚀 Features

### Core Capabilities
- **Surrogate Endpoint Analysis**: Full Bayesian and frequentist approaches
- **Network Meta-Analysis**: Direct and indirect treatment comparisons
- **Surrogacy Metrics**: STE (Surrogate Threshold Effect), R², α/β parameters
- **Inconsistency Detection**: Node-splitting, design-by-treatment interaction
- **Ranking Methods**: SUCRA, POTH, MID-adjusted preferences

### 🤖 AI-Enhanced Features (NEW in v2.0)
- **Llama 3 Integration**: Local AI via Ollama for intelligent analysis
- **Automated Interpretation**: Clinical and statistical interpretation of results
- **Quality Assessment**: AI-powered risk of bias and quality evaluation
- **Literature Review**: Automated abstract screening and data extraction
- **Report Generation**: Multiple formats (clinical, regulatory, HTA, academic)
- **Surrogate Validation**: Intelligent assessment using Prentice criteria

### ⚖️ Rules-Based Validation (500+ Rules)
1. **Data Quality Rules** (100 rules)
   - Missing data patterns
   - Standard error validation
   - Effect size plausibility
   - Sample size adequacy

2. **Network Structure Rules** (100 rules)
   - Connectivity checks
   - Topology validation
   - Multi-arm trial handling
   - Treatment class hierarchies

3. **Statistical Validity Rules** (100 rules)
   - Assumption checking
   - Convergence diagnostics (MCMC)
   - Prior sensitivity
   - Effect plausibility

4. **Inconsistency Detection Rules** (50 rules)
   - Loop inconsistency
   - Design-by-treatment interaction
   - Global inconsistency tests

5. **Reporting Quality Rules** (50 rules)
   - PRISMA compliance
   - Completeness checks
   - Transparency standards

6. **Clinical Validity Rules** (100 rules)
   - Clinical plausibility
   - Therapeutic context
   - Expert validation

### 🧪 Comprehensive Testing (10,000+ Scenarios)
1. **Basic Network Scenarios** (1000): Various sizes, heterogeneity levels
2. **Inconsistency Scenarios** (1000): Loop patterns, design interactions
3. **Complex Topologies** (1000): Star, mesh, disconnected networks
4. **Edge Cases** (1000): Extreme values, numerical stability
5. **Multivariate Scenarios** (1000): Multiple surrogates, SI methods
6. **Bayesian Scenarios** (1000): Prior sensitivity, MCMC configurations
7. **Frequentist Scenarios** (1000): Bootstrap, weighting schemes
8. **Clinical Applications** (1000): Oncology, cardiology, rare diseases
9. **Regulatory Scenarios** (500): FDA, EMA, HTA requirements
10. **Performance Tests** (1500): Scalability, memory, optimization

## 📦 Installation

```r
# Install dependencies
install.packages(c("R6", "httr", "jsonlite", "Matrix", "MASS"))

# Optional but recommended for full functionality
install.packages(c("posterior", "cmdstanr", "igraph", "ggplot2",
                   "glmnet", "pls", "rmarkdown"))

# For Bayesian analysis
install.packages("cmdstanr", repos = c("https://mc-stan.org/r-packages/",
                                       getOption("repos")))
cmdstanr::install_cmdstan()
```

### Ollama Setup for AI Features

```bash
# 1. Install Ollama
# Visit: https://ollama.ai

# 2. Start Ollama service
ollama serve

# 3. Pull Llama 3 model
ollama pull llama3

# 4. Verify in R
```

```r
source("llama_integration.R")
check_llama_setup()
```

## 🎯 Quick Start

### Basic Analysis

```r
# Source the enhanced package
source("surroNMA")
source("rules_engine.R")
source("scenarios.R")
source("llama_integration.R")
source("ai_enhanced_nma.R")

# Load or simulate data
data <- simulate_surro_data(K = 5, J = 20, alpha = 0.1, beta = 0.8)

# Build network
net <- surro_network(
  data = data,
  study = study,
  trt = trt,
  comp = comp,
  S_eff = logHR_S,
  S_se = se_S,
  T_eff = logHR_T,
  T_se = se_T
)

# Run basic analysis
fit <- surro_nma(net, engine = "bayes")

# Summarize
summary(fit)
```

### AI-Enhanced Analysis

```r
# Initialize Llama 3
llama <- init_llama()

# Run intelligent analysis with full validation
result <- surro_nma_intelligent(
  net,
  engine = "bayes",
  use_ai = TRUE,
  apply_rules = TRUE,
  auto_sensitivity = TRUE,
  llama_conn = llama
)

# View comprehensive results
summary(result)

# Generate detailed report
generate_intelligent_report(
  result,
  format = "html",
  output_file = "nma_report.html"
)
```

### Rules-Based Validation Only

```r
# Create rules engine
rules_engine <- create_complete_rules_system()

# Apply to your network
validation <- apply_rules_to_nma(net)

# Check violations
summary(validation$engine)

# Get specific violations
errors <- validation$engine$get_violations("error")
warnings <- validation$engine$get_violations("warning")
```

### Scenario Testing

```r
# Load scenario library
scenario_db <- create_complete_scenario_library()

# Get specific scenarios
oncology_scenarios <- scenario_db$filter_by_category("clinical")
star_networks <- scenario_db$filter_by_tag("star")

# Run a scenario
scenario <- scenario_db$get_scenario("BN0001")
result <- run_scenario(scenario)

# Batch processing
scenarios_to_run <- scenario_db$filter_by_tag("basic")
results <- run_scenario_batch(scenarios_to_run[1:10])
```

## 🔬 Advanced Methods

### Population Adjustment (Phillippo et al. 2024)

```r
adjusted_fit <- surro_nma_population_adjusted(
  net,
  covariates = c("age", "sex", "baseline_risk"),
  target_population = target_pop_data
)
```

### Component Network Meta-Analysis (Schmitz et al. 2023)

```r
component_fit <- surro_nma_component(
  net,
  component_structure = list(
    drug_class = c("SSRI", "SNRI"),
    dose = c("low", "high")
  )
)
```

### Robust Variance Estimation (Jackson et al. 2024)

```r
robust_fit <- surro_nma_robust(net, robust_se = TRUE)
```

## 📊 AI-Powered Features

### Automated Interpretation

```r
interpretation <- llama_interpret_results(
  fit,
  llama_conn = llama,
  clinical_context = "First-line treatment for major depression"
)

cat(interpretation$interpretation)
```

### Quality Assessment

```r
quality <- llama_assess_quality(net$data, llama)
cat(quality$assessment)
```

### Surrogate Validation

```r
validation <- llama_validate_surrogate(
  fit,
  llama_conn = llama,
  clinical_context = "PFS as surrogate for OS in oncology"
)

cat(validation$validation)
```

### Automated Literature Review

```r
abstracts <- c(
  "Study 1: RCT comparing treatment A vs B...",
  "Study 2: Observational study of treatment C..."
)

screening <- llama_review_literature(abstracts, llama)
```

### Report Generation

```r
# Clinical report
clinical_report <- llama_generate_report(
  fit,
  llama_conn = llama,
  report_type = "clinical"
)

# Regulatory submission
regulatory_report <- llama_generate_report(
  fit,
  llama_conn = llama,
  report_type = "regulatory"
)

# HTA submission
hta_report <- llama_generate_report(
  fit,
  llama_conn = llama,
  report_type = "hta"
)
```

## 📈 Validation and Diagnostics

### Rules Engine

```r
# Check specific rule categories
dq_violations <- rules_engine$filter_violations("data_quality")
ns_violations <- rules_engine$filter_violations("network_structure")

# Custom rules
custom_rule <- Rule(
  id = "CUSTOM001",
  category = "custom",
  description = "Check minimum sample size per arm",
  severity = "warning",
  condition = function(data, ctx) {
    # Your custom logic
    any(data$n < 30)
  },
  action = function(data, ctx) {
    "Sample size < 30 in some arms"
  }
)

rules_engine$add_rule(custom_rule)
```

### Sensitivity Analyses

```r
# Automated sensitivity analyses
sensitivity <- run_automated_sensitivity(fit, net)

# Prior sensitivity (Bayesian)
sensitivity$prior_sensitivity

# Leave-one-out
sensitivity$leave_one_out

# Inconsistency models
sensitivity$inconsistency
```

## 🎨 Visualization

```r
# Surrogacy plot
plot_surrogacy(fit)

# Rankograms
plot_rankogram(fit)

# Network graph
plot_networks(net)

# Rank flip analysis
plot_rank_flip(fit)

# STE distribution
diag <- surrogacy_diagnostics(fit)
plot_ste(diag)
```

## 📚 References

### Implemented Methods
- **Phillippo et al. (2024)** "Population adjustment methods in network meta-analysis" *Statistics in Medicine*
- **Schmitz et al. (2023)** "Component network meta-analysis" *Research Synthesis Methods*
- **Jackson et al. (2024)** "Robust variance estimation for network meta-analysis" *BMJ*
- **Bujkiewicz et al. (2023)** "Multivariate network meta-analysis of multiple outcomes" *Biometrics*
- **Dias et al. (2023)** "Network meta-analysis for decision-making" *Wiley*

### Original surroNMA Methods
- Prentice (1989) "Surrogate endpoints in clinical trials"
- Buyse & Molenberghs (1998) "Criteria for the validation of surrogate endpoints"
- Burzykowski et al. (2005) "The evaluation of surrogate endpoints"

## 🤝 Contributing

The codebase includes:
- `surroNMA`: Core package (1400+ lines, massively improved)
- `rules_engine.R`: 500+ validation rules with R6 engine
- `scenarios.R`: 10,000+ test scenarios across 10 categories
- `llama_integration.R`: Complete Ollama/Llama 3 integration
- `ai_enhanced_nma.R`: Intelligent workflow combining rules + AI

## 🔒 Requirements

### Minimum
- R >= 4.0.0
- R6 >= 2.5.0
- Matrix, MASS (base packages)

### For Bayesian Analysis
- cmdstanr >= 0.5.0
- CmdStan >= 2.30.0
- posterior >= 1.3.0

### For AI Features
- httr >= 1.4.0
- jsonlite >= 1.8.0
- Ollama with Llama 3 model

### Optional
- igraph (network graphs)
- ggplot2 (visualization)
- glmnet (ridge SI)
- pls (PCR SI)
- rmarkdown (reports)

## 💡 Examples

See the `/examples` directory for:
- Oncology case study (PFS → OS)
- Cardiovascular case study (BP → CVD events)
- Rare disease analysis
- Regulatory submission example
- HTA decision model

## 📄 License

See LICENSE file for details.

## 🐛 Issues

Report issues at: https://github.com/mahmood726-cyber/surroNMA/issues

## ✨ Citation

```
@software{surroNMA2024,
  title = {surroNMA v2.0: AI-Enhanced Surrogate Network Meta-Analysis},
  author = {{surroNMA Development Team}},
  year = {2024},
  note = {R package with Llama 3 integration}
}
```

---

**Built with ❤️ combining state-of-the-art statistics and AI**
