# surroNMA Test Suite

## Quick Start

### Unit Tests
```r
source("tests/test_unit_tests.R")
run_all_unit_tests()
```

### GUI Tests (requires Selenium)
```r
# Start app first
shiny::runApp("bs4dash_app.R", port = 3838)

# Then in another session
source("tests/test_selenium_gui.R")
run_selenium_tests()
```

### Mock Tests (no Selenium needed)
```r
source("tests/test_selenium_gui.R")
run_mock_gui_tests()
```

## Test Coverage

- **Unit Tests**: 26 tests across 5 suites
- **GUI Tests**: 16 tests across 3 suites
- **Total**: 42 comprehensive tests
- **Code Coverage**: ~89% of critical functions

## Files

- `test_unit_tests.R` - Unit testing suite (588 lines)
- `test_selenium_gui.R` - Browser automation tests (530 lines)

## Full Documentation

See `../TEST_REPORT.md` for comprehensive testing documentation.
