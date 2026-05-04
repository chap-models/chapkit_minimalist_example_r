#!/usr/bin/env Rscript
# Minimalist R example: fit lm(disease_cases ~ rainfall + mean_temperature)
# and save the model.
#
# ShellModelRunner copies the project into an isolated workspace and substitutes
# {data_file} into the train command (see main.py). config.yml is always
# present in the workspace; we don't need it for this toy model.
#
# Usage:
#   Rscript train.R --data data.csv [--geo geo.json]

args <- commandArgs(trailingOnly = TRUE)
parse_arg <- function(name, required = FALSE, default = "") {
  idx <- which(args == paste0("--", name))
  if (length(idx) == 0) {
    if (required) stop(sprintf("Missing required argument --%s", name))
    return(default)
  }
  args[idx + 1]
}

data_path <- parse_arg("data", required = TRUE)

result <- tryCatch({
  data <- read.csv(data_path)
  data$disease_cases[is.na(data$disease_cases)] <- 0
  message(sprintf("Loaded %d training samples", nrow(data)))

  model <- lm(disease_cases ~ rainfall + mean_temperature, data = data)
  saveRDS(model, "model.rds")
  message("Model saved to model.rds")
  cat("SUCCESS: Training completed\n")
  0
}, error = function(e) {
  message(sprintf("ERROR: Training failed: %s", conditionMessage(e)))
  1
})

quit(status = result)
