package main

import (
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

type testingUser struct {
	UserId string `uri:"userId" binding:"required"`
}

type testingActiveStatus struct {
	UserId string `json:"userId" binding:"required"`
	Active bool   `json:"active"`
}

type mediaRequest struct {
	ObjectId string `uri:"objectid" binding:"required"`
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

type roomDetails struct {
	RoomId       string              `json:"roomId" binding:"required"`
	Name         string              `json:"name" binding:"required"`
	Description  string              `json:"description"`
	RoomIcon     string              `json:"roomIcon"`
	RoomMembers  map[string]User_udt `json:"roomMembers"`
	ChannelsList map[string]string   `json:"channelsList"`
}

func updateRoomHandler(g *gin.Context) {
	var req roomDetails
	if err := g.BindJSON(&req); err != nil {
		log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
		return
	}

	data, err := updateRoomMetadata(&RoomMetadata{Roomid: req.RoomId, Name: req.Name, Image: &req.RoomIcon, Description: &req.Description, Userslist: req.RoomMembers, Channelslist: req.ChannelsList})
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	g.JSON(200, roomDetails{RoomId: data.Roomid, Name: data.Name, Description: *data.Description, RoomIcon: *data.Image, RoomMembers: data.Userslist, ChannelsList: data.Channelslist})
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
		g.AbortWithStatusJSON(400, gin.H{"error": err.Error()})
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
		g.AbortWithStatusJSON(400, gin.H{"error": err.Error()})
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
		g.AbortWithStatusJSON(400, gin.H{"error": err.Error()})
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
		g.AbortWithStatusJSON(400, gin.H{"error": err.Error()})
		return
	}
	g.JSON(200, msgs)
}
