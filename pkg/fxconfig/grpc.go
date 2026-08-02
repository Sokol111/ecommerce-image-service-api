package client

import (
	"context"

	"go.uber.org/fx"
	"google.golang.org/grpc"

	"github.com/Sokol111/ecommerce-commons/pkg/core/config"
	grpcclient "github.com/Sokol111/ecommerce-commons/pkg/http/grpc/client"
	imagev1 "github.com/Sokol111/ecommerce-image-service-api/gen/go/image/v1"
)

// NewGrpcClientsModule wires a native gRPC client for ImageService.
// Configuration is read from koanf under key "image.grpc".
func NewGrpcClientsModule() fx.Option {
	return fx.Module("image-grpc-clients",
		fx.Provide(func(loader *config.Loader) (grpcclient.Config, error) {
			return grpcclient.LoadConfig(loader, "image.grpc")
		}, fx.Private),
		fx.Provide(grpcclient.NewGrpcConnWithTokenSource, fx.Private),
		fx.Provide(func(conn *grpc.ClientConn) grpc.ClientConnInterface {
			return conn
		}, fx.Private),
		fx.Provide(imagev1.NewImageServiceClient),
		fx.Invoke(func(lc fx.Lifecycle, conn *grpc.ClientConn) {
			lc.Append(fx.Hook{
				OnStop: func(context.Context) error {
					return conn.Close()
				},
			})
		}),
	)
}
