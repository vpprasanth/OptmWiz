# run_optm.R (robust, vectorized, Shiny-safe)

library(dplyr)
library(data.table)

# Flexible normalization
normalise_Function <- function(df) {
  # If material_cost exists, clean it
  if ("material_cost" %in% names(df)) {
    df <- df %>%
      mutate(
        material_cost = ifelse(material_cost == -1, NA, material_cost),
        material_cost = coalesce(material_cost, 0)
      )
  } else {
    df$material_cost <- 0
  }

  # If labour_cost exists, clean it
  if ("labour_cost" %in% names(df)) {
    df <- df %>% mutate(labour_cost = coalesce(labour_cost, 0))
  } else {
    df$labour_cost <- 0
  }

  # If material exists, keep it; otherwise create placeholder
  if (!"material" %in% names(df)) {
    df$material <- "Unknown"
  }

  return(df)
}

# Main optimization
run_optm <- function(
    input_file = "",
    output_file = "Optm_df",
    order_type = 1,
    mat_markup = 0.18,
    lab_markup = 0.10
) {
  cat("run_optm started...\n")

  out_file <- file.path("results", paste0(output_file, ".csv"))
  if (!dir.exists("results")) dir.create("results")

  if (input_file == "") stop("No input file provided")

  # Read input
  test_df <- read.csv(input_file, stringsAsFactors = FALSE)
  cat("Rows in input:", nrow(test_df), "\n")

  # Normalize
  test_df <- normalise_Function(test_df)

  # Apply markups vectorized
  test_df <- test_df %>%
    mutate(
      opt_mat_revenue = round(material_cost * (1 + mat_markup), 2),
      opt_lab_revenue = round(labour_cost * (1 + lab_markup), 2),
      ord_expected    = ifelse(opt_mat_revenue + opt_lab_revenue > 0, "Accepted", "Rejected")
    )

  # Select output columns
  optm_df <- test_df %>%
    select(material, opt_mat_revenue, opt_lab_revenue, ord_expected)

  # Write results
  write.csv(optm_df, out_file, row.names = FALSE)
  cat("Results written to", out_file, "\n")

  return(optm_df)
}
