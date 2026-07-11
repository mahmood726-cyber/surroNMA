# Regression + smoke tests for the surroNMA frequentist core.
# The core is sourced into the test env by tests/run_tests.R (env=) so all
# exported functions (surro_network, surro_nma_freq, sucra, poth, ...) are visible.

make_net <- function(seed = 1, n = 8, miss = integer(0), se_T = 0.15) {
  set.seed(seed)
  trts <- rep(c("B", "C", "D", "E"), length.out = n)
  df <- data.frame(
    study = seq_len(n),
    trt   = trts,
    comp  = rep("A", n),
    logHR_S = stats::rnorm(n, -0.4, 0.3),
    se_S    = rep(0.1, n),
    logHR_T = stats::rnorm(n, -0.35, 0.3),
    se_T    = rep(se_T, n),
    class   = rep("C1", n)
  )
  if (length(miss)) {
    df$logHR_T[miss] <- NA
    df$se_T[miss]    <- NA
  }
  surro_network(df, study = study, trt = trt, comp = comp,
                S_eff = logHR_S, S_se = se_S, T_eff = logHR_T, T_se = se_T,
                class = class, check_connectivity = FALSE)
}

test_that("core sources and the frequentist engine runs end-to-end (all T observed)", {
  net <- make_net(seed = 1)
  fit <- surro_nma_freq(net, B = 100, seed = 1)
  expect_equal(fit$engine, "freq")
  expect_length(fit$sucra, net$K)
  expect_true(all(is.finite(fit$sucra)))
  expect_true(all(fit$sucra >= 0 & fit$sucra <= 1))
  expect_true(is.finite(fit$poth))
})

test_that("F3 regression: partially-observed T no longer misaligns / crashes", {
  # Before the fix this raised 'incompatible dimensions' from deming()/cov().
  net <- make_net(seed = 2, n = 8, miss = c(2, 5))
  expect_true(sum(is.finite(net$T_eff)) < length(net$T_eff))  # genuinely partial
  fit <- suppressWarnings(surro_nma_freq(net, B = 100, seed = 1))
  expect_equal(fit$engine, "freq")
  expect_true(all(is.finite(fit$deming)))
  expect_true(all(is.finite(fit$sucra)))
})

test_that("F3: predicted surrogate/true contrasts align with observed T rows", {
  # Deming slope must recover a known linear T = 0.9*S relationship even with
  # a missing T row placed in the interior (mis-indexing would corrupt it).
  df <- data.frame(
    study = 1:5, trt = c("B","C","D","E","B"), comp = rep("A",5),
    logHR_S = c(-0.5, -0.3, -0.8, -0.2, -0.6), se_S = rep(0.05,5),
    logHR_T = c(-0.45, NA, -0.72, -0.18, -0.54), se_T = c(0.05, NA, 0.05, 0.05, 0.05),
    class = rep("C1",5)
  )
  net <- surro_network(df, study=study, trt=trt, comp=comp,
                       S_eff=logHR_S, S_se=se_S, T_eff=logHR_T, T_se=se_T,
                       class=class, check_connectivity=FALSE)
  fit <- suppressWarnings(surro_nma_freq(net, B = 50, seed = 3))
  expect_gt(fit$deming["beta"], 0.6)
  expect_lt(fit$deming["beta"], 1.2)
})

test_that("F4 regression: frequentist STE uncertainty is data-driven, not hardcoded 0.2", {
  # Structured data where T ~ 0.9*S so the Deming slope is well-identified and
  # its bootstrap SD responds monotonically to the stated T-precision.
  mk <- function(se_T) {
    df <- data.frame(
      study = 1:8, trt = c("B","C","D","E","B","C","D","E"), comp = rep("A",8),
      logHR_S = c(-0.5,-0.3,-0.8,-0.2,-0.55,-0.28,-0.82,-0.18), se_S = rep(0.1,8),
      logHR_T = c(-0.4,-0.25,-0.7,-0.15,-0.42,-0.24,-0.68,-0.16), se_T = rep(se_T,8),
      class = rep("C1",8))
    net <- surro_network(df, study=study, trt=trt, comp=comp,
                         S_eff=logHR_S, S_se=se_S, T_eff=logHR_T, T_se=se_T,
                         class=class, check_connectivity=FALSE)
    surro_nma_freq(net, B = 800, seed = 1)
  }
  fit_lo <- mk(0.05); fit_hi <- mk(0.30)
  expect_false(is.null(fit_lo$deming_draws))
  sd_lo <- stats::sd(fit_lo$deming_draws[, "beta"], na.rm = TRUE)
  sd_hi <- stats::sd(fit_hi$deming_draws[, "beta"], na.rm = TRUE)
  # Noisier true-effect data must yield wider slope uncertainty.
  expect_gt(sd_hi, sd_lo)
  # And neither is the old fabricated constant 0.2.
  expect_false(isTRUE(all.equal(sd_lo, 0.2, tolerance = 1e-6)))
  dg <- surrogacy_diagnostics(fit_hi)
  expect_true(is.finite(dg$beta["q025"]) && is.finite(dg$beta["q975"]))
  expect_lt(dg$beta["q025"], dg$beta["q975"])
})

test_that("F6 regression: single-treatment network is rejected, not silently NaN", {
  df <- data.frame(study = 1:3, trt = rep("A",3), comp = rep("A",3),
                   logHR_S = c(-0.1,-0.2,-0.15), se_S = rep(0.1,3),
                   logHR_T = c(-0.1,-0.2,-0.15), se_T = rep(0.15,3),
                   class = rep("C1",3))
  expect_error(
    surro_network(df, study=study, trt=trt, comp=comp,
                  S_eff=logHR_S, S_se=se_S, T_eff=logHR_T, T_se=se_T,
                  class=class, check_connectivity=FALSE),
    regexp = "2 distinct treatments"
  )
})

test_that("K=2 is the smallest valid network and works", {
  df <- data.frame(study = 1:4, trt = rep("B",4), comp = rep("A",4),
                   logHR_S = c(-0.4,-0.5,-0.45,-0.55), se_S = rep(0.1,4),
                   logHR_T = c(-0.35,-0.45,-0.4,-0.5), se_T = rep(0.15,4),
                   class = rep("C1",4))
  net <- surro_network(df, study=study, trt=trt, comp=comp,
                       S_eff=logHR_S, S_se=se_S, T_eff=logHR_T, T_se=se_T,
                       class=class, check_connectivity=FALSE)
  expect_equal(net$K, 2)
  fit <- suppressWarnings(surro_nma_freq(net, B = 50, seed = 1))
  expect_length(fit$sucra, 2)
})

test_that("sucra/poth ranking helpers are internally consistent", {
  # Treatment that is always ranked 1 (best) must have SUCRA 1; always-last -> 0.
  ranks <- matrix(c(1, 2, 3), nrow = 10, ncol = 3, byrow = TRUE)
  s <- sucra(ranks)
  expect_equal(unname(s[1]), 1)
  expect_equal(unname(s[3]), 0)
  expect_true(all(s >= 0 & s <= 1))
  # POTH of a perfectly stable hierarchy is 1 (no rank disagreement).
  expect_equal(poth(ranks), 1)
})

test_that("compute_STE returns paired-draw summary", {
  set.seed(1)
  a <- stats::rnorm(1000, 0.1, 0.05)
  b <- stats::rnorm(1000, 0.8, 0.1)
  ste <- compute_STE(a, b, threshold_T = 0)
  expect_true(is.finite(ste$summary["mean"]))
  expect_length(ste$ste, 1000)
})

test_that("simulate_surro_data feeds the freq engine (integration)", {
  df <- simulate_surro_data(K = 5, J = 20, per_study = 1, seed = 1)
  net <- surro_network(df, study = study, trt = trt, comp = comp,
                       S_eff = logHR_S, S_se = se_S, T_eff = logHR_T, T_se = se_T,
                       class = class, check_connectivity = FALSE)
  fit <- suppressWarnings(surro_nma_freq(net, B = 100, seed = 1))
  expect_equal(length(fit$sucra), net$K)
  expect_true(all(is.finite(fit$sucra)))
})
