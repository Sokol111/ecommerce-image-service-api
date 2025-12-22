# Configuration (can be overridden)
ASYNCAPI_SPEC ?= asyncapi/asyncapi.yaml
AVRO_DIR ?= avro
EVENTS_DIR ?= gen/events
EVENTS_PACKAGE ?= events

# =============================================================================
# AsyncAPI/Events Generation
# =============================================================================

.PHONY: events-generate
events-generate: _events-check-tools ## Generate Go code from AsyncAPI/Avro schemas
	@eventgen generate \
		--payloads $(AVRO_DIR) \
		--output $(EVENTS_DIR) \
		--package $(EVENTS_PACKAGE) \
		--asyncapi $(ASYNCAPI_SPEC)

.PHONY: events-validate
events-validate: _events-check-tools ## Validate Avro schemas
	@eventgen validate --payloads $(AVRO_DIR)

.PHONY: events-clean
events-clean: ## Clean generated events directory
	@echo "Cleaning $(EVENTS_DIR)..."
	@rm -rf $(EVENTS_DIR)
	@echo "Done."

# Path to local ecommerce-commons (for local development)
COMMONS_PATH ?= ../ecommerce-commons

.PHONY: events-install-tools
events-install-tools: ## Install required tools for events generation
	@echo "Installing eventgen..."
	@if [ -d "$(COMMONS_PATH)/cmd/eventgen" ]; then \
		echo "  -> from local: $(COMMONS_PATH)"; \
		(cd $(COMMONS_PATH) && go install ./cmd/eventgen); \
	else \
		echo "  -> from github"; \
		go install github.com/Sokol111/ecommerce-commons/cmd/eventgen@latest; \
	fi
	@echo "Installing avrogen..."
	@go install github.com/hamba/avro/v2/cmd/avrogen@latest
	@echo "Done."

# Internal targets
.PHONY: _events-check-tools
_events-check-tools:
	@command -v eventgen >/dev/null 2>&1 || { echo "Error: eventgen not found. Run: make events-install-tools"; exit 1; }
	@command -v avrogen >/dev/null 2>&1 || { echo "Error: avrogen not found. Run: make events-install-tools"; exit 1; }
