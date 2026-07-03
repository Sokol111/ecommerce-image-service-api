package client

import (
	"github.com/knadh/koanf/v2"
	"go.uber.org/fx"

	grpcclient "github.com/Sokol111/ecommerce-commons/pkg/grpc/client"
	imagev1 "github.com/Sokol111/ecommerce-image-service-api/gen/go/image/v1"
)

// Module wires a native gRPC client for ImageService.
// Configuration is read from koanf under key "image.grpc".
func Module() fx.Option {
	return fx.Module("image-grpc-client",
		fx.Provide(func(k *koanf.Koanf) (grpcclient.Config, error) {
			return grpcclient.LoadConfig(k, "image.grpc")
		}, fx.Private),
		fx.Provide(grpcclient.NewConn, fx.Private),
		fx.Provide(imagev1.NewImageServiceClient),
	)
}
