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

	dbChannel := make(chan interface{})
	dbQuit := make(chan bool)
	readChannel := make(chan interface{})
	readQuit := make(chan bool)

	// Database insert routine
	go func(ch chan interface{}, quit <-chan bool) {
		for {
			select {
			case msg := <-ch:
				msg, err = addMessage(msg.(WSMessage))
				if err != nil {
					var emsg string
					if err.Error() == "unknown message type" {
						emsg = "Unknown message type"
					} else {
						emsg = "Server error, contact support"
						log.Error().Str("where", "add message").Str("type", "failed to add messsage to db").Msg(err.Error())
					}
					ch <- WSError{Error: emsg}
				} else {
					ch <- msg
				}
			case <-quit:
				return
			}
		}
	}(dbChannel, dbQuit)

	// WS Read routine
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

	gotQuitFromRead := false

	for {
		var msg interface{}
		connFailed := false

		select {
		case msg = <-readChannel:
			switch msg.(type) {
			case WSMessage:
				dbChannel <- msg
			case WSError:
				err := conn.WriteJSON(msg)
				if err != nil {
					log.Info().Str("where", "wsHandler").Str("type", "writing message").Msg(err.Error())
					connFailed = true
				}
			}
		case <-readQuit:
			gotQuitFromRead = true
		}

		if gotQuitFromRead || connFailed {
			break
		}

		err = conn.WriteJSON(<-dbChannel)
		if err != nil {
			log.Info().Str("where", "wsHandler").Str("type", "writing message").Msg(err.Error())
			break
		}
	}
	dbQuit <- true
	if !gotQuitFromRead {
		readQuit <- true
	}
}
