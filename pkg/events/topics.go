package events

import (
	eventsv1 "github.com/Sokol111/ecommerce-image-service-api/gen/image/events/v1"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/reflect/protoreflect"
)

// Topic constants
const (
	TopicCatalogProductEvents = "catalog.product.events"
)

// topicMap maps proto message full names to their Kafka topics.
var topicMap = map[protoreflect.FullName]string{
	(&eventsv1.ProductImagePromotedEvent{}).ProtoReflect().Descriptor().FullName(): TopicCatalogProductEvents,
}

// TopicFor returns the Kafka topic for the given proto message.
// Panics if the message type is not registered in topicMap.
func TopicFor(msg proto.Message) string {
	fullName := msg.ProtoReflect().Descriptor().FullName()
	topic, ok := topicMap[fullName]
	if !ok {
		panic("events: no topic registered for " + string(fullName))
	}
	return topic
}
