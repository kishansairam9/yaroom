package main

import (
	"encoding/json"
	"fmt"
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
	GroupId   string       `json:"groupId,omitempty"`
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
		g.AbortWithStatusJSON(400, gin.H{"error": "user not authenticated"})
		return
	}
	userId := rawUserId.(string)

	// Get metadata for active status handlers
	userMeta, err := getUserMetadata(userId)
	if err != nil {
		log.Error().Str("where", "get user metadata").Str("type", "error occured in retrieving data").Msg(err.Error())
		g.AbortWithStatus(500)
		return
	}
	if userMeta == nil {
		log.Error().Str("where", "get user metadata").Str("type", "no metadata in user tables").Msg(err.Error())
		g.AbortWithStatus(500)
		return
	}

	activeStatusStreams := make([]string, 0)
	activeStatusStreams = append(activeStatusStreams, "USER:15")
	if userMeta.Friendslist != nil {
		for _, friend := range userMeta.Friendslist {
			activeStatusStreams = append(activeStatusStreams, fmt.Sprintf("USER:%v", friend))
		}
	}
	if userMeta.Groupslist != nil {
		for _, group := range userMeta.Groupslist {
			activeStatusStreams = append(activeStatusStreams, fmt.Sprintf("GROUP:%v", group))
		}
	}
	if userMeta.Roomslist != nil {
		for _, room := range userMeta.Roomslist {
			activeStatusStreams = append(activeStatusStreams, fmt.Sprintf("ROOM:%v", room))
		}
	}
	err = ensureActiveStatusStreamsExist(activeStatusStreams)
	if err != nil {
		log.Error().Str("where", "ensure active status streams").Str("type", "error occured in adding streams").Msg(err.Error())
		g.AbortWithStatus(500)
		return
	}

	// Active status routine
	activeStatusQuit := make(chan bool)
	activeStatusOutChannel := make(chan interface{}, 30)
	go subscribeToActiveStatus(activeStatusStreams, activeStatusOutChannel, activeStatusQuit)
	activityMonitorChannelQuit := make(chan bool)
	activityMonitorChannel := make(chan bool, 3)
	// Activity monitor routine
	go monitorActivity(userId, activeStatusStreams, activityMonitorChannel, activityMonitorChannelQuit)

	// Database insert routine
	dbInChannel := make(chan interface{}, 50)
	dbOutChannel := make(chan interface{}, 50)
	dbQuit := make(chan bool)
	go dbInsertRoutine(dbInChannel, dbOutChannel, dbQuit)

	// WS Read routine
	readChannel := make(chan interface{}, 10)
	readQuit := make(chan bool)
	go func(msgChannel chan<- interface{}, activityChannel chan<- bool, quit chan bool) {
		for {
			_, rawMsg, err := conn.ReadMessage()
			if err != nil {
				log.Info().Str("where", "wsHandler").Str("type", "conn read msg").Msg(err.Error())
				quit <- true
				return
			}
			var msg WSMessage
			if err := json.Unmarshal(rawMsg, &msg); err != nil {
				msgChannel <- WSError{Error: "Error parsing message contents"}
				continue
			}

			if msg.Type == "Active" {
				activityChannel <- true
			} else {
				// Validate fromUser with userId in JWT to prevent invalid msgs
				if msg.FromUser != userId {
					msgChannel <- WSError{Error: "Invalid fromUser! Identifications spoofing"}
					continue
				}
				msgChannel <- msg
			}

			select {
			case <-quit:
				return
			default:
			}
		}
	}(readChannel, activityMonitorChannel, readQuit)

	// Write loop
	gotQuitFromRead := false
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
			// data, isMsg := out.(WSMessage)
			// if isMsg && data.FromUser == userId {
			// 	if err = sendMessageNotification(out.(WSMessage).ToUser, out.(WSMessage)); err != nil {
			// 		log.Error().Str("where", "fcm send to user").Str("type", "failed to send push notification").Msg(err.Error())
			// 	}
			// }

		case activity := <-activeStatusOutChannel:
			err = conn.WriteJSON(activity)
			if err != nil {
				log.Info().Str("where", "wsHandler").Str("type", "writing message").Msg(err.Error())
				connFailed = true
			}

		case <-readQuit:
			gotQuitFromRead = true
		}

		if gotQuitFromRead || connFailed {
			break
		}

	}
	dbQuit <- true
	activeStatusQuit <- true
	activityMonitorChannelQuit <- true
	if !gotQuitFromRead {
		readQuit <- true
	}
}
