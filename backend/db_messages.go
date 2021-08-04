package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"sort"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/rs/xid"
	"github.com/rs/zerolog/log"
	"github.com/scylladb/gocqlx/v2"
	"github.com/scylladb/gocqlx/v2/table"
)

var ChatMessageMetadata = table.Metadata{
	Name:    "yaroom.chat_messages",
	Columns: []string{"exchange_id", "msgid", "fromuser", "touser", "msgtime", "content", "mediaid", "replyto", "es_query", "es_options"},
	PartKey: []string{"exchange_id"},
	SortKey: []string{"msgid"},
}

var GroupMessageMetadata = table.Metadata{
	Name:    "yaroom.group_messages",
	Columns: []string{"exchange_id", "msgid", "fromuser", "groupid", "msgtime", "content", "mediaid", "replyto", "es_query", "es_options"},
	PartKey: []string{"exchange_id"},
	SortKey: []string{"msgid"},
}

var RoomMessageMetadata = table.Metadata{
	Name:    "yaroom.room_messages",
	Columns: []string{"exchange_id", "msgid", "fromuser", "roomid", "channelid", "msgtime", "content", "mediaid", "replyto", "es_query", "es_options"},
	PartKey: []string{"exchange_id"},
	SortKey: []string{"msgid"},
}

var ChatMessageTable *table.Table

var RoomMessageTable *table.Table

var GroupMessageTable *table.Table

var InsertChatMessage *gocqlx.Queryx

var InsertGroupMessage *gocqlx.Queryx

var InsertRoomMessage *gocqlx.Queryx

var GetLaterChatMessages *gocqlx.Queryx

var GetLaterGroupMessages *gocqlx.Queryx

type ChatMessage struct {
	Exchange_id string    `json:"exchange_id,omitempty"`
	Msgid       string    `json:"msgId,omitempty"`
	Fromuser    string    `json:"fromUser"`
	Touser      string    `json:"toUser"`
	Msgtime     time.Time `json:"time"`
	Content     *string   `json:"content,omitempty"`
	Mediaid     *string   `json:"media,omitempty"`
	Replyto     *string   `json:"replyTo,omitempty"`
	Es_query    string    `json:"es_query,omitempty"`
	Es_options  string    `json:"es_options,omitempty"`
}

type GroupMessage struct {
	Exchange_id string    `json:"exchange_id,omitempty"`
	Msgid       string    `json:"msgId,omitempty"`
	Fromuser    string    `json:"fromUser"`
	Groupid     string    `json:"groupId"`
	Msgtime     time.Time `json:"time"`
	Content     *string   `json:"content,omitempty"`
	Mediaid     *string   `json:"media,omitempty"`
	Replyto     *string   `json:"replyTo,omitempty"`
	Es_query    string    `json:"es_query,omitempty"`
	Es_options  string    `json:"es_options,omitempty"`
}

type RoomMessage struct {
	Exchange_id string    `json:"exchange_id,omitempty"`
	Msgid       string    `json:"msgId,omitempty"`
	Fromuser    string    `json:"fromUser"`
	Roomid      string    `json:"roomid"`
	Channelid   string    `json:"channelid"`
	Msgtime     time.Time `json:"time"`
	Content     *string   `json:"content,omitempty"`
	Mediaid     *string   `json:"media,omitempty"`
	Replyto     *string   `json:"replyTo,omitempty"`
	Es_query    string    `json:"es_query,omitempty"`
	Es_options  string    `json:"es_options,omitempty"`
}

func getExchangeId(msg *WSMessage) (string, error) {
	switch msg.Type {
	case "ChatMessage":
		uids := []string{msg.FromUser, msg.ToUser}
		sort.Strings(uids)
		return uids[0] + ":" + uids[1], nil
	case "GroupMessage":
		uids := []string{msg.GroupId}
		sort.Strings(uids)
		return uids[0], nil
	case "RoomMessage":
		uids := []string{msg.RoomId}
		sort.Strings(uids)
		return uids[0], nil
	default:
		return "", errors.New("unknown message type")
	}
}

func addMessage(msg *WSMessage) error {
	// Get exchange id
	exchange_id, err := getExchangeId(msg)
	if err != nil {
		return err
	}

	// Handle media content
	if msg.MediaData != nil {
		if msg.MediaData.Name == "" || len(msg.MediaData.Bytes) == 0 {
			return errors.New("invalid media file, check non empty name, bytes > 0")
		}
		// TODO: COMPRESS AND STORE TO SAVE STORAGE SPACE (LATER)
		mediaBytes, _ := json.Marshal(msg.MediaData)
		mediaId := xid.New().String()

		if _, err := minioClient.PutObject(context.Background(), miniobucket, mediaId, bytes.NewReader(mediaBytes), -1, minio.PutObjectOptions{ContentType: "application/json", UserMetadata: map[string]string{"x-amz-meta-key": exchange_id}}); err != nil {
			log.Error().Str("where", "ws read routine").Str("type", "uploading to minio failed at put object").Msg(err.Error())
			return errors.New("internal server error")
		}
		msg.Media = mediaId
		msg.MediaData = nil
	}

	// Use current time of server // We don't care about user sending time, we use receiving time
	msg.Time = time.Now()
	jsonBytes, _ := json.Marshal(msg)

	msgId := xid.New().String()

	// Handle different message types
	switch msg.Type {
	case "ChatMessage":
		var data ChatMessage
		if err := json.Unmarshal(jsonBytes, &data); err != nil {
			return err
		}
		data.Exchange_id = exchange_id
		data.Msgid = msgId
		data.Msgtime = time.Now()
		if q := InsertChatMessage.BindStruct(data); q.Err() != nil {
			log.Error().Str("where", "insert chat message").Str("type", "failed to bind struct").Msg(q.Err().Error())
			return errors.New("internal server error")
		}
		if err := InsertChatMessage.Exec(); err != nil {
			log.Error().Str("where", "insert chat message").Str("type", "failed to execute query").Msg(err.Error())
			return errors.New("internal server error")
		}
	case "GroupMessage":
		var data GroupMessage
		if err := json.Unmarshal(jsonBytes, &data); err != nil {
			return err
		}
		data.Exchange_id = exchange_id
		data.Msgid = msgId
		data.Msgtime = time.Now()
		if q := InsertGroupMessage.BindStruct(data); q.Err() != nil {
			log.Error().Str("where", "insert chat message").Str("type", "failed to bind struct").Msg(q.Err().Error())
			return errors.New("internal server error")
		}
		if err := InsertGroupMessage.Exec(); err != nil {
			log.Error().Str("where", "insert groups message").Str("type", "failed to execute query").Msg(err.Error())
			return errors.New("internal server error")
		}
	case "RoomMessage":
		var data RoomMessage
		if err := json.Unmarshal(jsonBytes, &data); err != nil {
			return err
		}
		data.Exchange_id = exchange_id
		data.Msgid = msgId
		data.Msgtime = time.Now()
		if q := InsertRoomMessage.BindStruct(data); q.Err() != nil {
			log.Error().Str("where", "insert rooms message").Str("type", "failed to bind struct").Msg(q.Err().Error())
			return errors.New("internal server error")
		}
		if err := InsertRoomMessage.Exec(); err != nil {
			log.Error().Str("where", "insert rooms message").Str("type", "failed to execute query").Msg(err.Error())
			return errors.New("internal server error")
		}
	default:
		return errors.New("unknown message type")
	}

	msg.MsgId = msgId
	return nil
}

func dbInsertRoutine(inChannel <-chan interface{}, outChannel chan<- interface{}, quit <-chan bool) {
	var err error
	for {
		select {
		case data := <-inChannel:
			msg, _ := data.(WSMessage)
			err = addMessage(&msg)
			if err != nil {
				var emsg string
				if err.Error() == "unknown message type" {
					emsg = "Unknown message type"
				} else {
					emsg = "Server error, contact support"
					log.Error().Str("where", "add message").Str("type", "failed to add messsage to db").Msg(err.Error())
				}
				outChannel <- WSError{Error: emsg}
			} else {
				outChannel <- msg
			}
		case <-quit:
			return
		}
	}
}
