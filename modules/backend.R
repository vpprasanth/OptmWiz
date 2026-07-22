# backend.R (modernized)

checkPackage <- function(list.of.packages) {
  new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[, "Package"])]
  if (length(new.packages) > 0) install.packages(new.packages, dependencies = TRUE)
  suppressPackageStartupMessages(lapply(list.of.packages, require, character.only = TRUE))
}

# Wrapper for optimization
run_optimization <- function(
    input_file = "",
    output_file = "Optm_df",
    order_type = 1,
    mat_markup = 0.18,
    lab_markup = 0.10
) {
  cat("run_optimization called...\n")
  run_optm(input_file, output_file, order_type, mat_markup, lab_markup)
}

# Wrapper for database update
update_db <- function() {
  cat("update_db called...\n")
  run_update()
}
