# minimalist_example_r_chapkit

ML service for minimalist_example_r_chapkit

This project was scaffolded using the [Chapkit](https://dhis2-chap.github.io/chapkit) CLI.

## Quick Start

### Development Mode

Install dependencies and run the service locally:

```bash
uv sync
uv run python main.py
```

The API will be available at http://localhost:8000

### Docker

Build and run with Docker Compose:

```bash
docker compose up --build
```

The API will be available at:
- API: http://localhost:8000
- API Docs: http://localhost:8000/docs

## API Endpoints

### Health Check

```bash
curl http://localhost:8000/health
```

### Configuration Management

Create a configuration:

```bash
curl -X POST http://localhost:8000/api/v1/configs \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-config",
    "data": {}
  }'
```

### ML Operations

Train a model:

```bash
curl -X POST http://localhost:8000/api/v1/ml/\$train \
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
curl -X POST http://localhost:8000/api/v1/ml/\$predict \
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

### Update Model Configuration

Edit the configuration class in `main.py`:

```python
class MinimalistExampleRChapkitConfig(BaseConfig):
    # Add your parameters here
    min_samples: int = 5
    learning_rate: float = 0.01
```

### Customize Training (Shell Runner)

Edit the training script in `scripts/train_model.py` to implement your model training logic.

The script receives the following arguments:
- `--config`: Path to config YAML file
- `--data`: Path to training data CSV
- `--model`: Path to save trained model (pickle format)
- `--geo`: Optional GeoJSON file path

### Customize Prediction (Shell Runner)

Edit the prediction script in `scripts/predict_model.py` to implement your prediction logic.

The script receives the following arguments:
- `--config`: Path to config YAML file
- `--model`: Path to trained model pickle file
- `--historic`: Path to historic data CSV
- `--future`: Path to future data CSV
- `--output`: Path to save predictions CSV
- `--geo`: Optional GeoJSON file path

### Using Other Languages

The shell runner is language-agnostic! You can replace the Python scripts with:
- R scripts: `Rscript scripts/train_model.R ...`
- Julia scripts: `julia scripts/train_model.jl ...`
- Any executable that accepts the same arguments

Just update the command templates in `main.py`:

```python
train_command = f"Rscript {SCRIPTS_DIR}/train_model.R --config  ..."
```

## Project Structure

```
minimalist_example_r_chapkit/
├── main.py              # Main application file
├── scripts/             # External training/prediction scripts
│   ├── train_model.py   # Training script
│   └── predict_model.py # Prediction script
├── pyproject.toml       # Python dependencies
├── Dockerfile           # Docker build configuration
├── compose.yml          # Docker Compose configuration
├── data/                # Database directory
│   └── chapkit.db       # SQLite database (persisted)
```

## Documentation

- [Chapkit Documentation](https://dhis2-chap.github.io/chapkit)
- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [Servicekit Documentation](https://winterop-com.github.io/servicekit)

## License

Add your license information here.