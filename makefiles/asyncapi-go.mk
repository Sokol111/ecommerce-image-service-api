# Configuration (can be overridden)
ASYNCAPI_SPEC ?= asyncapi/asyncapi.yaml
AVRO_DIR ?= avro
EVENTS_DIR ?= gen/events
EVENTS_PACKAGE ?= events

# Scripts
EVENTS_SCRIPT := scripts/generate-events.sh

# =============================================================================
# AsyncAPI/Events Generation
# =============================================================================

.PHONY: events-generate
events-generate: _events-check-tools ## Generate Go code from AsyncAPI/Avro schemas
	@chmod +x $(EVENTS_SCRIPT)
	@$(EVENTS_SCRIPT) \
		--asyncapi $(ASYNCAPI_SPEC) \
		--schemas $(AVRO_DIR) \
		--output $(EVENTS_DIR) \
		--package $(EVENTS_PACKAGE)

.PHONY: events-clean
events-clean: ## Clean generated events directory
	@echo "Cleaning $(EVENTS_DIR)..."
	@rm -rf $(EVENTS_DIR)
	@echo "Done."

.PHONY: events-install-tools
events-install-tools: ## Install required tools for events generation
	@echo "Installing avrogen..."
	@go install github.com/hamba/avro/v2/cmd/avrogen@latest
	@echo ""
	@echo "Note: Also ensure you have installed:"
	@echo "  - yq: brew install yq / sudo apt install yq"
	@echo "  - jq: brew install jq / sudo apt install jq"
	@echo ""
	@echo "Done."

# Internal targets
.PHONY: _events-check-tools
_events-check-tools:
	@command -v avrogen >/dev/null 2>&1 || { echo "Error: avrogen not found. Run: make events-install-tools"; exit 1; }
	@command -v yq >/dev/null 2>&1 || { echo "Error: yq not found. Install: brew install yq"; exit 1; }
	@command -v jq >/dev/null 2>&1 || { echo "Error: jq not found. Install: brew install jq"; exit 1; }
