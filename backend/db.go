package main

import (
	"context"
	"time"

	"github.com/rs/zerolog/log"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"go.mongodb.org/mongo-driver/x/bsonx"
)

type User struct {
	UserId     primitive.ObjectID `bson:"_id"`
	Name       string             `bson:"name"`
	About      string             `bson:"about,omitempty"`
	ProfileImg string             `bson:"profileImg,omitempty"`
}

type ChatMessage struct {
	MsgId    primitive.ObjectID `bson:"_id"` // NOTE: Remember while querying, msgId is stored as _id
	FromUser primitive.ObjectID `bson:"fromUser"`
	ToUser   primitive.ObjectID `bson:"toUser"`
	Time     time.Time          `bson:"time"`
	Content  string             `bson:"content,omitempty"`
	Media    string             `bson:"media,omitempty"`
	ReplyTo  primitive.ObjectID `bson:"replyTo,omitempty"` // TODO: NOTE here should we
}

var chatMsgIndexModels = []mongo.IndexModel{
	{Keys: bsonx.Doc{{Key: "fromUser", Value: bsonx.Int32(-1)}}},
	{Keys: bsonx.Doc{{Key: "toUser", Value: bsonx.Int32(-1)}}},
}

var chatMsgCol *mongo.Collection

func createIndexes(ctx context.Context) {
	opts := options.CreateIndexes().SetMaxTime(10 * time.Second)
	_, err := chatMsgCol.Indexes().CreateMany(ctx, chatMsgIndexModels, opts)

	if err != nil {
		log.Fatal().Str("where", "create indexes").Str("error", "Indexes Create Many chatMsgCol").Msg(err.Error())
	}

	// TODO: Similarly for Group and Rooms messages

	log.Info().Msg("Database indexes ensured")
}
