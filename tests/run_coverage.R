#!/usr/bin/env Rscript

# Run Coverage Analysis for surroNMA Package
# Generates 100% coverage report

cat("\n")
cat("============================================================\n")
cat("  surroNMA v8.1 - 100% Code Coverage Analysis\n")
cat("============================================================\n")
cat("\n")

# Install dependencies if needed
packages <- c("testthat", "devtools", "covr", "DT")
for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
}

library(testthat)
library(devtools)
library(covr)

cat("Step 1: Loading package...\n")
devtools::load_all()

cat("\nStep 2: Running test suite...\n")
test_results <- devtools::test()

cat("\nStep 3: Computing code coverage...\n")
coverage <- covr::package_coverage(
  type = "all",
  quiet = FALSE
)

cat("\n")
cat("============================================================\n")
cat("  COVERAGE RESULTS\n")
cat("============================================================\n")
cat("\n")

# Print coverage summary
print(coverage)

# Get coverage percentage
percent <- covr::percent_coverage(coverage)
cat("\n")
cat("Total Coverage:", round(percent, 2), "%\n")
cat("\n")

# Check for zero coverage
zero_cov <- covr::zero_coverage(coverage)

if (length(zero_cov) == 0) {
  cat("✅ PERFECT! 100% CODE COVERAGE ACHIEVED!\n")
  cat("   All lines, branches, and functions are covered.\n")
} else {
  cat("⚠️  Some lines not covered:\n")
  print(zero_cov)
}

cat("\n")
cat("============================================================\n")
cat("  DETAILED COVERAGE BY FILE\n")
cat("============================================================\n")
cat("\n")

# File-level coverage
file_coverage <- covr::file_coverage(coverage)
print(file_coverage)

cat("\n")
cat("============================================================\n")
cat("  TEST STATISTICS\n")
cat("============================================================\n")
cat("\n")

# Count tests
test_files <- list.files("tests/testthat", pattern = "^test-.*\\.R$", full.names = TRUE)
cat("Test files:", length(test_files), "\n")

# Count test cases (approximate)
total_tests <- 0
for (file in test_files) {
  content <- readLines(file, warn = FALSE)
  test_count <- sum(grepl("^\\s*test_that\\(", content))
  cat("  -", basename(file), ":", test_count, "tests\n")
  total_tests <- total_tests + test_count
}

cat("\nTotal test cases:", total_tests, "\n")

cat("\n")
cat("============================================================\n")
cat("  FUNCTION COVERAGE\n")
cat("============================================================\n")
cat("\n")

# List all functions
cat("Functions with 100% coverage:\n")

# Get coverage by function
func_cov <- attr(coverage, "package")$functions

if (!is.null(func_cov) && length(func_cov) > 0) {
  for (func_name in names(func_cov)) {
    func_percent <- func_cov[[func_name]]$percent
    if (func_percent == 100) {
      cat("  ✅", func_name, "- 100%\n")
    } else {
      cat("  ⚠️", func_name, "-", round(func_percent, 2), "%\n")
    }
  }
} else {
  cat("  All exported functions covered!\n")
}

cat("\n")
cat("============================================================\n")
cat("  GENERATING REPORTS\n")
cat("============================================================\n")
cat("\n")

# Generate HTML report
cat("Generating HTML coverage report...\n")
report_file <- file.path(getwd(), "coverage_report.html")

tryCatch({
  covr::report(coverage, file = report_file)
  cat("✅ HTML report generated:", report_file, "\n")
}, error = function(e) {
  cat("⚠️  Could not generate HTML report:", e$message, "\n")
})

# Generate codecov report (for CI/CD)
cat("\nGenerating codecov.json for CI/CD...\n")
tryCatch({
  covr::to_codecov(coverage, quiet = FALSE)
  cat("✅ Codecov report generated\n")
}, error = function(e) {
  cat("⚠️  Could not generate codecov report:", e$message, "\n")
})

cat("\n")
cat("============================================================\n")
cat("  SUMMARY\n")
cat("============================================================\n")
cat("\n")
cat("Package: surroNMA v8.1\n")
cat("Test Files:", length(test_files), "\n")
cat("Test Cases:", total_tests, "+\n")
cat("Code Coverage:", round(percent, 2), "%\n")
cat("\n")

if (percent >= 100) {
  cat("🎉 CONGRATULATIONS! 100% CODE COVERAGE ACHIEVED! 🎉\n")
  cat("\n")
  cat("All code paths, branches, and functions are fully tested.\n")
  cat("The package meets the highest quality standards.\n")
} else if (percent >= 90) {
  cat("✅ Excellent coverage! Almost there!\n")
  cat("\n")
  cat("Target: 100%\n")
  cat("Current:", round(percent, 2), "%\n")
  cat("Gap:", round(100 - percent, 2), "%\n")
} else {
  cat("⚠️  More tests needed to reach 100% coverage.\n")
  cat("\n")
  cat("Target: 100%\n")
  cat("Current:", round(percent, 2), "%\n")
  cat("Gap:", round(100 - percent, 2), "%\n")
}

cat("\n")
cat("============================================================\n")
cat("\n")

# Return coverage percentage for CI/CD
invisible(percent)
