# surroNMA v8.0 - Modern bs4Dash GUI Guide

## 🎨 Beautiful Bootstrap 4 Dashboard with HD Downloads

surroNMA now features a **state-of-the-art bs4Dash** (Bootstrap 4 Dashboard) interface with **high-resolution download handlers** for publication-quality exports.

---

## 🚀 Quick Start

### Installation

```r
# Install required packages
install.packages(c(
  "shiny",
  "bs4Dash",
  "shinyjs",
  "DT",
  "plotly",
  "htmlwidgets",
  "shinycssloaders",
  "shinyWidgets",
  "waiter"
))

# Install surroNMA
devtools::install_github("mahmood726-cyber/surroNMA")
```

### Launch Dashboard

```r
# Method 1: Direct launch
library(surroNMA)
shiny::runApp("bs4dash_app.R")

# Method 2: From R console
source("bs4dash_app.R")

# Method 3: RStudio
# Open bs4dash_app.R and click "Run App"
```

The dashboard will open in your default browser at `http://127.0.0.1:XXXX`

---

## 📊 Dashboard Features

### 1. **Home Tab**
- Quick stats overview (Version, Methods, Visualizations, Export Quality)
- Welcome message with v8.0 features
- Quick action buttons
- System status

### 2. **Data Upload Tab**
- **File Upload**: CSV, Excel (.xlsx, .xls)
- **Paste Data**: Tab-delimited text
- **Data Preview**: Interactive table
- **Variable Mapping**: Select study, treatment, effect, SE columns
- **Create Network**: One-click network creation

### 3. **Analysis Tabs**

#### Standard NMA
- Bayesian or Frequentist engine
- MCMC settings (iterations, chains)
- GPU acceleration toggle
- Redis caching toggle
- Real-time results

#### Component NMA
- JSON component definition
- Interaction effects
- Component contribution plots
- Component rankings

#### BART NMA
- Tree settings (50-500 trees)
- Burn-in configuration
- Variable importance
- Partial dependence plots
- Heterogeneous treatment effects

#### IPD NMA
- One-stage, two-stage, or mixed methods
- Individual predictions
- Subgroup analysis

#### Multivariate NMA
- Multiple outcomes
- Correlation estimation
- Joint rankings

### 4. **Visualizations Tab**

**25+ Plot Types**:
- Network Plot
- Forest Plot
- Rankogram
- Funnel Plot
- League Table
- Contribution Matrix
- 3D Network
- Component Plots
- BART Partial Dependence
- Spline Curves
- And more...

**Customization**:
- Width: 6-20 inches
- Height: 4-16 inches
- DPI: 72-600 (default: 300)
- Quality indicator

### 5. **AI Assistant Tab**
- **Real-time Chat**: Natural language queries
- **Quick Actions**:
  - Suggest Analysis
  - Interpret Results
  - Write Methods Section
  - Generate Report
- **AI Status**: Model info, GPU status

### 6. **Downloads Tab** ⭐

#### Individual Plot Downloads
- **Formats**:
  - PNG (High-Res): 72-600 DPI
  - PDF (Vector): Scalable
  - SVG (Vector): Web-friendly
  - TIFF (Print): LZW compression
  - EPS (Publication): Standard format
- **Custom Dimensions**: 4-24 inches
- **Resolution Control**: Up to 600 DPI

#### Batch Downloads
- Download all plots as ZIP
- Maintains high resolution
- Organized file naming

#### Reports
- **Formats**: PDF, HTML, DOCX, LaTeX
- **Customizable Sections**:
  - Summary Statistics
  - Network Characteristics
  - Treatment Effects
  - Rankings
  - Heterogeneity
  - Inconsistency
  - All Visualizations
  - Methods Description
  - References

#### Data Exports
- Results CSV
- Results Excel
- R Workspace (.RData)

#### Download History
- Track all downloads
- Timestamp, format, resolution

### 7. **Settings Tab**
- **Theme**: Light/Dark mode
- **Performance**: GPU, Cache, Workers
- **Export Defaults**: DPI, Format
- **AI Settings**: Model, Temperature
- **Advanced**: Upload limits

---

## 📥 High-Resolution Download Guide

### Recommended Settings

| Use Case | DPI | Width | Height | Format |
|----------|-----|-------|--------|--------|
| **Journal Publication** | 300-600 | 8-12 | 6-8 | TIFF or PDF |
| **Poster Presentation** | 300 | 16-20 | 12-16 | PNG or PDF |
| **Slides (PowerPoint)** | 150 | 10 | 6 | PNG |
| **Web/Blog** | 72-150 | 8 | 6 | PNG or SVG |
| **Print (High Quality)** | 300-600 | 10 | 8 | TIFF |
| **Vector Graphics** | N/A | 8 | 6 | PDF or SVG |

### Quality Guidelines

- **Publication Quality**: 300+ DPI
  - Suitable for: Journals, books, high-quality prints
  - File size: Large (5-20 MB per plot)

- **High Quality**: 150-299 DPI
  - Suitable for: Presentations, posters, reports
  - File size: Medium (1-5 MB per plot)

- **Screen Quality**: 72-149 DPI
  - Suitable for: Web, slides, quick review
  - File size: Small (<1 MB per plot)

### Format Recommendations

#### PNG (Raster)
- **Pros**: Universal support, good compression
- **Cons**: Not scalable
- **Best for**: Digital use, presentations
- **DPI**: 150-300

#### PDF (Vector)
- **Pros**: Scalable, professional, text searchable
- **Cons**: Larger file size
- **Best for**: Publications, LaTeX documents
- **DPI**: N/A (vector)

#### SVG (Vector)
- **Pros**: Scalable, web-friendly, editable
- **Cons**: Limited software support
- **Best for**: Web graphics, further editing
- **DPI**: N/A (vector)

#### TIFF (Raster)
- **Pros**: Lossless, high quality, print standard
- **Cons**: Very large files
- **Best for**: Print publications, archival
- **DPI**: 300-600

#### EPS (Vector)
- **Pros**: Publication standard, widely accepted
- **Cons**: Older format
- **Best for**: Journal submissions requiring EPS
- **DPI**: N/A (vector)

---

## 🎨 UI Components

### Modern Design Elements

1. **Info Boxes**: Key metrics at a glance
2. **Gradient Cards**: Beautiful status displays
3. **Maximizable Plots**: Full-screen visualization
4. **Collapsible Sections**: Clean interface
5. **Loading Spinners**: Professional animations
6. **Waiter Screens**: Smooth transitions
7. **Quality Badges**: "HD Exports", "300+ DPI"
8. **Responsive Layout**: Mobile-friendly

### Interactive Features

- **Datatables**: Sortable, filterable, searchable
- **Plotly Graphs**: Zoom, pan, hover tooltips
- **Dropdown Menus**: Notifications, messages
- **Controlbar**: Quick export, help
- **User Card**: Profile information
- **Footer**: Version info, credits

---

## 💡 Usage Examples

### Example 1: Export Forest Plot for Journal

```r
# 1. Run analysis
# 2. Go to "Downloads" tab
# 3. Select "Forest Plot"
# 4. Choose format: "TIFF (Print)"
# 5. Set dimensions: Width = 10, Height = 8
# 6. Set DPI: 300
# 7. Click "Download Plot"

# Result: forest_plot_2025-01-15.tiff (300 DPI, publication-ready)
```

### Example 2: Create Complete Report

```r
# 1. Complete your analysis
# 2. Go to "Downloads" tab
# 3. Select report sections:
#    ☑ Summary Statistics
#    ☑ Treatment Effects
#    ☑ All Visualizations
#    ☑ Methods Description
# 4. Choose format: "PDF (Publication)"
# 5. Click "Generate & Download Report"

# Result: surroNMA_report_2025-01-15.pdf (complete analysis report)
```

### Example 3: Batch Export All Plots

```r
# 1. Run multiple analyses
# 2. Go to "Downloads" tab
# 3. Set default DPI: 300
# 4. Click "Download All Plots (ZIP)"

# Result: surroNMA_all_plots_2025-01-15.zip
# Contains: network_300DPI.png, forest_300DPI.png, rankogram_300DPI.png, etc.
```

### Example 4: Ask AI to Interpret Results

```r
# 1. Go to "AI Assistant" tab
# 2. Type: "What are the main findings from this analysis?"
# 3. Click "Send"
# 4. AI provides interpretation
# 5. Ask follow-up: "Which treatment should we recommend?"
```

---

## ⚙️ Configuration

### Default Settings

Edit in `Settings` tab or modify code:

```r
# Default DPI
default_dpi = 300

# Default dimensions
default_width = 12  # inches
default_height = 8  # inches

# Default format
default_format = "PNG"

# Theme
theme_mode = "light"  # or "dark"

# Performance
enable_gpu = TRUE
enable_cache = TRUE
parallel_workers = 4
```

### Custom Themes

The dashboard supports custom theming through bs4Dash:

```r
# In ui definition
ui <- dashboardPage(
  dark = TRUE,  # Enable dark mode
  ...
)
```

---

## 🔧 Advanced Features

### 1. Programmatic Export

```r
# Export specific plot with R code
ggsave("my_plot.png",
       plot = my_plot,
       width = 12,
       height = 8,
       dpi = 300,
       device = "png",
       type = "cairo")
```

### 2. Custom Download Handlers

The app includes custom download handlers that ensure:
- Cairo rendering for anti-aliasing
- LZW compression for TIFF
- Proper color profiles
- Correct aspect ratios

### 3. Batch Processing

```r
# Download all plots in one click
# Automatically creates ZIP with:
# - Consistent naming
# - Same resolution across all
# - Organized structure
```

---

## 📱 Mobile Support

The dashboard is **fully responsive** and works on:
- Desktop (optimal)
- Tablets (good)
- Mobile phones (limited)

For best experience, use desktop with screen resolution ≥1920×1080.

---

## 🐛 Troubleshooting

### Issue: Plots not downloading

**Solution**: Check file permissions, ensure enough disk space

### Issue: Low resolution exports

**Solution**: Increase DPI in download settings (300+ recommended)

### Issue: Large file sizes

**Solution**:
- Use PDF/SVG for vector graphics
- Reduce DPI for digital use (150 DPI)
- Use PNG compression

### Issue: AI not responding

**Solution**:
1. Check if Ollama is running: `ollama serve`
2. Verify model is installed: `ollama pull llama3`
3. Check AI settings in Settings tab

---

## 📚 Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + S` | Open Settings |
| `Ctrl/Cmd + D` | Open Downloads |
| `Ctrl/Cmd + H` | Open Help |
| `Esc` | Close sidebar |

---

## 🎓 Video Tutorials

*Coming soon:*
- Getting Started with bs4Dash GUI
- High-Resolution Export Workflow
- AI-Assisted Analysis
- Creating Publication-Ready Figures

---

## 💬 Support

- **GitHub Issues**: https://github.com/mahmood726-cyber/surroNMA/issues
- **Documentation**: https://mahmood726-cyber.github.io/surroNMA
- **Email**: support@surronma.org

---

## 📝 Changelog

### v8.0 (2025-01-15)
- ✅ Upgraded to bs4Dash (Bootstrap 4)
- ✅ High-resolution download handlers (up to 600 DPI)
- ✅ Multiple export formats (PNG, PDF, SVG, TIFF, EPS)
- ✅ Batch download all plots
- ✅ Publication-ready reports
- ✅ Download history tracking
- ✅ Modern responsive design
- ✅ AI chat assistant
- ✅ Quick export from controlbar

---

**surroNMA bs4Dash GUI** - *Publication-quality exports with a beautiful interface* 🎨📊
