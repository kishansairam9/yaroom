package main

import (
	"encoding/json"
	"time"

	"github.com/gin-gonic/gin"
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

func wsHandler(g *gin.Context) {
	conn, err := wsUpgrader.Upgrade(g.Writer, g.Request, nil)
	if err != nil {
		log.Warn().Str("where", "wsHandler").Str("type", "ws upgrade").Msg(err.Error())
		return
	}

	// TODO uncomment after securing ws route
	// rawUserId, _ := g.Get("userId")
	// userId := rawUserId.(string)

	// Database insert routine
	dbInChannel := make(chan interface{}, 50)
	dbOutChannel := make(chan interface{}, 50)
	dbQuit := make(chan bool)
	go dbInsertRoutine(dbInChannel, dbOutChannel, dbQuit)

	// WS Read routine
	readChannel := make(chan interface{}, 10)
	readQuit := make(chan bool)
	go func(ch chan<- interface{}, quit chan bool) {
		for {
			_, rawMsg, err := conn.ReadMessage()
			if err != nil {
				log.Info().Str("where", "wsHandler").Str("type", "conn read msg").Msg(err.Error())
				quit <- true
				return
			}
			var msg WSMessage
			if err := json.Unmarshal(rawMsg, &msg); err != nil {
				ch <- WSError{Error: "Error parsing message contents"}
				continue
			}
			// TODO uncomment after securing ws route
			// // Validate fromUser with userId in JWT to prevent
			// if msg.FromUser != userId {
			// 	ch <- WSError{Error: "Invalid fromUser! Identifications spoofing"}
			// 	continue
			// }
			ch <- msg
			select {
			case <-quit:
				return
			default:
			}
		}
	}(readChannel, readQuit)

	// Message queue read routine
	msgQueueReadQuit := make(chan bool)
	// TODO: Replace userID with jwt user ID
	go msgQueueReadRoutine("userId", dbOutChannel, msgQueueReadQuit)

	gotQuitFromRead, gotQuitFromMsgReadQueue := false, false

	for {
		var msg interface{}
		connFailed := false

		select {
		case msg = <-readChannel:
			switch msg.(type) {
			case WSMessage:
				dbInChannel <- msg
			case WSError:
				err := conn.WriteJSON(msg)
				if err != nil {
					log.Info().Str("where", "wsHandler").Str("type", "writing message").Msg(err.Error())
					connFailed = true
				}
			}

		case out := <-dbOutChannel:
			err = conn.WriteJSON(out)
			if err != nil {
				log.Info().Str("where", "wsHandler").Str("type", "writing message").Msg(err.Error())
				connFailed = true
			}
			// TODO: Replace userID with jwt user ID
			data, isMsg := out.(WSMessage)
			if isMsg && data.FromUser == "userId" {
				if err = msgQueueSendToUser(out.(WSMessage).ToUser, out.(WSMessage)); err != nil {
					log.Error().Str("where", "msgQueue send to user").Str("type", "failed to write to user queue").Msg(err.Error())
				}
			}

		case <-readQuit:
			gotQuitFromRead = true

		case <-msgQueueReadQuit:
			gotQuitFromMsgReadQueue = true
			err = conn.WriteJSON(WSError{Error: "Server Error, report to support"})
			if err != nil {
				log.Info().Str("where", "wsHandler").Str("type", "writing message").Msg(err.Error())
				connFailed = true
			}
		}

		if gotQuitFromRead || gotQuitFromMsgReadQueue || connFailed {
			break
		}

	}
	dbQuit <- true
	if !gotQuitFromRead {
		readQuit <- true
	}
	if !gotQuitFromMsgReadQueue {
		msgQueueReadQuit <- true
	}
}
