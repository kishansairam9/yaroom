package main

import (
	"fmt"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

type JSONableSlice []uint8

func (u JSONableSlice) MarshalJSON() ([]byte, error) {
	var result string
	if u == nil {
		result = "null"
	} else {
		result = strings.Join(strings.Fields(fmt.Sprintf("%d", u)), ",")
	}
	return []byte(result), nil
}

type testingUser struct {
	UserId string `uri:"userId" binding:"required"`
}

type mediaRequest struct {
	ObjectId string `uri:"objectid" binding:"required"`
}

type iconUploadRequest struct {
	IconId    string        `json:"iconId" binding:"required"`
	JpegBytes JSONableSlice `json:"jpegBytes"`
}

type getLaterMessagesRequest struct {
	LastMsgId string `form:"lastMsgId" binding:"required"`
}

type getOlderMessagesRequest struct {
	ExchangeId string `form:"exchangeId" binding:"required"`
	MsgType    string `form:"msgType" binding:"required"`
	Limit      uint   `form:"limit" binding:"required"`
	LastMsgId  string `form:"lastMsgId" binding:"required"`
}

type searchQueryRequest struct {
	ExchangeId   string `form:"exchangeId" binding:"required"`
	MsgType      string `form:"msgType" binding:"required"`
	Limit        uint   `form:"limit" binding:"required"`
	SearchString string `form:"searchString" binding:"required"`
}

type fcmTokenUpdate struct {
	Token string `json:"fcm_token" binding:"required"`
}

type groupDetails struct {
	GroupId      string     `json:"groupId"`
	Name         string     `json:"name"`
	Description  string     `json:"description"`
	GroupIcon    string     `json:"groupIcon"`
	GroupMembers []User_udt `json:"groupMembers"`
}

type roomDetails struct {
	RoomId       string   `json:"roomId" binding:"required"`
	Name         string   `json:"name" binding:"required"`
	Description  string   `json:"description"`
	RoomIcon     string   `json:"roomIcon"`
	RoomMembers  []string `json:"roomMembers"`
	ChannelsList []string `json:"channelsList"`
}

type exitGroupRequest struct {
	GroupId string     `json:"groupId" binding:"required"`
	User    []User_udt `json:"user"`
}

type friendRequest struct {
	UserId string `json:"userId" binding:"required"`
	Status int    `json:"status" binding:"required"`
}

func updateGroupHandler(g *gin.Context) {
	var req groupDetails
	if err := g.BindJSON(&req); err != nil {
		log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
		return
	}

	data, err := updateGroupMetadata(&GroupMetadata{Groupid: req.GroupId, Name: req.Name, Image: &req.GroupIcon, Description: &req.Description, Userslist: req.GroupMembers})
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	g.JSON(200, groupDetails{GroupId: data.Groupid, Name: data.Name, Description: *data.Description, GroupIcon: *data.Image, GroupMembers: data.Userslist})
}

func getUserDetailsHandler(g *gin.Context) {
	rawUserId, exists := g.Get("userId")
	if !exists {
		g.AbortWithStatusJSON(400, gin.H{"error": "user not authenticated"})
		return
	}
	userId := rawUserId.(string)

	data, err := getUserDetails(userId)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	g.JSON(200, data)
}

func getLaterMessageHandler(g *gin.Context) {
	var req getLaterMessagesRequest
	if err := g.BindQuery(&req); err != nil {
		log.Info().Str("where", "bind query").Str("type", "failed to parse body to query").Msg(err.Error())
		return
	}

	rawUserId, exists := g.Get("userId")
	if !exists {
		g.AbortWithStatusJSON(400, gin.H{"error": "user not authenticated"})
		return
	}
	userId := rawUserId.(string)

	if req.LastMsgId == "null" {
		req.LastMsgId = "0"
	}

	msgs, err := getLaterMessages(userId, req.LastMsgId)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	g.JSON(200, msgs)
}

func getOlderMessageHandler(g *gin.Context) {
	var req getOlderMessagesRequest
	if err := g.BindQuery(&req); err != nil {
		log.Info().Str("where", "bind query").Str("type", "failed to parse body").Msg(err.Error())
		return
	}

	rawUserId, exists := g.Get("userId")
	if !exists {
		g.AbortWithStatusJSON(400, gin.H{"error": "user not authenticated"})
		return
	}
	userId := rawUserId.(string)

	if req.LastMsgId == "null" {
		req.LastMsgId = "0"
	}

	msgs, err := getOlderMessages(userId, req.LastMsgId, req.ExchangeId, req.MsgType, req.Limit)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	g.JSON(200, msgs)
}

func searchQueryHandler(g *gin.Context) {
	var req searchQueryRequest
	if err := g.BindQuery(&req); err != nil {
		log.Info().Str("where", "bind query").Str("type", "failed to parse body to query").Msg(err.Error())
		return
	}

	rawUserId, exists := g.Get("userId")
	if !exists {
		g.AbortWithStatusJSON(400, gin.H{"error": "user not authenticated"})
		return
	}
	userId := rawUserId.(string)

	if req.SearchString == "" {
		g.AbortWithStatusJSON(400, gin.H{"error": "empty search string"})
		return
	}

	msgs, err := searchQuery(userId, req.SearchString, req.ExchangeId, req.MsgType, req.Limit)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	g.JSON(200, msgs)
}

func exitGroupHandler(g *gin.Context) {
	var req exitGroupRequest
	if err := g.BindJSON(&req); err != nil {
		log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
		return
	}
	var userId string
	for _, k := range req.User {
		userId = k.Userid
		break
	}
	err := deleteGroupFromUser(&GroupsListOfUserUpdate{Userid: userId, Groupslist: []string{req.GroupId}})
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	er := deleteUserFromGroup(&UsersListOfGroupUpdate{Groupid: req.GroupId, Userslist: req.User})
	if er != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": er.Error()})
		return
	}

	g.JSON(200, gin.H{"success": true})
}

func friendRequestHandler(g *gin.Context) {
	var req friendRequest
	if err := g.BindJSON(&req); err != nil {
		log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
		return
	}
	rawUserId, exists := g.Get("userId")
	if !exists {
		g.AbortWithStatusJSON(400, gin.H{"error": "user not authenticated"})
		return
	}
	userId := rawUserId.(string)

	if req.Status == 1 {
		// User sent friend request
		if err := addUserPendingRequest(&PendingListOfUserUpdate{Userid: req.UserId, Pendinglist: []string{userId}}); err != nil {
			g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
			return
		}
	} else if req.Status == 2 {
		// User accepted friend request
		if err := removeUserPendingRequest(&PendingListOfUserUpdate{Userid: userId, Pendinglist: []string{req.UserId}}); err != nil {
			g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
			return
		}
		if err := addUserFriend(&FriendsListOfUserUpdate{Userid: req.UserId, Friendslist: []string{userId}}); err != nil {
			g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
			return
		}
		if err := addUserFriend(&FriendsListOfUserUpdate{Userid: userId, Friendslist: []string{req.UserId}}); err != nil {
			g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
			return
		}
	} else if req.Status == 3 {
		// User rejects friend request
		if err := removeUserPendingRequest(&PendingListOfUserUpdate{Userid: userId, Pendinglist: []string{req.UserId}}); err != nil {
			g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
			return
		}
	} else if req.Status == 4 {
		// User removes friend
		if err := removeUserFriend(&FriendsListOfUserUpdate{Userid: req.UserId, Friendslist: []string{userId}}); err != nil {
			g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
			return
		}
		if err := removeUserFriend(&FriendsListOfUserUpdate{Userid: userId, Friendslist: []string{req.UserId}}); err != nil {
			g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
			return
		}
	}
	g.JSON(200, gin.H{"success": true})

}
