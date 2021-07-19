package main

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"github.com/rs/zerolog/log"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"go.mongodb.org/mongo-driver/x/bsonx"
)

// Note: If we use primitive object ID as type then we need to limit to 12 char strings
// But our user ID is longer hence, we use type as string. Note that however
// though type is string, if it refers to `_id` then it is still created as an index
// And references to other objects we are creating indexes manually in db

type User struct {
	UserId     string   `bson:"_id"`
	Name       string   `bson:"name"`
	About      string   `bson:"about,omitempty"`
	ProfileImg string   `bson:"profileImg,omitempty"`
	Friends    []string `bson:"friends"`
	Groups     []string `bson:"groups"`
}

type ChatMessage struct {
	MsgId    string    `bson:"_id,omitempty"` // NOTE: Remember while querying, msgId is stored as _id
	FromUser string    `bson:"fromUser"`
	ToUser   string    `bson:"toUser"`
	Time     time.Time `bson:"time"`
	Content  string    `bson:"content,omitempty"`
	Media    string    `bson:"media,omitempty"`
	ReplyTo  string    `bson:"replyTo,omitempty"`
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
		log.Fatal().Str("where", "create indexes").Str("type", "Indexes Create Many chatMsgCol").Msg(err.Error())
	}

	// TODO: Similarly for Group and Rooms messages

	log.Info().Msg("Database indexes ensured")
}

func addMessage(msg WSMessage) (WSMessage, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	jsonBytes, _ := json.Marshal(msg)

	var msgId string

	switch msg.Type {
	case "ChatMessage":
		var data ChatMessage
		if err := bson.UnmarshalExtJSON(jsonBytes, true, &data); err != nil {
			return msg, err
		}
		res, err := chatMsgCol.InsertOne(ctx, data)
		if err != nil {
			return msg, err
		}
		msgId = res.InsertedID.(primitive.ObjectID).Hex()
	default:
		return msg, errors.New("unknown message type")
	}

	msg.MsgId = msgId
	return msg, nil
}
