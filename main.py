"""ML service for chapkit_minimalist_example_r."""

# =====================================================================
# What is this file?
# =====================================================================
# main.py is the chapkit service wrapper around your model. You usually
# only edit two things in here:
#   1. The Config class below (add fields your scripts read from config.yml).
#   2. The ServiceInfo block (your name, email, model description).
#
# Your actual training and prediction logic lives in:
#   - scripts/train.R
#   - scripts/predict.R
#
# Edit those scripts to do real work; main.py wires them into the HTTP
# service, manages databases, and handles request/response shapes for you.
# =====================================================================

import os
from pathlib import Path

from chapkit import BaseConfig
from chapkit.api import AssessedStatus, MLServiceBuilder, MLServiceInfo, ModelMetadata, PeriodType
from chapkit.artifact import ArtifactHierarchy
from chapkit.ml import ShellModelRunner


class ChapkitMinimalistExampleRConfig(BaseConfig):
    """Configuration for chapkit_minimalist_example_r."""

    # Required: number of prediction periods
    prediction_periods: int = 3

    # Add your model-specific parameters here
    # Config fields can be accessed by external scripts via config.yml
    # For example:
    # min_samples: int = 5
    # model_type: str = "linear_regression"


# Create shell-based runner with command templates
# The runner copies the entire project directory to an isolated workspace
# and executes commands with the workspace as the current directory.
# This allows scripts to use relative paths and imports.
#
# Variables will be substituted with actual file paths at runtime:
#   {data_file} - Training data CSV
#   {historic_file} - Historic data CSV
#   {future_file} - Future data CSV
#   {output_file} - Predictions CSV
#   {geo_file} - Optional GeoJSON file (if provided)
#
# Files available in workspace (scripts can access directly):
#   config.yml - YAML config (always available)
#   model.rds - Model file (saveRDS / readRDS in your R scripts)

# Training command template (using relative path to script)
train_command = "Rscript scripts/train.R --data {data_file}"

# Prediction command template (using relative path to script)
predict_command = (
    "Rscript scripts/predict.R "
    "--historic {historic_file} "
    "--future {future_file} "
    "--output {output_file}"
)

# Create shell model runner
runner: ShellModelRunner[ChapkitMinimalistExampleRConfig] = ShellModelRunner(
    train_command=train_command,
    predict_command=predict_command,
)

# Create ML service info with metadata
info = MLServiceInfo(
    id="chapkit-minimalist-example-r",
    display_name="chapkit_minimalist_example_r",
    version="1.0.0",
    description=(
        "Minimalist R example: a linear regression on rainfall + mean_temperature, "
        "wrapped as a chapkit service. Intended as a starting point for chapkit-r-inla "
        "model authors - copy and replace the lm() in scripts/train.R with the real model."
    ),
    model_metadata=ModelMetadata(
        author="DHIS2 CHAP",
        author_assessed_status=AssessedStatus.red,
        contact_email="chap@dhis2.org",
    ),
    period_type=PeriodType.monthly,
    min_prediction_periods=0,
    max_prediction_periods=100,
)

# Create artifact hierarchy for ML artifacts
HIERARCHY = ArtifactHierarchy(
    name="chapkit_minimalist_example_r",
    level_labels={0: "ml_training_workspace", 1: "ml_prediction"},
)

# Database configuration
# Uses environment variable or defaults to data/chapkit.db
# Creates data directory if it doesn't exist
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///data/chapkit.db")
if DATABASE_URL.startswith("sqlite") and ":///" in DATABASE_URL:
    db_path = Path(DATABASE_URL.split("///")[1])
    db_path.parent.mkdir(parents=True, exist_ok=True)

# Build the FastAPI application
app = (
    MLServiceBuilder(
        info=info,
        config_schema=ChapkitMinimalistExampleRConfig,
        hierarchy=HIERARCHY,
        runner=runner,
        database_url=DATABASE_URL,
    )
    .with_monitoring()
    # See compose.yml for chap-core self-registration env vars.
    .with_registration()
    .build()
)


if __name__ == "__main__":
    from chapkit.api import run_app

    # Default to port 9090 to match the Docker compose host port and avoid the usual
    # busy ports (8000, 8080). Override with the PORT env var. Set reload=True to
    # enable hot reloading during development.
    run_app("main:app", reload=False, port=9090)