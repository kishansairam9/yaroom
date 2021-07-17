package main

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
	"github.com/rs/xid"
	"github.com/rs/zerolog/log"
)

var wsUpgrader = websocket.Upgrader{ReadBufferSize: 1024, WriteBufferSize: 1024}

type WSMessage struct {
	Type string `json:"type"`
}

type ChatMessage struct {
	Type     string    `json:"type"`
	MsgId    string    `json:"msgId"`
	FromUser string    `json:"fromUser"`
	ToUser   string    `json:"toUser"`
	Time     time.Time `json:"time"`
	Content  string    `json:"content"`
	Media    string    `json:"media"`
	ReplyTo  string    `json:"replyTo"`
}

func wsHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := wsUpgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Warn().Str("where", "wsHandler").Str("error", "ws upgrade").Msg(err.Error())
		return
	}
	// NOTE: We are just ignoring fault messages sent on websocket, not informing clients
	// TODO: Is ignoring good?
	for {
		t, rawMsg, err := conn.ReadMessage()
		if err != nil {
			log.Info().Str("where", "wsHandler").Str("error", "conn read msg").Msg(err.Error())
			break
		}
		var wsm WSMessage
		if err := json.Unmarshal(rawMsg, &wsm); err != nil {
			log.Warn().Str("where", "wsHandler").Str("error", "msg type not found").Msg(err.Error())
			continue
		}
		var enc []byte
		switch wsm.Type {
		case "ChatMessage":
			var msg ChatMessage
			if err := json.Unmarshal(rawMsg, &msg); err != nil {
				log.Warn().Str("where", "wsHandler").Str("error", "msg type and contents didn't match").Msg(err.Error())
				continue
			}
			msg.MsgId = xid.New().String()
			// TODO: Send to RabbitMQ & Data Store
			enc, _ = json.Marshal(msg)
		default:
			log.Warn().Str("where", "wsHandler").Str("error", "unknown message type").Msg(err.Error())
			continue
		}
		conn.WriteMessage(t, enc)
	}
}
