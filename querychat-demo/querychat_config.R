# querychat_config.R
# Configuration helper for querychat connection

#' Initialize querychat connection with USDA data
#' 
#' @param fruit_2020_path Path to Fruit-Prices-2020.csv
#' @param fruit_2022_path Path to Fruit-Prices-2022.csv
#' @param veg_2022_path Path to Vegetable-Prices-2022.csv
#' @param api_key Optional API key for querychat (if required)
#' @return A querychat connection object
setup_querychat_connection <- function(
    fruit_2020_path = "~/usda_fruit_veg_data/Fruit-Prices-2020.csv",
    fruit_2022_path = "~/usda_fruit_veg_data/Fruit-Prices-2022.csv",
    veg_2020_path = "~/usda_fruit_veg_data/Vegetable-Prices-2020.csv",
    veg_2022_path = "~/usda_fruit_veg_data/Vegetable-Prices-2022.csv",
    api_key = NULL
) {
  
  # Load datasets
  fruit_2020 <- read.csv(fruit_2020_path) %>%
    mutate(Year = 2020, DataType = "Fruit")
  
  fruit_2022 <- read.csv(fruit_2022_path) %>%
    mutate(Year = 2022, DataType = "Fruit")
  
  veg_2020 <- read.csv(veg_2020_path) %>%
    mutate(Year = 2020, DataType = "Vegetable")
  
  veg_2022 <- read.csv(veg_2022_path) %>%
    mutate(Year = 2022, DataType = "Vegetable")
  
  # Initialize querychat connection
  # NOTE: Adjust this based on actual querychat package API
  if (!is.null(api_key)) {
    conn <- querychat::connect(api_key = api_key)
  } else {
    conn <- querychat::connect()
  }
  
  # Register tables with descriptive names
  querychat::register_dataframe(
    conn, 
    fruit_2020, 
    table_name = "fruit_2020",
    description = "Fruit prices from 2020, includes retail prices, yields, and cup equivalent pricing"
  )
  
  querychat::register_dataframe(
    conn, 
    fruit_2022, 
    table_name = "fruit_2022",
    description = "Fruit prices from 2022, includes retail prices, yields, and cup equivalent pricing"
  )
  
  querychat::register_dataframe(
    conn, 
    veg_2020, 
    table_name = "veg_2020",
    description = "Vegetable prices from 2020, includes retail prices, yields, and cup equivalent pricing"
  )
  
  querychat::register_dataframe(
    conn, 
    veg_2022, 
    table_name = "veg_2022",
    description = "Vegetable prices from 2022, includes retail prices, yields, and cup equivalent pricing"
  )
  
  # Optional: Create a combined view
  all_produce <- bind_rows(
    fruit_2020,
    fruit_2022,
    veg_2020,
    veg_2022
  ) %>%
    mutate(
      ItemName = coalesce(Fruit, Vegetable),
      .keep = "unused"
    )
  
  querychat::register_dataframe(
    conn,
    all_produce,
    table_name = "all_produce",
    description = "Combined view of all fruits and vegetables across all years"
  )
  
  # Set context for the AI assistant
  context <- "
  You have access to USDA fruit and vegetable price datasets spanning 2020-2022.
  
  Available tables:
  - fruit_2020: Fruit prices from 2020
  - fruit_2022: Fruit prices from 2022
  - veg_2020: Vegetable prices from 2020
  - veg_2022: Vegetable prices from 2022
  - all_produce: Combined view of all data
  
  Column descriptions:
  - Fruit/Vegetable: Name of the produce item
  - Form: How the item is sold (Fresh, Canned, Frozen, Juice, Dried)
  - RetailPrice: Price at retail
  - RetailPriceUnit: Unit for retail price (typically 'per pound')
  - Yield: Proportion that is edible after preparation (0-1)
  - CupEquivalentSize: Amount needed for one cup equivalent serving
  - CupEquivalentUnit: Unit for cup equivalent
  - CupEquivalentPrice: Price per cup equivalent serving
  - Year: Year of the data
  - DataType: 'Fruit' or 'Vegetable'
  
  When answering questions:
  - Use CupEquivalentPrice for the most accurate price comparisons
  - Consider the Form when comparing items
  - Yield indicates how much is edible/usable
  - Be specific about years when relevant
  "
  
  querychat::set_context(conn, context)
  
  return(conn)
}

#' Execute a natural language query
#' 
#' @param conn querychat connection object
#' @param query Natural language query
#' @param return_code Whether to return the generated SQL/R code
#' @return List with response, data, and optionally code
execute_query <- function(conn, query, return_code = TRUE) {
  result <- querychat::query(
    conn,
    query = query,
    return_code = return_code,
    execute = TRUE,
    max_rows = 1000
  )
  
  return(result)
}

#' Clean and format query results for display
#' 
#' @param data Data frame from query results
#' @return Formatted data frame
format_results <- function(data) {
  if (is.null(data) || nrow(data) == 0) {
    return(data)
  }
  
  # Round numeric columns to 2 decimal places
  numeric_cols <- sapply(data, is.numeric)
  data[numeric_cols] <- lapply(data[numeric_cols], round, 2)
  
  # Format price columns as currency
  price_cols <- grep("price|Price", names(data), ignore.case = TRUE)
  for (col in price_cols) {
    if (is.numeric(data[[col]])) {
      data[[col]] <- sprintf("$%.2f", data[[col]])
    }
  }
  
  return(data)
}

#' Generate example queries based on the data
#' 
#' @return Character vector of example queries
get_example_queries <- function() {
  c(
    "What are the top 10 most expensive fruits by cup equivalent price in 2022?",
    "Compare the average price of fresh vs canned vegetables",
    "Show me all apple products and their prices across all forms",
    "Which produce items have a yield below 0.5?",
    "What's the price range for fresh fruits in 2022?",
    "List all vegetables available in multiple forms",
    "What's the cheapest way to buy one cup of each type of produce?",
    "How do 2020 fruit prices compare to 2022 prices?",
    "Which form (Fresh, Canned, Frozen) typically costs the most?",
    "Show me produce items where the retail price differs significantly from cup equivalent price",
    "What's the average yield by produce form?",
    "Which fruits and vegetables cost less than $1 per cup equivalent?",
    "Compare asparagus prices across different forms",
    "What's the total number of unique produce items in the dataset?",
    "Show the price distribution of all fresh produce"
  )
}