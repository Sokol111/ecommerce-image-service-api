EVENTS_PROTO_DIR ?= proto/events
EVENTS_OUT ?= gen/go

# =============================================================================
# Events (buf + protoc-gen-go)
# =============================================================================

.PHONY: events-generate
events-generate: _events-check-tools ## Generate Go types from Kafka event proto files
	@echo "$(COLOR_BLUE)→ Generating event types...$(COLOR_RESET)"
	$(BUF) generate --path $(EVENTS_PROTO_DIR) --template buf.gen.events.yaml
	@echo "$(COLOR_GREEN)✓ Event generation complete!$(COLOR_RESET)"
	@echo "$(COLOR_BLUE)  Generated files in $(EVENTS_OUT)/:$(COLOR_RESET)"
	@find $(EVENTS_OUT) -name '*.pb.go' | sed 's/^/    /'

.PHONY: events-clean
events-clean: ## Remove generated event pb.go files
	@echo "$(COLOR_BLUE)→ Cleaning generated event files...$(COLOR_RESET)"
	@find $(EVENTS_OUT) -name '*.pb.go' -delete
	@echo "$(COLOR_GREEN)✓ Cleaned event pb.go files$(COLOR_RESET)"

# ---- Internal targets ----

.PHONY: _events-check-tools
_events-check-tools:
	@command -v $(BUF) >/dev/null 2>&1 || \
		{ echo "$(COLOR_RED)✗ buf not found$(COLOR_RESET)"; \
		  echo "$(COLOR_YELLOW)  Install: make connect-install-tools$(COLOR_RESET)"; \
		  exit 1; }
	@echo "$(COLOR_GREEN)✓ buf found: $(BUF)$(COLOR_RESET)"

	@command -v protoc-gen-go >/dev/null 2>&1 || \
		{ echo "$(COLOR_RED)✗ protoc-gen-go not found$(COLOR_RESET)"; \
		  echo "$(COLOR_YELLOW)  Install: make connect-install-tools$(COLOR_RESET)"; \
		  exit 1; }
	@echo "$(COLOR_GREEN)✓ protoc-gen-go found$(COLOR_RESET)"
