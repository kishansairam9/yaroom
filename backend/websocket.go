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
	Type      string       `json:"type"`
	MsgId     string       `json:"msgId,omitempty"`
	FromUser  string       `json:"fromUser"`
	ToUser    string       `json:"toUser,omitempty"`
	Time      time.Time    `json:"time,omitempty"`
	Content   string       `json:"content,omitempty"`
	MediaData *WSMediaFile `json:"mediaData,omitempty"`
	Media     string       `json:"media,omitempty"`
	ReplyTo   string       `json:"replyTo,omitempty"`
	RoomId    string       `json:"roomId,omitempty"`
	ChannelId string       `json:"channelId,omitempty"`
}

type WSMediaFile struct {
	Name  string `json:"name"`
	Bytes []byte `json:"bytes"`
}

type WSError struct {
	Error string `json:"error"`
}

func wsHandler(g *gin.Context) {
	conn, err := wsUpgrader.Upgrade(g.Writer, g.Request, nil)
	if err != nil {
		log.Warn().Str("where", "wsHandler").Str("type", "ws upgrade").Msg(err.Error())
		g.AbortWithStatusJSON(400, gin.H{"error": "failed to upgrade connection to websocket"})
		return
	}

	rawUserId, exists := g.Get("userId")
	if !exists {
		// TODO: REMOVE DUMMY USER ID AFTER SECURING ROUTE AND THROW ERROR
		rawUserId = "0"
		// g.AbortWithStatusJSON(400, gin.H{"error": "user not authenticated"})
		// return
	}
	userId := rawUserId.(string)

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

			// Validate fromUser with userId in JWT to prevent
			// if msg.FromUser != userId {
			// 	ch <- WSError{Error: "Invalid fromUser! Identifications spoofing msg.FromUser " + msg.FromUser + " userId " + userId}

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

	go msgQueueReadRoutine(userId, dbOutChannel, msgQueueReadQuit)

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
			data, isMsg := out.(WSMessage)
			if isMsg && data.FromUser == userId {
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
