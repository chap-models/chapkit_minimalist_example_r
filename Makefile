.PHONY: help build run run-ghcr test lint

IMAGE      ?= chapkit-minimalist-example-r:latest
GHCR_IMAGE ?= ghcr.io/chap-models/chapkit_minimalist_example_r:latest
TEST_NAME  ?= chapkit-minimalist-example-r-test
TEST_PORT  ?= 9000
TEST_URL   ?= http://localhost:$(TEST_PORT)

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build      Build docker image ($(IMAGE))"
	@echo "  run        Build and run the image on :8000"
	@echo "  run-ghcr   Pull and run the prebuilt GHCR image on :8000"
	@echo "  test       Build, start container, run 'chapkit test', shut down"
	@echo "  lint       Run ruff format check + lint"

build:
	@echo ">>> Building $(IMAGE)"
	@docker build --no-cache -t $(IMAGE) .

run: build
	@echo ">>> Running $(IMAGE) on :8000"
	@docker run --rm -p 8000:8000 --name chapkit-minimalist-example-r $(IMAGE)

run-ghcr:
	@echo ">>> Running $(GHCR_IMAGE) on :8000"
	@docker run --rm --pull always --platform linux/amd64 -p 8000:8000 --name chapkit-minimalist-example-r $(GHCR_IMAGE)

test: build
	@echo ">>> Starting $(TEST_NAME) on :$(TEST_PORT)"
	@docker rm -f $(TEST_NAME) >/dev/null 2>&1 || true
	@docker run -d --rm -p $(TEST_PORT):8000 --name $(TEST_NAME) $(IMAGE) >/dev/null
	@trap 'echo ">>> Stopping $(TEST_NAME)"; docker stop $(TEST_NAME) >/dev/null 2>&1 || true' EXIT; \
		echo ">>> Waiting for $(TEST_URL)/health"; \
		for i in $$(seq 1 60); do \
			if curl -fsS $(TEST_URL)/health >/dev/null 2>&1; then break; fi; \
			if [ $$i -eq 60 ]; then \
				echo ">>> Service did not become healthy in time"; \
				docker logs $(TEST_NAME) || true; \
				exit 1; \
			fi; \
			sleep 1; \
		done; \
		echo ">>> Running chapkit test against $(TEST_URL)"; \
		uv run chapkit test --url $(TEST_URL)

lint:
	@echo ">>> Ruff format check"
	@uv run ruff format --check .
	@echo ">>> Ruff lint"
	@uv run ruff check .

.DEFAULT_GOAL := help
