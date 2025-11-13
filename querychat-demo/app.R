library(shiny)
library(bslib)
library(querychat)
library(dplyr)
library(ellmer)
library(plotly)

# Load data
fruit_2020 <- read.csv("~/innovation/querychat-demo/usda_fruit_veg_data/Fruit-Prices-2020.csv") %>% 
  mutate(Year = 2020, Category = "Fruit")
fruit_2022 <- read.csv("~/innovation/querychat-demo/usda_fruit_veg_data/Fruit-Prices-2022.csv") %>% 
  mutate(Year = 2022, Category = "Fruit")
veg_2020 <- read.csv("~/innovation/querychat-demo/usda_fruit_veg_data/Vegetable-Prices-2020.csv") %>% 
  mutate(Year = 2020, Category = "Vegetable")
veg_2022 <- read.csv("~/innovation/querychat-demo/usda_fruit_veg_data/Vegetable-Prices-2022.csv") %>% 
  mutate(Year = 2022, Category = "Vegetable")

produce_data <- bind_rows(fruit_2020, fruit_2022, veg_2020, veg_2022) %>%
  mutate(Item = coalesce(Fruit, Vegetable)) %>%
  select(-Fruit, -Vegetable) %>%
  select(Item, Category, everything())

# Configure querychat
querychat_config <- querychat_init(
  data = produce_data,
  greeting = "Ask me questions about USDA fruit and vegetable prices!",
  create_chat_func = function(system_prompt = NULL) {
    chat_aws_bedrock(
      model = "us.anthropic.claude-sonnet-4-20250514-v1:0",
      system_prompt = system_prompt
    )
  },
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
  card(
    card_header(
      "Fruit & Vegetable Price Table"
    ),
    DT::DTOutput("produce_dt")
  ),
  card(
    card_header(
      "Plot"
    ),
    plotlyOutput("produce_plot")
  )
)

# Server
server <- function(input, output, session) {
  querychat <- querychat_server("chat", querychat_config)
  
  output$produce_dt <- DT::renderDT({
    DT::datatable(
      querychat$df(),
      filter = 'top',
      options = list(
        autoWidth = FALSE
      )
    )
  })
  
  output$produce_plot <- renderPlotly({
    p <- ggplot(querychat$df(), aes(x = RetailPrice, y = CupEquivalentPrice, 
                                    color = Category, text = Item)) +
      geom_point(alpha = 0.6, size = 3) +
      geom_smooth(method = "lm", se = TRUE, alpha = 0.2) +
      scale_color_manual(values = c("Fruit" = "#E69F00", "Vegetable" = "#009E73")) +
      labs(
        title = "Retail Price vs Cup Equivalent Price",
        x = "Retail Price (per pound)",
        y = "Cup Equivalent Price ($)"
      ) +
      theme_minimal()
    
    ggplotly(p, tooltip = c("text", "x", "y"))
  })

}
shinyApp(ui, server)