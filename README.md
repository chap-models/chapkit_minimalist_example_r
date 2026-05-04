# chapkit_minimalist_example_r

The canonical minimal R example for [chapkit](https://dhis2-chap.github.io/chapkit).
Fits `lm(disease_cases ~ rainfall + mean_temperature)` and forecasts from future
climate data, wrapped as a chapkit ML service on top of the public
[`chapkit-r-inla`](https://github.com/dhis2-chap/chapkit-images) base image.

Use this repo as a starting point for your own R-on-chapkit model: copy and
replace the `lm()` in `scripts/train.R` / `scripts/predict.R` with your real
model, update the `MLServiceInfo` block in `main.py`, and you're done.

Scaffolded with `uvx --from chapkit chapkit init <name> --template shell-r`.

## What you'll edit

You typically only edit three places:

1. `scripts/train.R` - your R training logic
2. `scripts/predict.R` - your R prediction logic
3. The `Config` class and `MLServiceInfo` block in `main.py` - the parameters your
   model accepts and the metadata that describes it

Everything else (`Dockerfile`, `compose.yml`, the rest of `main.py`, the database
plumbing) is wiring you can leave alone.

## What you need installed

- **Docker** with the compose plugin (the Docker image ships R + INLA + the spatial /
  time-series stack, so you don't need a local R install).
- **Python 3.13 + uv** *(optional, only for fast iteration without rebuilding the
  Docker image)*. Install uv from [astral.sh/uv](https://docs.astral.sh/uv/).

`chapkit` itself is bundled inside the Docker image; you don't have to install
it on your host.

## Quick Start

### Run with Docker (recommended)

The Docker image bundles everything (R, INLA, chapkit), so this works without a
local Python or R install:

```bash
# One-time: generates uv.lock that the Dockerfile pins against. Needs uv installed.
uv lock

docker compose up --build
```

The API will be available at:
- API: http://localhost:9090
- API Docs: http://localhost:9090/docs

The compose stack maps host port 9090 to container port 8000. Edit `compose.yml`
if you want a different host port.

### Local dev (optional, faster iteration)

If you have Python 3.13 + uv + R installed locally, you can skip Docker for
faster restart cycles:

```bash
uv sync
uv run python main.py
```

### Verify the service

Once the service is running (locally or in Docker), exercise the full
config -> train -> predict flow with `chapkit test`:

```bash
# Against the running service (default http://localhost:9090)
uv run chapkit test

# More aggressive: 3 configs, 2 trainings each, 2 predictions per model
uv run chapkit test -c 3 -t 2 -p 2 --verbose

# Auto-start an in-memory service for the duration of the test
uv run chapkit test --start-service
```

Note: this is an end-to-end **smoke test** of the API surface, not a model
quality test. `chapkit test` synthesises random training and prediction
data, drives the service through the full config -> train -> predict
lifecycle, and confirms each step returns a valid response. It does not
validate that your model produces meaningful predictions - only that the
service plumbing (config CRUD, the train job, artifact persistence, and
predict) all work. Handy after editing `main.py` or rebuilding the image.

## API Endpoints

The interactive Swagger UI at <http://localhost:9090/docs> is the easiest way to
poke at the service - it lets you fill in payloads and hit endpoints from the
browser without any extra tools.

If you prefer Postman or Insomnia, point them at the OpenAPI spec at
<http://localhost:9090/openapi.json> (Postman: *Import → Link* and paste the URL;
it generates a fresh collection). Re-import after API changes.

### Health Check

```bash
curl http://localhost:9090/health
```

### Configuration Management

Create a configuration:

```bash
curl -X POST http://localhost:9090/api/v1/configs \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-config",
    "data": {}
  }'
```

### ML Operations

Train a model:

```bash
curl -X POST http://localhost:9090/api/v1/ml/\$train \
  -H "Content-Type: application/json" \
  -d '{
    "config_id": "YOUR_CONFIG_ID",
    "data": {
      "feature_1": [1, 2, 3],
      "feature_2": [4, 5, 6],
      "target": [7, 8, 9]
    }
  }'
```

Make predictions:

```bash
curl -X POST http://localhost:9090/api/v1/ml/\$predict \
  -H "Content-Type: application/json" \
  -d '{
    "model_id": "YOUR_MODEL_ID",
    "future": {
      "feature_1": [1, 2],
      "feature_2": [3, 4]
    }
  }'
```

## Customization

### Service identity (`MLServiceInfo`)

Open `main.py` and fill in the `MLServiceInfo` block - chap-core surfaces these
fields in its UI when listing models:

- `id`, `display_name`, `version`, `description` - human-readable identity.
- `model_metadata.author`, `contact_email`, `organization` - who owns it.
- `model_metadata.author_assessed_status` - your honest read of how validated
  the model is. Pick conservatively; chap-core shows this colour next to your
  model in the catalogue.

| Status | Meaning |
| --- | --- |
| `green` | Validated and ready for production use |
| `yellow` | Ready for more rigorous testing on diverse data |
| `orange` | Shows promise on limited data, needs manual configuration and careful evaluation |
| `red` | Highly experimental prototype, not validated, only for early experimentation |
| `gray` | Not intended for use - deprecated or kept only for backwards compatibility |

This repo ships `AssessedStatus.red` because it's a teaching example, not a
real forecaster. When you fork it for a real model, bump it up to match
reality.

### Update Model Configuration

Edit the configuration class in `main.py`. The default `Config` only declares
`prediction_periods`; add whatever your scripts read from `config.yml`:

```python
class ChapkitMinimalistExampleRConfig(BaseConfig):
    prediction_periods: int = 3
    # Your model's hyperparameters, exposed via the config endpoint
    min_samples: int = 5
    learning_rate: float = 0.01
```

### Customize Training (Shell Runner, R)

Edit `scripts/train.R` to implement your model training logic. The example
fits a linear regression — replace the `lm(...)` line with your real model.
The script receives `--data <path-to-training-csv>` (and optionally
`--geo <path-to-geojson>`), reads `config.yml` from the workspace if you
need hyperparameters, and writes the model artefact to `model.rds`.

### Customize Prediction (Shell Runner, R)

Edit `scripts/predict.R`. The example calls `predict()` on the saved `lm`
object using `rainfall` and `mean_temperature` from the future CSV — replace
that with your model's inference path. The script receives `--historic`,
`--future`, `--output` (and optional `--geo`); it loads the model written
by training and writes predictions (with at least a `sample_0` column) to
the `--output` CSV.

### R packages

The default Docker image (`chapkit-r-inla`) ships a curated R stack: `INLA`,
`fmesher`, `dlnm`, `tsModel`, `sn`, `xgboost`, `sf`, `spdep`, `dplyr`, `readr`,
`yaml`, `jsonlite`, `pak`, `renv`. To add packages, either install them at
build time in the `Dockerfile` (`RUN R -e "install.packages('foo')"`) or
commit an `renv.lock` and bake it in. See
[chapkit-r-inla](https://github.com/dhis2-chap/chapkit-images) for the full list.

## Project Structure

```
chapkit_minimalist_example_r/
├── main.py              # Main application file
├── scripts/             # External training/prediction scripts (R)
│   ├── train.R          # Training script
│   └── predict.R        # Prediction script
├── pyproject.toml       # Python dependencies
├── Dockerfile           # Docker build configuration
├── compose.yml          # Docker Compose configuration
└── data/                # Database directory
    └── chapkit.db       # SQLite database (persisted)
```

## Documentation

- [Chapkit Documentation](https://dhis2-chap.github.io/chapkit)
- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [Servicekit Documentation](https://winterop-com.github.io/servicekit)

## License

[GPL-3.0](LICENSE), matching sister chap-models repos.