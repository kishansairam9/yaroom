package main

import (
	"encoding/json"
	"errors"
	"fmt"

	"github.com/appleboy/go-fcm"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

func fcmTokenUpdateHandler(g *gin.Context) {
	var req fcmTokenUpdate
	if err := g.BindJSON(&req); err != nil {
		log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
		return
	}

	rawUserId, exists := g.Get("userId")
	if !exists {
		print("what?")
		g.AbortWithStatusJSON(400, gin.H{"error": "not authenticated"})
		return
	}
	userId := rawUserId.(string)

	if err := addFCMToken(&UserFCMTokenUpdate{Userid: userId, Tokens: []string{req.Token}}); err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
}

func fcmTokenInvalidateHandler(g *gin.Context) {
	var req fcmTokenUpdate
	if err := g.BindJSON(&req); err != nil {
		log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
		return
	}

	rawUserId, exists := g.Get("userId")
	if !exists {
		print("what?")
		g.AbortWithStatusJSON(400, gin.H{"error": "not authenticated"})
		return
	}
	userId := rawUserId.(string)

	if err := removeFCMToken(&UserFCMTokenUpdate{Userid: userId, Tokens: []string{req.Token}}); err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
}

func trimLength(content string, length int) string {
	if len(content) > length {
		content = content[:length] + "..."
	}
	return content
}

func sendMessageNotification(userId string, msg WSMessage) error {
	fmt.Printf("sending fcm message to %v\n", userId)
	encodedString, _ := json.Marshal(msg)
	var data map[string]interface{}
	json.Unmarshal(encodedString, &data)

	var fromUserData *UserMetadata
	var toUserData *UserMetadata

	fromUserData, err := getUserMetadata(msg.FromUser)
	if err != nil {
		return err
	}

	toUserData, err = getUserMetadata(userId)
	if err != nil {
		return err
	}

	if toUserData == nil || fromUserData == nil {
		return errors.New("user doesn't exits")
	}

	if len(toUserData.Tokens) == 0 {
		// no active device token so no need to send notification
		return nil
	}

	switch msg.Type {
	case "ChatMessage":
		for _, token := range toUserData.Tokens {
			print("sending to ", token)
			notif := &fcm.Message{
				To:   token,
				Data: data,
				Notification: &fcm.Notification{
					Title: fromUserData.Name,
					Body:  trimLength(msg.Content, 150),
				},
			}
			res, err := fcmClient.SendWithRetry(notif, 3)
			if err == fcm.ErrInvalidRegistration {
				print("remove token ", token)
				removeFCMToken(&UserFCMTokenUpdate{Userid: userId, Tokens: []string{token}})
			} else if err != nil {
				log.Error().Str("where", "update user metadata").Str("type", "failed to bind struct").Str("fcm response", fmt.Sprint(res)).Msg(err.Error())
			}
		}

	default:
		return errors.New("unknown message type")
	}
	return nil
}
