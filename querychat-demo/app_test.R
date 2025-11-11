library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(plotly)
library(reactable)
library(querychat)

# Load data
fruit_2020 <- read.csv("~/usda_fruit_veg_data/Fruit-Prices-2020.csv")
fruit_2022 <- read.csv("~/usda_fruit_veg_data/Fruit-Prices-2022.csv")
veg_2020 <- read.csv("~/usda_fruit_veg_data/Vegetable-Prices-2020.csv")
veg_2022 <- read.csv("~/usda_fruit_veg_data/Vegetable-Prices-2022.csv")

# Combine all data
fruit_data <- bind_rows(fruit_2020, fruit_2022) %>%
  mutate(Category = "Fruit")

veg_data <- bind_rows(veg_2020, veg_2022) %>%
  rename(Vegetable = Vegetable) %>%
  rename(Fruit = Vegetable) %>%
  mutate(Category = "Vegetable")

all_data <- bind_rows(fruit_data, veg_data)

# Configure querychat with stream = FALSE
querychat_config <- querychat_init(
  data = all_data,
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
  title = "USDA Produce Prices Dashboard",
  theme = bs_theme(preset = "bootstrap"),
  
  sidebar = sidebar(
    width = 400,
    
    # Filters
    card(
      card_header("Filters"),
      selectInput("category", "Category:", 
                  choices = c("All", "Fruit", "Vegetable"),
                  selected = "All"),
      selectInput("year", "Year:",
                  choices = c("All", "2020", "2022"),
                  selected = "All"),
      selectInput("form", "Form:",
                  choices = c("All", sort(unique(all_data$Form))),
                  selected = "All")
    ),
    
    # Querychat component
    card(
      card_header("AI Chat Assistant"),
      querychat_ui("chat")
    )
  ),
  
  # Main content
  layout_columns(
    col_widths = c(12, 6, 6),
    
    # Summary cards
    card(
      card_header("Quick Stats"),
      layout_columns(
        col_widths = c(3, 3, 3, 3),
        value_box(
          title = "Total Items",
          value = textOutput("total_items"),
          showcase = bsicons::bs_icon("basket"),
          theme = "primary"
        ),
        value_box(
          title = "Avg Retail Price",
          value = textOutput("avg_price"),
          showcase = bsicons::bs_icon("currency-dollar"),
          theme = "success"
        ),
        value_box(
          title = "Avg Cup Equiv Price",
          value = textOutput("avg_cup_price"),
          showcase = bsicons::bs_icon("cup-straw"),
          theme = "info"
        ),
        value_box(
          title = "Avg Yield",
          value = textOutput("avg_yield"),
          showcase = bsicons::bs_icon("graph-up-arrow"),
          theme = "warning"
        )
      )
    ),
    
    # Price comparison chart
    card(
      card_header("Retail Price Distribution"),
      plotlyOutput("price_distribution", height = "400px")
    ),
    
    # Top 10 most expensive
    card(
      card_header("Most Expensive Items (by Cup Equivalent)"),
      plotlyOutput("top_expensive", height = "400px")
    ),
    
    # Data table
    card(
      full_screen = TRUE,
      card_header("Data Table"),
      reactableOutput("data_table")
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Filtered data
  filtered_data <- reactive({
    data <- all_data
    
    if (input$category != "All") {
      data <- data %>% filter(Category == input$category)
    }
    
    if (input$year != "All") {
      data <- data %>% filter(Year == as.numeric(input$year))
    }
    
    if (input$form != "All") {
      data <- data %>% filter(Form == input$form)
    }
    
    data
  })
  
  # Querychat server
  querychat_server(
    "chat",
    querychat_config
  )
  
  # Summary statistics
  output$total_items <- renderText({
    nrow(filtered_data())
  })
  
  output$avg_price <- renderText({
    paste0("$", round(mean(filtered_data()$RetailPrice, na.rm = TRUE), 2))
  })
  
  output$avg_cup_price <- renderText({
    paste0("$", round(mean(filtered_data()$CupEquivalentPrice, na.rm = TRUE), 2))
  })
  
  output$avg_yield <- renderText({
    paste0(round(mean(filtered_data()$Yield, na.rm = TRUE) * 100, 1), "%")
  })
  
  # Price distribution plot
  output$price_distribution <- renderPlotly({
    p <- ggplot(filtered_data(), aes(x = RetailPrice, fill = Category)) +
      geom_histogram(bins = 30, alpha = 0.7, position = "identity") +
      labs(
        title = "Distribution of Retail Prices",
        x = "Retail Price ($/lb or $/pint)",
        y = "Count"
      ) +
      theme_minimal() +
      scale_fill_manual(values = c("Fruit" = "#E69F00", "Vegetable" = "#009E73"))
    
    ggplotly(p)
  })
  
  # Top expensive items
  output$top_expensive <- renderPlotly({
    top_data <- filtered_data() %>%
      arrange(desc(CupEquivalentPrice)) %>%
      head(10) %>%
      mutate(Label = paste(Fruit, Form, sep = " - "))
    
    p <- ggplot(top_data, aes(x = reorder(Label, CupEquivalentPrice), 
                              y = CupEquivalentPrice, 
                              fill = Category)) +
      geom_col() +
      coord_flip() +
      labs(
        title = "Top 10 Most Expensive (Cup Equivalent)",
        x = "",
        y = "Cup Equivalent Price ($)"
      ) +
      theme_minimal() +
      scale_fill_manual(values = c("Fruit" = "#E69F00", "Vegetable" = "#009E73"))
    
    ggplotly(p)
  })
  
  # Data table
  output$data_table <- renderReactable({
    reactable(
      filtered_data() %>%
        select(Fruit, Category, Form, Year, RetailPrice, 
               RetailPriceUnit, Yield, CupEquivalentPrice),
      searchable = TRUE,
      filterable = TRUE,
      striped = TRUE,
      highlight = TRUE,
      bordered = TRUE,
      defaultPageSize = 15,
      columns = list(
        Fruit = colDef(name = "Item", minWidth = 120),
        Category = colDef(name = "Category", maxWidth = 100),
        Form = colDef(name = "Form", maxWidth = 150),
        Year = colDef(name = "Year", maxWidth = 80),
        RetailPrice = colDef(
          name = "Retail Price",
          format = colFormat(prefix = "$", digits = 2)
        ),
        RetailPriceUnit = colDef(name = "Unit", maxWidth = 120),
        Yield = colDef(
          name = "Yield",
          format = colFormat(percent = TRUE, digits = 0)
        ),
        CupEquivalentPrice = colDef(
          name = "Cup Equiv Price",
          format = colFormat(prefix = "$", digits = 2)
        )
      )
    )
  })
}

# Run the app
shinyApp(ui = ui, server = server)