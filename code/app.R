#!/usr/bin/env Rscript
library(shiny)
library(DBI)
library(odbc)

ui <- fluidPage(
  
  # App title ----
  titlePanel("Enter Table Name"),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      # Input: Select the random distribution type ----
      p("Enter the name of your table:"),
      textInput("ID1", "Table Name:", "<DB.TableName>"),
      actionButton("goButton", "Run Analytic Functions!")
    ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      
      # Output: Tabset w/ plot, summary, and table ----
      tabsetPanel(type = "tabs",
                  tabPanel("Moments Table", tableOutput("moments_tbl")),
                  tabPanel("Basic Table", tableOutput("basic_tbl")),
                  tabPanel("Quantiles Table", tableOutput("quantiles_tbl"))
                  )
    )
  )
)

server <- function(input, output, session) {
#  output$tbl <- renderTable({
    # This makes the code in this block run when someone clicks the go button. 
    
    moments_table_reactive <- eventReactive(input$goButton, {

      cat("inside moments table eventReactive\n")
      load("./data/credentials/conn.RDS")
    on.exit(dbDisconnect(conn), add = TRUE)

    cat("Successfully made DB connection\n")
    
    # Run the univariatestatistics function on the input table when user clicks GO!
    
    query <- paste("SELECT * 
    FROM UnivariateStatistics (
    ON", input$ID1,"AS InputTable
    OUT TABLE MomentsTableName (scratch.moments) 
    OUT TABLE BasicTableName (scratch.basic) 
    OUT TABLE QuantilesTableName (scratch.quantiles) 
    ) AS t
    ;", sep=" ")

    # Note that sqlInterpolate doesn't work in Postgresql with passing table names
    # because it single quotes the table name which doesn't work
    #query <- sqlInterpolate(conn, sql, id1 = input$ID1)
    
    cat("Running query: ", query, "\n")
    
    dbGetQuery(conn, "drop table scratch.moments")
    dbGetQuery(conn, "drop table scratch.basic")
    dbGetQuery(conn, "drop table scratch.quantiles")
    
    result_of_univariate <- dbGetQuery(conn, query)
        
    cat("finished univariatestats: ", str(result_of_univariate), "\n")
    
    # Now get moments table...
    
    sql <- "SELECT * FROM scratch.moments;"
    
    dbGetQuery(conn, sql)
    
  })

    
  basic_table_reactive <- eventReactive(input$goButton, {   
    cat("inside basic_table_reactive ", "function")
    load("./data/credentials/conn.RDS")
    on.exit(dbDisconnect(conn), add = TRUE)
    
    sql <- "SELECT * FROM scratch.basic;"
    dbGetQuery(conn, sql) 
  })

  quantiles_table_reactive <- eventReactive(input$goButton, {   
    cat("inside quantiles_table_reactive ", "function")
    load("./data/credentials/conn.RDS")
    on.exit(dbDisconnect(conn), add = TRUE)
    
    sql <- "SELECT * FROM scratch.quantiles;"
    dbGetQuery(conn, sql) 
  })
      
  output$moments_tbl <- renderTable({ moments_table_reactive() })
  output$basic_tbl <- renderTable({ basic_table_reactive() })
  output$quantiles_tbl <- renderTable({ quantiles_table_reactive() })
    
}

shinyApp(ui, server)