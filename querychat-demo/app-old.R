library(shiny)
library(bslib)
library(querychat)
library(dplyr)

# Load data (replace with your actual CSV files)
produce_data <- tryCatch({
  fruit_2020 <- read.csv("~/usda_fruit_veg_data/Fruit-Prices-2020.csv") %>% mutate(Year = 2020)
  fruit_2022 <- read.csv("~/usda_fruit_veg_data/Fruit-Prices-2022.csv") %>% mutate(Year = 2022)
  veg_2020 <- read.csv("~/usda_fruit_veg_data/Vegetable-Prices-2020.csv") %>% mutate(Year = 2020)
  veg_2022 <- read.csv("~/usda_fruit_veg_data/Vegetable-Prices-2022.csv") %>% mutate(Year = 2022)
  
  bind_rows(fruit_2020, fruit_2022, veg_2020, veg_2022) %>%
    mutate(Item = coalesce(Fruit, Vegetable)) %>%
    select(-Fruit, -Vegetable) %>%
    select(Item, everything())
}, error = function(e) {
  # Sample data if CSV files not found
  data.frame(
    Item = c("Apples", "Bananas", "Carrots"),
    Form = c("Fresh", "Fresh", "Fresh"),
    RetailPrice = c(1.85, 0.62, 1.10),
    CupEquivalentPrice = c(0.50, 0.29, 0.36),
    Year = c(2022, 2022, 2022)
  )
})


Sys.setenv(ANTHROPIC_API_KEY="")
# Configure querychat
querychat_config <- querychat_init(
  data = produce_data,
  greeting = "Ask me questions about USDA fruit and vegetable prices!",
  create_chat_func = purrr::partial(ellmer::chat_anthropic, model = "claude-3-7-sonnet-latest"),
  #create_chat_func = purrr::partial(ellmer::chat_aws_bedrock, model = "us.anthropic.claude-sonnet-4-20250514-v1:0"),
  data_description = "
  - Item: Fruit or vegetable name
  - Form: Fresh, Canned, Frozen, Juice, or Dried
  - RetailPrice: Price per pound
  - CupEquivalentPrice: Price per cup serving (best for comparisons)
  - Year: 2020 or 2022
  "
)

# UI
ui <- page_sidebar(
  title = "USDA Produce Prices",
  sidebar = querychat_sidebar("chat"),
  DT::DTOutput("dt")
)

# Server
server <- function(input, output, session) {
  querychat <- querychat_server("chat", querychat_config)
  
  output$dt <- DT::renderDT({
    DT::datatable(querychat$df())
  })
}

shinyApp(ui, server)