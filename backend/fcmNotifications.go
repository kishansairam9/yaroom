package main

import (
	"encoding/json"
	"errors"
	"fmt"

	"github.com/appleboy/go-fcm"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

// TODO: Remove receiving name and image, backend should have it already
func fcmTokenHandler(g *gin.Context) {
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

	if err := addFCMToken(&UserFCMTokenUpdate{Userid: userId, Tokens: []string{req.Token}, Name: req.Name, Image: req.Image}); err != nil {
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
	// TODO: Uncomment after mocking
	// fromUserData, err := getUserMetadata(msg.FromUser)
	// if err != nil {
	// 	return err
	// }
	dummy := "dmmy"
	fromUserData = &UserMetadata{Name: &dummy}
	toUserData, err := getUserMetadata(userId)
	if err != nil {
		return err
	}
	// TODO Remove debug statements
	fmt.Println(toUserData.Name)
	fmt.Println(toUserData.Userid)
	fmt.Println(fromUserData.Image)
	fmt.Print("To user tokens -----  ")
	fmt.Println(toUserData.Tokens)
	if toUserData.Userid == nil || len(toUserData.Tokens) == 0 {
		return errors.New("user doesn't exits or token for notification not present")
	}

	switch msg.Type {
	case "ChatMessage":
		if fromUserData.Image == nil || *fromUserData.Image == "" {
			testImg := "https://cdn.business2community.com/wp-content/uploads/2017/08/blank-profile-picture-973460_640.png"
			fromUserData.Image = &testImg
		}
		for _, token := range toUserData.Tokens {
			print("sending to ", token)
			notif := &fcm.Message{
				To:   token,
				Data: data,
				Notification: &fcm.Notification{
					Title: *fromUserData.Name,
					Body:  trimLength(msg.Content, 150),
					Image: *fromUserData.Image,
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
