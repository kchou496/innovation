# USDA Fruit & Vegetable Prices QueryChat Shiny App

This R Shiny application demonstrates how to use `querychat` with USDA fruit and vegetable pricing datasets to create an interactive data exploration interface.

## Features

- **Natural Language Querying**: Ask questions about fruit and vegetable prices in plain English
- **Multiple Datasets**: Incorporates Fruit prices (2020, 2022) and Vegetable prices (2022)
- **Interactive Tabs**:
  - Chat Response: See the AI-generated answer and SQL/R code
  - Data Table: View query results in a sortable, filterable table
  - Visualization: Auto-generated plots when applicable
  - Data Preview: Browse the raw datasets

## Requirements

### R Packages

```r
install.packages(c(
  "shiny",
  "dplyr",
  "ggplot2",
  "DT"
))

# Install querychat (adjust based on actual installation method)
# If from CRAN:
install.packages("querychat")

# If from GitHub:
# remotes::install_github("organization/querychat")
```

## Setup

1. **Place your CSV files in the same directory as app.R**:
   - `Fruit-Prices-2020.csv`
   - `Fruit-Prices-2022.csv`
   - `Vegetable-Prices-2022.csv`
   - `Vegetable-Prices-2022.csv`

2. **Update the data loading section** in `app.R`:

Replace the reactive data loading functions with actual CSV reads:

```r
fruit_2020 <- reactive({
  read.csv("Fruit-Prices-2020.csv") %>%
    mutate(Year = 2020)
})

fruit_2022 <- reactive({
  read.csv("Fruit-Prices-2022.csv") %>%
    mutate(Year = 2022)
})

veg_2022 <- reactive({
  read.csv("Vegetable-Prices-2022.csv") %>%
    mutate(Year = 2022)
})
```

3. **Configure querychat** based on your specific implementation:

The current code uses placeholder functions. Update these based on your actual querychat API:

```r
# Example - adjust to your querychat implementation
qc_connection <- reactive({
  conn <- querychat::querychat_connect(
    api_key = Sys.getenv("QUERYCHAT_API_KEY"),  # if needed
    # other configuration...
  )
  
  # Register your tables
  querychat::register_dataframe(conn, fruit_2020(), "fruit_2020")
  querychat::register_dataframe(conn, fruit_2022(), "fruit_2022")
  querychat::register_dataframe(conn, veg_2022(), "veg_2022")
  
  return(conn)
})
```

## Running the App

### From RStudio
1. Open `app.R` in RStudio
2. Click the "Run App" button

### From R Console
```r
library(shiny)
runApp("path/to/app.R")
```

### From Command Line
```bash
R -e "shiny::runApp('app.R')"
```

## Example Queries

Try these natural language queries:

- "What are the top 5 most expensive fruits in 2022?"
- "Compare fresh vs canned vegetable prices"
- "Show me all apple products and their prices"
- "What's the average cup equivalent price by form?"
- "Which vegetables have the highest yield?"
- "List all produce items under $1 per cup equivalent"
- "What's the price difference between fresh and canned asparagus?"

## Data Schema

### Fruit Prices Tables
- `Fruit`: Name of the fruit/product
- `Form`: Fresh, Canned, Juice, Frozen, Dried
- `RetailPrice`: Price value
- `RetailPriceUnit`: Unit for retail price (usually "per pound")
- `Yield`: Edible portion after preparation
- `CupEquivalentSize`: Amount needed for one cup equivalent
- `CupEquivalentUnit`: Unit for cup equivalent
- `CupEquivalentPrice`: Price per cup equivalent
- `Year`: Year of the data (added)

### Vegetable Prices Tables
- `Vegetable`: Name of the vegetable/product
- `Form`: Fresh, Canned, Frozen
- `RetailPrice`: Price value
- `RetailPriceUnit`: Unit for retail price
- `Yield`: Edible portion after preparation
- `CupEquivalentSize`: Amount needed for one cup equivalent
- `CupEquivalentUnit`: Unit for cup equivalent
- `CupEquivalentPrice`: Price per cup equivalent
- `Year`: Year of the data (added)

## Customization

### Adding More Datasets
To add more years or types of data:

```r
# Add to the reactive section
new_dataset <- reactive({
  read.csv("New-Dataset.csv")
})

# Register with querychat
querychat_register_table(conn, "new_dataset", new_dataset())
```

### Styling
Modify the UI to customize appearance:

```r
ui <- fluidPage(
  theme = bslib::bs_theme(bootswatch = "flatly"),  # Add theme
  # ... rest of UI
)
```

### Custom Visualizations
Enhance the plotting logic in the `observeEvent(input$submit, {...})` section to create more sophisticated visualizations based on your query results.

## Troubleshooting

### Common Issues

1. **querychat not found**: Ensure the package is properly installed
2. **API Key errors**: Set your API key if required: `Sys.setenv(QUERYCHAT_API_KEY = "your-key")`
3. **Data not loading**: Verify CSV file paths and column names match exactly
4. **Connection errors**: Check querychat documentation for proper connection setup

## Notes

- This is a template application. The actual querychat API calls may differ based on the specific implementation of the package.
- The sample includes mock data for demonstration. Replace with actual CSV loading for production use.
- Consider adding error handling and input validation for production deployments.

## License

This is a sample application for demonstration purposes.