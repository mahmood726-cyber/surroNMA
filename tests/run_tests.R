#!/usr/bin/env Rscript
# Standalone test runner for surroNMA.
#
# The statistical core lives in the single file `surroNMA` (no .R extension and
# not an installed package), so we source it into a dedicated environment and
# run the testthat suite against that environment. No package install required.
#
# Usage (from repo root or anywhere):
#   Rscript tests/run_tests.R
# Exit status is non-zero if any test fails.

suppressMessages(library(testthat))

# Locate this script so paths work regardless of the caller's working dir.
args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grep("^--file=", args)])
here <- if (length(file_arg)) dirname(normalizePath(file_arg)) else getwd()
repo <- normalizePath(file.path(here, ".."))

core <- file.path(repo, "surroNMA")
if (!file.exists(core)) stop("Cannot find surroNMA core at: ", core)

env <- new.env(parent = globalenv())
source(core, local = env)

test_path <- file.path(repo, "tests", "testthat", "test-surroNMA.R")
res <- test_file(test_path, env = env, reporter = "summary")

df <- as.data.frame(res)
passed  <- sum(df$passed)
failed  <- sum(df$failed)
warned  <- sum(df$warning)
cat(sprintf("\nRESULT: passed=%d failed=%d warnings=%d\n", passed, failed, warned))
if (failed > 0) quit(status = 1, save = "no")
