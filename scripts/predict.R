#!/usr/bin/env Rscript
# Minimalist R example: load the lm() model and predict from future climate.
#
# ShellModelRunner substitutes {historic_file}, {future_file}, {output_file}
# into the predict command (see main.py). The historic CSV isn't needed for
# this toy linear model — kept in the signature for parity with chap-core's
# expected predict shape.
#
# Usage:
#   Rscript predict.R --historic historic.csv --future future.csv --output predictions.csv [--geo geo.json]

args <- commandArgs(trailingOnly = TRUE)
parse_arg <- function(name, required = FALSE, default = "") {
  idx <- which(args == paste0("--", name))
  if (length(idx) == 0) {
    if (required) stop(sprintf("Missing required argument --%s", name))
    return(default)
  }
  args[idx + 1]
}

future_path <- parse_arg("future", required = TRUE)
output_path <- parse_arg("output", required = TRUE)

result <- tryCatch({
  model <- readRDS("model.rds")
  future <- read.csv(future_path)
  message(sprintf("Loaded %d prediction rows", nrow(future)))

  future$sample_0 <- predict(model, newdata = future[, c("rainfall", "mean_temperature"), drop = FALSE])
  write.csv(future, output_path, row.names = FALSE)
  message(sprintf("Predictions saved to %s", output_path))
  cat("SUCCESS: Prediction completed\n")
  0
}, error = function(e) {
  message(sprintf("ERROR: Prediction failed: %s", conditionMessage(e)))
  1
})

quit(status = result)
