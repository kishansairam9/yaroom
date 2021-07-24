package main

import (
	"encoding/json"
	"errors"
	"sort"
	"time"

	"github.com/rs/xid"
	"github.com/rs/zerolog/log"
	"github.com/scylladb/gocqlx/v2"
	"github.com/scylladb/gocqlx/v2/table"
)

// Note: If we use primitive object ID as type then we need to limit to 12 char strings
// But our user ID is longer hence, we use type as string. Note that however
// though type is string, if it refers to `_id` then it is still created as an index
// And references to other objects we are creating indexes manually in db

var ChatMessageMetadata = table.Metadata{
	Name:    "messages.chat_messages",
	Columns: []string{"exchange_id", "msgid", "fromuser", "touser", "msgtime", "content", "media", "replyto", "es_query", "es_options"},
	PartKey: []string{"exchange_id"},
	SortKey: []string{"msgtime", "msgid"},
}

var ChatMessageTable *table.Table

var InsertChatMessage *gocqlx.Queryx

func setupDB() {
	ChatMessageTable = table.New(ChatMessageMetadata)
	InsertChatMessage = ChatMessageTable.InsertQuery(dbSession)
}

type ChatMessage struct {
	Exchange_id string    `json:"exchange_id,omitempty"`
	Msgid       string    `json:"msgId,omitempty"`
	Fromuser    string    `json:"fromUser"`
	Touser      string    `json:"toUser"`
	Msgtime     time.Time `json:"time"`
	Content     string    `json:"content,omitempty"`
	Media       string    `json:"media,omitempty"`
	Replyto     string    `json:"replyTo,omitempty"`
	Es_query    string    `json:"es_query,omitempty"`
	Es_options  string    `json:"es_options,omitempty"`
}

func addMessage(msg WSMessage) (WSMessage, error) {
	jsonBytes, _ := json.Marshal(msg)

	msgId := xid.New().String()

	switch msg.Type {
	case "ChatMessage":
		var data ChatMessage
		if err := json.Unmarshal(jsonBytes, &data); err != nil {
			return msg, err
		}
		uids := []string{data.Fromuser, data.Touser}
		sort.Strings(uids)
		data.Exchange_id = uids[0] + ":" + uids[1]
		data.Msgid = msgId
		if q := InsertChatMessage.BindStruct(data); q.Err() != nil {
			log.Error().Str("where", "insert chat message").Str("type", "failed to bind struct").Msg(q.Err().Error())
			return msg, errors.New("internal server error")
		}
		if err := InsertChatMessage.Exec(); err != nil {
			log.Error().Str("where", "insert chat message").Str("type", "failed to execute query").Msg(err.Error())
			return msg, errors.New("internal server error")
		}
	default:
		return msg, errors.New("unknown message type")
	}

	msg.MsgId = msgId
	return msg, nil
}

func dbInsertRoutine(inChannel <-chan interface{}, outChannel chan<- interface{}, quit <-chan bool) {
	var err error
	for {
		select {
		case msg := <-inChannel:
			msg, err = addMessage(msg.(WSMessage))
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
