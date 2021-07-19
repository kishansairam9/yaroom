package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
	"github.com/rs/zerolog/log"
)

var wsUpgrader = websocket.Upgrader{ReadBufferSize: 1024, WriteBufferSize: 1024}

// All message types are handled by one raw struct (non relavant fields are ignored), we switch based on type of message as required
type WSMessage struct {
	Type     string    `json:"type"`
	MsgId    string    `json:"msgId,omitempty"`
	FromUser string    `json:"fromUser"`
	ToUser   string    `json:"toUser,omitempty"`
	Time     time.Time `json:"time"`
	Content  string    `json:"content,omitempty"`
	Media    string    `json:"media,omitempty"`
	ReplyTo  string    `json:"replyTo,omitempty"`
}

type WSError struct {
	Error string `json:"error"`
}

func wsHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := wsUpgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Warn().Str("where", "wsHandler").Str("error", "ws upgrade").Msg(err.Error())
		return
	}

	for {
		t, rawMsg, err := conn.ReadMessage()
		var enc []byte = nil
		if err != nil {
			log.Info().Str("where", "wsHandler").Str("error", "conn read msg").Msg(err.Error())
			break
		}
		var msg WSMessage
		if err := json.Unmarshal(rawMsg, &msg); err != nil {
			enc, _ = json.Marshal(WSError{Error: "Error parsing message contents"})
		}
		msg, err = addMessage(msg)
		if err != nil {
			if err.Error() == "unknown message type" {
				enc, _ = json.Marshal(WSError{Error: "Unknown message type"})
			} else {
				log.Error().Str("where", "add message").Str("error", "failed to add messsage to db").Msg(err.Error())
			}
		}
		msg.Media = ""
		if enc == nil {
			enc, _ = json.Marshal(msg)
		}
		fmt.Print("returning ", string(enc))
		conn.WriteMessage(t, enc)
	}
}
