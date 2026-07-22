library(shiny)
library(shinydashboard)
library(DT)
library(ggplot2)

# Source backend functions
source("modules/backend.R")
source("modules/run_optm.R")
source("modules/run_update.R")

options(shiny.maxRequestSize = 100*1024^2)  # allow up to 100 MB

library(readr)
library(readxl)

read_any <- function(path) {
  ext <- tools::file_ext(path)
  switch(tolower(ext),
         "csv"  = read_csv(path),
         "txt"  = read_delim(path, delim = "\t"),
         "tsv"  = read_tsv(path),
         "xls"  = read_excel(path),
         "xlsx" = read_excel(path),
         "xlsb" = read_excel(path),  # requires additional support packages
         # default fallback
         read_csv(path)
  )
}

# ---- UI ----
ui <- dashboardPage(
  dashboardHeader(title = "OptmWiz"),

  dashboardSidebar(
    sidebarMenu(
      id = "sidebar",   # <-- add this
      menuItem("Upload Data", tabName = "upload", icon = icon("upload")),
      menuItem("Data Preview", tabName = "preview", icon = icon("table")),
      menuItem("Exploratory Analysis", tabName = "eda", icon = icon("search")),
      menuItem("Optimization", tabName = "results", icon = icon("cogs")),
      menuItem("Visualization", tabName = "viz", icon = icon("chart-bar")),
      menuItem("Update Database", tabName = "update", icon = icon("database")),
      menuItem("Feedback Style", tabName = "feedback", icon = icon("cogs"),
               radioButtons("feedback_style", "Choose feedback style:",
                            choices = c("Notification", "Progress Bar"),
                            selected = "Notification"))
    )
  ),

  dashboardBody(
    tabItems(
      # Upload tab
      tabItem(tabName = "upload",
              fluidRow(
                box(title = "Upload & Parameters", width = 6, status = "primary",
                    actionButton("loadDemo", "Use Demo Data", icon = icon("play")),
                    br(), br(),
                    fileInput("input_file", "Optional: Upload Order CSV", accept = ".csv"),
                    numericInput("mat_markup", "Material Markup (%)", value = 18, min = 0, max = 100),
                    numericInput("lab_markup", "Labour Markup (%)", value = 10, min = 0, max = 100),
                    selectInput("order_type", "Order Type",
                                choices = c("Straight haul" = 1, "Back haul" = 2, "Dirt deal" = 3)),
                    actionButton("run_btn", "Run Optimization", icon = icon("play"))
                )
              )
      ),

      # Preview tab
      tabItem(tabName = "preview",
              fluidRow(
                box(title = "Data Preview", width = 12, status = "info",
                    DTOutput("dataPreview"))
              )
      ),

      # EDA tab
      # EDA tab
      tabItem(tabName = "eda",
              fluidRow(
                box(title = "Summary Statistics", width = 12, status = "primary",
                    DTOutput("summaryStats")   # <-- changed from verbatimTextOutput
                )
              ),
              fluidRow(
                box(title = "Variable Distribution", width = 12, status = "info",
                    selectInput("eda_var", "Select variable:", choices = NULL),
                    plotOutput("eda_plot", height = "400px")
                )
              )
      ),

      # Optimization tab
      tabItem(tabName = "results",
              fluidRow(
                box(title = "Optimization Results Table", width = 12, status = "success",
                    DTOutput("results_table"))
              )
      ),

      # Visualization tab
      # Visualization tab
      tabItem(tabName = "viz",
              fluidRow(
                box(title = "Revenue Visualization", width = 12, status = "warning",
                    selectInput("viz_group", "Group by:",
                                choices = c("Order Number" = "ord_num",
                                            "Job Number"   = "job_num",
                                            "Customer"     = "cust_num"),
                                selected = "ord_num"),
                    plotOutput("results_plot", height = "500px"))
              )
      ),

      # Update tab
      tabItem(tabName = "update",
              fluidRow(
                box(title = "Database Update", width = 12, status = "danger",
                    actionButton("update_btn", "Run Update", icon = icon("sync")),
                    verbatimTextOutput("update_status"))
              )
      )
    )
  )
)



# ---- SERVER ----
server <- function(input, output, session) {

  active_data <- reactiveVal(NULL)

  # Demo data
  observeEvent(input$loadDemo, {
    demo_path <- file.path("data", "Sample OrderList.csv")
    demo_data <- read_any(demo_path)
    active_data(demo_data)
    showNotification("Demo dataset loaded successfully!", type = "message")
  })

  # Upload data
  observeEvent(input$input_file, {
    req(input$input_file)
    user_data <- read_any(input$input_file$datapath)
    active_data(user_data)
    showNotification("User dataset uploaded successfully!", type = "message")
  })

  # Core optimization routine (callable from button or tab)
  run_optm_reactive <- reactive({
    df <- active_data()
    req(df, nrow(df) > 0)

    tmpfile <- tempfile(fileext = ".csv")
    write.csv(df, tmpfile, row.names = FALSE)

    # run optimization
    if (input$feedback_style == "Notification") {
      showNotification("Running optimization...", type = "message", duration = NULL, id = "optm")
      run_optimization(
        input_file  = tmpfile,
        output_file = "Optm_df",
        order_type  = as.numeric(input$order_type),
        mat_markup  = input$mat_markup / 100,
        lab_markup  = input$lab_markup / 100
      )
      removeNotification("optm")
      showNotification("Optimization completed!", type = "message")
    } else {
      withProgress(message = "Running optimization...", value = 0, {
        incProgress(0.3, detail = "Normalizing data")
        df <- normalise_Function(df)
        incProgress(1, detail = "Applying markups")
        run_optm(tmpfile, "Optm_df", as.numeric(input$order_type),
                 input$mat_markup/100, input$lab_markup/100)
      })
    }

    optm_res <- read.csv("./results/Optm_df.csv")

    # Attach identifiers only once, and only if they are not already present
    id_cols <- c("ord_num","job_num","cust_num")
    missing_ids <- setdiff(id_cols, names(optm_res))
    if(all(id_cols %in% names(df)) && length(missing_ids) > 0) {
      optm_res <- cbind(df[,missing_ids, drop=FALSE], optm_res)
    }

    # Ensure unique column names
    names(optm_res) <- make.unique(names(optm_res))

    optm_res

  })


  # Results reactive value
  results <- reactiveVal(NULL)

  # Run when button clicked
  observeEvent(input$run_btn, {
    results(run_optm_reactive())
    updateTabItems(session, "sidebar", "results")  # <-- switch to Optimization tab
  })

  # Run when Optimization tab selected directly
  observeEvent(input$sidebar, {
    if (input$sidebar == "results") {
      results(run_optm_reactive())
    }
  })

  # Preview
  output$dataPreview <- renderDT({
    req(active_data())
    DT::datatable(
      as.data.frame(active_data()),   # ensures tabular display
      options = list(pageLength = 5, scrollX = TRUE),
      rownames = FALSE
    )
  })


  # Optimization results table
  output$results_table <- renderDT({
    req(results())
    DT::datatable(
      as.data.frame(results()),
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    ) %>%
      DT::formatStyle(
        "ord_expected",
        target = "row",
        backgroundColor = DT::styleEqual(
          c("Accepted", "Rejected"),
          c("lightgreen", "salmon")
        )
      )
  })


  # EDA
  output$summaryStats <- DT::renderDT({
    req(active_data())
    df <- active_data()
    stats <- data.frame(
      Variable = names(df),
      Class = sapply(df, class),
      Missing = sapply(df, function(x) sum(is.na(x))),
      Mean = sapply(df, function(x) if(is.numeric(x)) mean(x, na.rm=TRUE) else NA),
      Median = sapply(df, function(x) if(is.numeric(x)) median(x, na.rm=TRUE) else NA),
      Min = sapply(df, function(x) if(is.numeric(x)) min(x, na.rm=TRUE) else NA),
      Max = sapply(df, function(x) if(is.numeric(x)) max(x, na.rm=TRUE) else NA)
    )
    DT::datatable(stats, options = list(pageLength = 10, scrollX = TRUE))
  })

 # EDA
  observe({
    req(active_data())
    updateSelectInput(session, "eda_var", choices = names(active_data()))
  })

  output$eda_plot <- renderPlot({
    req(active_data(), input$eda_var)
    df <- active_data()
    var <- input$eda_var
    if(is.numeric(df[[var]])) {
      ggplot(df, aes_string(x = var)) +
        geom_histogram(bins = 30, fill="steelblue", color="white") +
        theme_minimal() +
        labs(title = paste("Distribution of", var))
    } else {
      ggplot(df, aes_string(x = var)) +
        geom_bar(fill="steelblue") +
        theme_minimal() +
        labs(title = paste("Counts of", var))
    }
  })



  # Visualization
  output$results_table <- renderDT({
    req(results())
    DT::datatable(
      as.data.frame(results()),
      options = list(pageLength = 10, scrollX = TRUE),
      rownames = FALSE
    ) %>%
      DT::formatStyle(
        "ord_expected",
        target = "row",
        backgroundColor = DT::styleEqual(
          c("Accepted", "Rejected"),
          c("lightgreen", "salmon")
        )
      )
  })

  # Visualization
  output$results_plot <- renderPlot({
    df <- results()
    req(df)

    group_var <- input$viz_group

    # Create a new column for total revenue
    df$opt_total_revenue <- df$opt_mat_revenue + df$opt_lab_revenue
    df$opt_total_revenue[df$ord_expected == "Rejected" & df$opt_total_revenue == 0] <- -25


    ggplot(df, aes_string(x = group_var,
                            y = "opt_total_revenue",
                            fill = "ord_expected")) +
      geom_col() +
      # geom_text(stat = "count", aes(label = ..count..),
                # position = position_stack(vjust = 0.5)) +
      theme_minimal()+
      labs(title = paste("Optimized Revenue by", group_var),
           x = group_var,
           y = "Revenue")
  })

  # Summary Visualization
  output$status_summary <- renderPlot({
    df <- results()
    req(df)
    ggplot(df, aes(x = ord_expected, fill = ord_expected)) +
      geom_bar() +
      theme_minimal() +
      labs(title = "Order Status Summary",
           x = "Status",
           y = "Count")
  })



  # Database update
  update_status <- reactiveVal("Click 'Run Update' to refresh database.")
  observeEvent(input$update_btn, {
    update_db()
    update_status("Database updated successfully!")
  })
  output$update_status <- renderText({ update_status() })

  # Download
  output$download_results <- downloadHandler(
    filename = function() { "Optm_df.csv" },
    content = function(file) {
      file.copy("./results/Optm_df.csv", file)
    }
  )
}


shinyApp(ui, server)
