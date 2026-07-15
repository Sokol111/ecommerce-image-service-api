# AGENTS.md

## What this repo is

This is the **API contract repo** for `ecommerce-image-service` — the image upload/serving
service (MinIO + imgproxy locally, Cloudflare R2 in production) in a CQRS + event-driven
system. It holds no business logic. It contains:

- **Protobuf sources** (`proto/`) — the only files you hand-edit.
- **Generated code** (`gen/go`, `gen/typescript`) — never hand-edit; regenerate instead.
- **Thin Go helpers** (`pkg/`) that build on the generated code: an `fx` gRPC client module
  and a Kafka topic registry.

Consumers: the image service (implements the `ImageService` RPC server, produces the events),
services that project image events into their read models (the `ProductImagePromotedEvent` is
published on the `catalog.product.events` topic), and the Nuxt UIs (import the generated TS
client).

## Golden rule: edit proto, then regenerate

**Never hand-edit anything under `gen/`.** All Go and TypeScript there is produced by `buf`
from `proto/`. Edit the `.proto` and run `make generate`. Hand edits are silently overwritten
on the next generation and break the release pipeline.

## Commands

```bash
make generate            # DEFAULT WORKFLOW: lint + generate TS + Go events + Go Connect/gRPC
make lint                # buf lint only (STANDARD rules)
make format              # buf format -w
make connect-breaking    # check proto for breaking changes against .git#branch=main
make tidy                # go mod tidy
make update-proto-deps   # buf dep update (refresh buf.lock)
make connect-install-tools   # install buf + protoc-gen-{go,connect-go,go-grpc} at pinned versions
make help                # list all targets grouped by category
```

`make generate` runs three independent generators (see `makefiles/`), each driven by its own
buf template:

- **`connect-generate`** → Go structs + Connect + gRPC from `proto/image/v1/` (template
  `buf.gen.yaml`) into `gen/go/image/v1/`.
- **`events-generate`** → Go structs from `proto/image/events/v1/` (template
  `buf.gen.events.yaml`) into `gen/go/image/events/v1/`.
- **`connect-ts-generate`** → TypeScript client + a generated `package.json`/`tsconfig.json`,
  then `npm run build`. The package is `@sokol111/ecommerce-image-service-api`, versioned from
  the `VERSION` file. Use `connect-ts-generate-fast` to skip the npm build (CI builds before
  publishing).

## Proto layout and conventions

Two proto trees under `proto/image/`, with distinct purposes and package names:

- `v1/` (`package image.v1`, `image.proto`) — **the synchronous RPC contract**. A single
  `ImageService` with six RPCs: `CreatePresign`, `ConfirmUpload`, `GetImage`, `DeleteImage`,
  `GetDeliveryUrl`, `PromoteImages`. The file defines the enums (`OwnerType`, `ImageRole`,
  `ImageStatus`, `ImageContentType`, `ImageFit`, `ImageFormat`), the `Image`/`ImageVariant`
  entities, and per-RPC request/response messages.
- `events/v1/` (`package image.events.v1`, `image_events.proto`) — **Kafka event schemas**.
  Currently just `ProductImagePromotedEvent`, emitted when a product's main image is promoted;
  it carries the image/product IDs, the small/large delivery URLs, and a timestamp.

The upload flow the proto encodes: `CreatePresign` hands back a presigned upload URL plus an
`upload_token`, the client uploads directly to object storage, then `ConfirmUpload` (keyed by
that token) finalizes the `Image`. Delivery URLs are minted on demand via `GetDeliveryUrl`
(imgproxy transform params: width/height, `ImageFit`, `ImageFormat`, quality, dpr, ttl).

The buf module (`buf.build/sokol111/image-api`) depends on `protovalidate`; validation rules
belong in the proto as protovalidate options.

## The `pkg/` helpers

- `pkg/client/grpc.go` — `client.Module()` returns an `fx.Option` wiring a native gRPC
  `ImageServiceClient`, reading config from koanf key `image.grpc`. This is how consumer
  services get an image client — import the module, don't construct the client by hand.
- `pkg/events/topics.go` — maps proto event message full-names to Kafka topic names
  (`ProductImagePromotedEvent` → `catalog.product.events`) and exposes `TopicFor(msg)`.
  **When you add a new event message, register it in `topicMap`** or `TopicFor` panics at
  runtime for that type.

## Releasing (production only)

Versioning is release-then-bump. Pushing a change to the `VERSION` file on `master` triggers
`.github/workflows/release.yml`, which calls the shared
`ecommerce-infrastructure/.github/workflows/api-release.yml` — this tags the Go module and
publishes the TS package to GitHub Packages, running a breaking-change check first
(`skip_breaking` input to override). Consuming services then bump their `go.mod` dependency.

Note: this applies to CI/production. In local development everything resolves through the root
`go.work`, so proto changes are visible to consumers immediately with no release/bump.
