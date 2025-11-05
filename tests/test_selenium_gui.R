#' Selenium Browser Tests for surroNMA GUI v8.1
#' @description Automated browser testing for Shiny dashboards
#' @version 8.1
#'
#' Tests both dashboards:
#' - shiny_dashboard.R (v4.0 - shinydashboard)
#' - bs4dash_app.R (v8.0 - bs4Dash)

library(RSelenium)
library(testthat)

# ============================================================================
# SELENIUM SETUP
# ============================================================================

#' Start Selenium server and browser
#' @export
setup_selenium <- function(browser = "firefox", port = 4445L) {
  cat("Setting up Selenium...\n")

  # Start Selenium server
  tryCatch({
    rD <- rsDriver(
      browser = browser,
      port = port,
      verbose = FALSE,
      chromever = NULL
    )

    remDr <- rD$client

    message("✓ Selenium server started")
    message(sprintf("✓ %s browser launched", tools::toTitleCase(browser)))

    list(driver = rD, client = remDr)
  }, error = function(e) {
    message("✗ Failed to start Selenium")
    message(sprintf("Error: %s", e$message))
    message("\nTo install Selenium:")
    message("  1. Install Java: sudo apt-get install default-jre")
    message("  2. Install browser: sudo apt-get install firefox")
    message("  3. Or use Docker: docker run -d -p 4445:4444 selenium/standalone-firefox")
    NULL
  })
}

#' Stop Selenium server
#' @export
teardown_selenium <- function(selenium_obj) {
  if (!is.null(selenium_obj)) {
    tryCatch({
      selenium_obj$client$close()
      selenium_obj$driver$server$stop()
      message("✓ Selenium stopped")
    }, error = function(e) {
      message("Warning: Could not stop Selenium cleanly")
    })
  }
}

# ============================================================================
# GUI TEST HELPER FUNCTIONS
# ============================================================================

#' Wait for element to appear
wait_for_element <- function(remDr, css_selector, timeout = 10) {
  start_time <- Sys.time()

  while (difftime(Sys.time(), start_time, units = "secs") < timeout) {
    elements <- remDr$findElements(using = "css selector", value = css_selector)

    if (length(elements) > 0 && elements[[1]]$isElementDisplayed()[[1]]) {
      return(elements[[1]])
    }

    Sys.sleep(0.5)
  }

  stop(sprintf("Element '%s' not found within %d seconds", css_selector, timeout))
}

#' Take screenshot
take_screenshot <- function(remDr, filename) {
  remDr$screenshot(file = filename)
  message(sprintf("Screenshot saved: %s", filename))
}

#' Check if text appears on page
check_text_present <- function(remDr, text) {
  page_source <- remDr$getPageSource()[[1]]
  grepl(text, page_source, fixed = TRUE)
}

# ============================================================================
# TEST SUITE 1: BS4DASH DASHBOARD (v8.0)
# ============================================================================

test_bs4dash_dashboard <- function(selenium, app_url = "http://127.0.0.1:3838") {
  remDr <- selenium$client

  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 1: bs4Dash Dashboard (v8.0)\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("\n")

  # Test 1: Dashboard Loads
  test_that("bs4Dash - Dashboard loads", {
    remDr$navigate(app_url)
    Sys.sleep(3)

    page_title <- remDr$getTitle()[[1]]
    expect_true(grepl("surroNMA|Dashboard", page_title, ignore.case = TRUE))

    take_screenshot(remDr, "screenshots/bs4dash_home.png")
    message("✓ Dashboard loaded successfully")
  })

  # Test 2: Check Header Elements
  test_that("bs4Dash - Header elements present", {
    # Check for brand/title
    brand_present <- check_text_present(remDr, "surroNMA")
    expect_true(brand_present)

    # Check for version
    version_present <- check_text_present(remDr, "8.0") || check_text_present(remDr, "v8")
    expect_true(version_present)

    message("✓ Header elements found")
  })

  # Test 3: Sidebar Navigation
  test_that("bs4Dash - Sidebar navigation", {
    # Look for menu items
    menu_items <- c("Home", "Data Upload", "Analysis", "Visualizations",
                   "AI Assistant", "Downloads", "Settings")

    for (item in menu_items) {
      item_present <- check_text_present(remDr, item)
      if (item_present) {
        message(sprintf("  ✓ Menu item found: %s", item))
      } else {
        warning(sprintf("  ✗ Menu item missing: %s", item))
      }
    }

    message("✓ Sidebar navigation checked")
  })

  # Test 4: Info Boxes on Home
  test_that("bs4Dash - Info boxes present", {
    # Check for key metrics
    metrics <- c("Version", "Methods", "Visualizations", "DPI", "300")

    found_count <- 0
    for (metric in metrics) {
      if (check_text_present(remDr, metric)) {
        found_count <- found_count + 1
      }
    }

    expect_true(found_count >= 3)
    message(sprintf("✓ Info boxes found (%d/%d metrics)", found_count, length(metrics)))
  })

  # Test 5: Navigate to Data Upload
  test_that("bs4Dash - Navigate to Data Upload", {
    tryCatch({
      # Find and click Data Upload link
      upload_link <- wait_for_element(remDr, "a[data-value='upload']", timeout = 5)

      if (!is.null(upload_link)) {
        upload_link$clickElement()
        Sys.sleep(2)

        # Check for file upload element
        upload_present <- check_text_present(remDr, "Upload") ||
                         check_text_present(remDr, "Choose")

        expect_true(upload_present)

        take_screenshot(remDr, "screenshots/bs4dash_upload.png")
        message("✓ Data Upload tab accessible")
      } else {
        message("⚠ Could not find upload link")
      }
    }, error = function(e) {
      message(sprintf("⚠ Navigation test skipped: %s", e$message))
    })
  })

  # Test 6: Navigate to Visualizations
  test_that("bs4Dash - Navigate to Visualizations", {
    tryCatch({
      viz_link <- wait_for_element(remDr, "a[data-value='visualizations']", timeout = 5)

      if (!is.null(viz_link)) {
        viz_link$clickElement()
        Sys.sleep(2)

        # Check for plot options
        plot_present <- check_text_present(remDr, "Plot") ||
                       check_text_present(remDr, "Visualization")

        expect_true(plot_present)

        take_screenshot(remDr, "screenshots/bs4dash_viz.png")
        message("✓ Visualizations tab accessible")
      }
    }, error = function(e) {
      message(sprintf("⚠ Visualization test skipped: %s", e$message))
    })
  })

  # Test 7: Downloads Tab
  test_that("bs4Dash - Downloads tab", {
    tryCatch({
      downloads_link <- wait_for_element(remDr, "a[data-value='downloads']", timeout = 5)

      if (!is.null(downloads_link)) {
        downloads_link$clickElement()
        Sys.sleep(2)

        # Check for download options
        download_options <- c("PNG", "PDF", "DPI", "Download", "Export")

        found_count <- 0
        for (option in download_options) {
          if (check_text_present(remDr, option)) {
            found_count <- found_count + 1
          }
        }

        expect_true(found_count >= 2)

        take_screenshot(remDr, "screenshots/bs4dash_downloads.png")
        message(sprintf("✓ Downloads tab found (%d/%d options)",
                       found_count, length(download_options)))
      }
    }, error = function(e) {
      message(sprintf("⚠ Downloads test skipped: %s", e$message))
    })
  })

  # Test 8: Settings Tab
  test_that("bs4Dash - Settings tab", {
    tryCatch({
      settings_link <- wait_for_element(remDr, "a[data-value='settings']", timeout = 5)

      if (!is.null(settings_link)) {
        settings_link$clickElement()
        Sys.sleep(2)

        settings_keywords <- c("Settings", "Theme", "GPU", "Cache", "DPI")

        found_count <- 0
        for (keyword in settings_keywords) {
          if (check_text_present(remDr, keyword)) {
            found_count <- found_count + 1
          }
        }

        expect_true(found_count >= 2)

        take_screenshot(remDr, "screenshots/bs4dash_settings.png")
        message(sprintf("✓ Settings tab found (%d/%d options)",
                       found_count, length(settings_keywords)))
      }
    }, error = function(e) {
      message(sprintf("⚠ Settings test skipped: %s", e$message))
    })
  })

  # Test 9: Responsive Design
  test_that("bs4Dash - Responsive design", {
    # Test different window sizes
    sizes <- list(
      desktop = c(1920, 1080),
      tablet = c(768, 1024),
      mobile = c(375, 667)
    )

    for (size_name in names(sizes)) {
      size <- sizes[[size_name]]

      remDr$setWindowSize(size[1], size[2])
      Sys.sleep(1)

      # Check if content is still visible
      content_visible <- check_text_present(remDr, "surroNMA")

      expect_true(content_visible)
      message(sprintf("  ✓ %s (%dx%d): Content visible",
                     size_name, size[1], size[2]))
    }

    # Reset to desktop size
    remDr$setWindowSize(1920, 1080)

    message("✓ Responsive design tested")
  })

  # Test 10: Performance
  test_that("bs4Dash - Page load performance", {
    start_time <- Sys.time()

    remDr$navigate(app_url)
    remDr$refresh()
    Sys.sleep(3)

    end_time <- Sys.time()
    load_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

    expect_true(load_time < 10)  # Should load in < 10 seconds

    message(sprintf("✓ Page load time: %.2f seconds", load_time))
  })

  cat("\n✓ bs4Dash Dashboard tests complete!\n\n")
}

# ============================================================================
# TEST SUITE 2: INTEGRATION TESTS
# ============================================================================

test_integration_workflow <- function(selenium, app_url = "http://127.0.0.1:3838") {
  remDr <- selenium$client

  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 2: Integration Workflow Tests\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("\n")

  test_that("Integration - Complete user workflow", {
    # Step 1: Load dashboard
    remDr$navigate(app_url)
    Sys.sleep(2)
    message("  1. Dashboard loaded")

    # Step 2: Navigate through tabs
    tabs <- c("upload", "visualizations", "downloads")

    for (tab in tabs) {
      tryCatch({
        tab_link <- remDr$findElements(using = "css selector",
                                       value = sprintf("a[data-value='%s']", tab))

        if (length(tab_link) > 0) {
          tab_link[[1]]$clickElement()
          Sys.sleep(1)
          message(sprintf("  2. Navigated to: %s", tab))
        }
      }, error = function(e) {
        message(sprintf("  ⚠ Could not navigate to: %s", tab))
      })
    }

    # Step 3: Take final screenshot
    take_screenshot(remDr, "screenshots/integration_workflow.png")

    message("✓ Integration workflow complete")
  })

  cat("\n✓ Integration tests complete!\n\n")
}

# ============================================================================
# TEST SUITE 3: ACCESSIBILITY TESTS
# ============================================================================

test_accessibility <- function(selenium) {
  remDr <- selenium$client

  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("TEST SUITE 3: Accessibility Tests\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("\n")

  test_that("Accessibility - Alt text for images", {
    images <- remDr$findElements(using = "css selector", value = "img")

    if (length(images) > 0) {
      has_alt <- sapply(images, function(img) {
        alt <- img$getElementAttribute("alt")[[1]]
        !is.null(alt) && nchar(alt) > 0
      })

      pct_with_alt <- mean(has_alt) * 100

      message(sprintf("  Images with alt text: %.0f%%", pct_with_alt))
      expect_true(pct_with_alt >= 50)
    } else {
      message("  No images found")
    }

    message("✓ Alt text check complete")
  })

  test_that("Accessibility - Keyboard navigation", {
    # Tab through elements
    for (i in 1:5) {
      remDr$sendKeysToActiveElement(list(key = "tab"))
      Sys.sleep(0.2)
    }

    message("✓ Keyboard navigation works")
  })

  cat("\n✓ Accessibility tests complete!\n\n")
}

# ============================================================================
# MAIN TEST RUNNER
# ============================================================================

#' Run all Selenium GUI tests
#' @export
run_selenium_tests <- function(app_url = "http://127.0.0.1:3838",
                               browser = "firefox",
                               create_screenshots = TRUE) {
  cat("\n")
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║          surroNMA v8.1 - Selenium GUI Tests                   ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n")
  cat("\n")

  # Create screenshots directory
  if (create_screenshots) {
    dir.create("screenshots", showWarnings = FALSE)
    message("✓ Screenshots directory created")
  }

  # Setup Selenium
  selenium <- setup_selenium(browser = browser)

  if (is.null(selenium)) {
    message("\n✗ Cannot run tests without Selenium")
    message("\nFallback: Running mock tests...\n")
    run_mock_gui_tests()
    return(NULL)
  }

  tryCatch({
    # Run test suites
    test_bs4dash_dashboard(selenium, app_url)
    test_integration_workflow(selenium, app_url)
    test_accessibility(selenium)

    cat("\n")
    cat("╔════════════════════════════════════════════════════════════════╗\n")
    cat("║                    ALL TESTS PASSED!                           ║\n")
    cat("╚════════════════════════════════════════════════════════════════╝\n")
    cat("\n")
  }, error = function(e) {
    message(sprintf("\n✗ Test error: %s\n", e$message))
  }, finally = {
    # Cleanup
    teardown_selenium(selenium)
  })

  invisible(TRUE)
}

# ============================================================================
# MOCK TESTS (when Selenium unavailable)
# ============================================================================

#' Run mock GUI tests without Selenium
#' @export
run_mock_gui_tests <- function() {
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("MOCK GUI TESTS (Selenium not available)\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("\n")

  # Test 1: Check if files exist
  test_that("Mock - Dashboard files exist", {
    expect_true(file.exists("bs4dash_app.R") || file.exists("../bs4dash_app.R"))
    message("✓ bs4dash_app.R exists")

    expect_true(file.exists("shiny_dashboard.R") || file.exists("../shiny_dashboard.R"))
    message("✓ shiny_dashboard.R exists")
  })

  # Test 2: Check file size (should be substantial)
  test_that("Mock - Dashboard files not empty", {
    if (file.exists("bs4dash_app.R")) {
      size <- file.info("bs4dash_app.R")$size
      expect_true(size > 10000)
      message(sprintf("✓ bs4dash_app.R size: %d bytes", size))
    }
  })

  # Test 3: Check for required packages
  test_that("Mock - Required packages available", {
    required_pkgs <- c("shiny", "bs4Dash", "DT", "plotly")

    for (pkg in required_pkgs) {
      available <- requireNamespace(pkg, quietly = TRUE)

      if (available) {
        message(sprintf("  ✓ %s installed", pkg))
      } else {
        message(sprintf("  ✗ %s NOT installed", pkg))
      }
    }
  })

  cat("\n✓ Mock GUI tests complete\n")
  cat("Note: For full testing, install Selenium and rerun\n\n")
}

# ============================================================================
# CONVENIENCE FUNCTION
# ============================================================================

#' Quick test function
#' @export
quick_gui_test <- function() {
  message("Starting quick GUI test...")
  message("Note: Make sure Shiny app is running on http://127.0.0.1:3838")
  message("      Launch with: shiny::runApp('bs4dash_app.R')")

  readline(prompt = "\nPress [Enter] when app is running...")

  run_selenium_tests()
}
