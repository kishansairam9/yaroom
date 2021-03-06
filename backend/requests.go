package main

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

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

type getUserDetailsRequest struct {
	Name string `form:"name" binding:"required"`
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

type userDetails struct {
	Userid string `json:"userId"`
	Name   string `json:"name"`
	About  string `json:"about"`
}

type groupDetails struct {
	GroupId      string   `json:"groupId"`
	Name         string   `json:"name"`
	Description  string   `json:"description"`
	GroupIcon    string   `json:"groupIcon"`
	GroupMembers []string `json:"groupMembers"`
}

type roomDetails struct {
	RoomId       string            `json:"roomId"`
	Name         string            `json:"name"`
	Description  string            `json:"description"`
	RoomIcon     string            `json:"roomIcon"`
	RoomMembers  []string          `json:"roomMembers"`
	ChannelsList map[string]string `json:"channelsList"`
}

type lastReadDetails struct {
	UserId     string `json:"userId" binding:"required"`
	ExchangeId string `json:"exchangeId" binding:"required"`
	LastRead   string `json:"lastRead" binding:"required"`
}

type exitGroupRequest struct {
	GroupId string   `json:"groupId" binding:"required"`
	User    []string `json:"user"`
}

type exitRoomRequest struct {
	RoomId string   `json:"roomId" binding:"required"`
	User   []string `json:"user"`
}

type friendRequest struct {
	UserId string `json:"userId" binding:"required"`
	Status string `json:"status" binding:"required"`
}

type deleteChannel struct {
	RoomId    string `json:"roomId" binding:"required"`
	ChannelId string `json:"channelId" binding:"required"`
}

const (
	SendRequest   = "1"
	AcceptRequest = "2"
	RejectRequest = "3"
	RemoveFriend  = "4"
)

func updateUserHandler(g *gin.Context) {
	var req userDetails
	if err := g.BindJSON(&req); err != nil {
		log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
		return
	}
	err := updateUserMetadata(&UserMetadata{Userid: req.Userid, Name: req.Name, Username: &req.About})
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
}

func updateGroupHandler(g *gin.Context) {
	_, exists := g.Get("userId")
	if !exists {
		g.AbortWithStatusJSON(400, gin.H{"error": "user not authenticated"})
		return
	}
	// userId := rawUserId.(string)

	var req groupDetails
	if err := g.BindJSON(&req); err != nil {
		log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
		return
	}

	var users_udt = []User_udt{}
	if len(req.GroupMembers) > 0 {
		users, e := getUsers(req.GroupMembers)
		if e != nil {
			g.AbortWithStatusJSON(500, gin.H{"error": e.Error()})
			return
		}
		for _, curr := range users {
			users_udt = append(users_udt, User_udt{Name: curr.Name, Userid: curr.Userid})
		}
	}
	data, err := updateGroupMetadata(&GroupMetadata{Groupid: req.GroupId, Name: req.Name, Description: &req.Description, Userslist: users_udt})
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}

	var users_list = []string{}
	ensureStreamsExist([]string{"GROUP:" + data.Groupid})
	for _, curr := range data.Userslist {
		users_list = append(users_list, curr.Userid)
		ensureStreamsExist([]string{"SELF:" + curr.Userid})
		sendUpdateOnStream([]string{"SELF:" + curr.Userid}, []byte("SUB-GROUP:"+data.Groupid))
	}

	obj, err := getGroupMetadata(data.Groupid)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	encObj, err := json.Marshal(*obj)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	m := make(map[string]interface{})
	_ = json.Unmarshal(encObj, &m)
	m["update"] = "group"
	encAug, _ := json.Marshal(m)
	time.AfterFunc(time.Duration(1)*time.Second, func() {
		sendUpdateOnStream([]string{"GROUP:" + data.Groupid}, encAug)
	})

	g.JSON(200, groupDetails{GroupId: data.Groupid, Name: data.Name, Description: *data.Description, GroupMembers: users_list})
}

func updateRoomHandler(g *gin.Context) {

	_, exists := g.Get("userId")
	if !exists {
		g.AbortWithStatusJSON(400, gin.H{"error": "user not authenticated"})
		return
	}
	// userId := rawUserId.(string)

	var req roomDetails
	if err := g.BindJSON(&req); err != nil {
		log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
		return
	}

	var users_udt = []User_udt{}
	if len(req.RoomMembers) > 0 {
		users, e := getUsers(req.RoomMembers)
		if e != nil {
			g.AbortWithStatusJSON(500, gin.H{"error": e.Error()})
			return
		}
		for _, curr := range users {
			users_udt = append(users_udt, User_udt{Name: curr.Name, Userid: curr.Userid})
		}
	}
	fmt.Println(req.ChannelsList)
	data, err := updateRoomMetadata(&RoomMetadata{Roomid: req.RoomId, Name: req.Name, Description: &req.Description, Userslist: users_udt, Channelslist: req.ChannelsList})
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}

	var users_list = []string{}
	ensureStreamsExist([]string{"ROOM:" + data.Roomid})
	for _, curr := range data.Userslist {
		users_list = append(users_list, curr.Userid)
		ensureStreamsExist([]string{"SELF:" + curr.Userid})
		sendUpdateOnStream([]string{"SELF:" + curr.Userid}, []byte("SUB-ROOM:"+data.Roomid))
	}

	obj, err := getRoomMetadata(data.Roomid)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	encObj, err := json.Marshal(*obj)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	m := make(map[string]interface{})
	_ = json.Unmarshal(encObj, &m)
	m["update"] = "room"
	encAug, _ := json.Marshal(m)
	time.AfterFunc(time.Duration(1)*time.Second, func() {
		sendUpdateOnStream([]string{"ROOM:" + data.Roomid}, encAug)
	})
	g.JSON(200, roomDetails{RoomId: data.Roomid, Name: data.Name, Description: *data.Description, RoomMembers: users_list, ChannelsList: data.Channelslist})
}

func deleteChannelHandler(g *gin.Context) {
	var req deleteChannel
	if err := g.BindJSON(&req); err != nil {
		log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
		return
	}

	err := deleteChannelsOfRoom(req.RoomId, req.ChannelId)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	obj, err := getRoomMetadata(req.RoomId)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	encObj, err := json.Marshal(obj)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	m := make(map[string]interface{})
	_ = json.Unmarshal(encObj, &m)
	m["update"] = "room"
	m["delChannel"] = req.ChannelId
	encAug, _ := json.Marshal(m)
	sendUpdateOnStream([]string{"ROOM:" + req.RoomId}, encAug)
	g.JSON(200, gin.H{"success": true})

}

func getUserDetailsHandler(g *gin.Context) {

	var req getUserDetailsRequest
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

	data, err := getUserDetails(userId, req.Name)
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

func exitRoomHandler(g *gin.Context) {
	var req exitRoomRequest
	if err := g.BindJSON(&req); err != nil {
		log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
		return
	}
	var userId string = req.User[0]
	user, e := getUsers([]string{userId})
	var user_udt = []User_udt{}
	for _, curr := range user {
		user_udt = append(user_udt, User_udt{Name: curr.Name, Userid: curr.Userid})
	}
	if e != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": e.Error()})
		return
	}
	err := deleteRoomFromUser(&RoomsListOfUserUpdate{Userid: userId, Roomslist: []string{req.RoomId}})
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	er := deleteUserFromRoom(&UsersListOfRoomUpdate{Roomid: req.RoomId, Userslist: user_udt})
	if er != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": er.Error()})
		return
	}
	obj, err := getRoomMetadata(req.RoomId)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	encObj, err := json.Marshal(obj)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	m := make(map[string]interface{})
	_ = json.Unmarshal(encObj, &m)
	m["update"] = "room"
	m["delUser"] = userId
	encAug, _ := json.Marshal(m)
	sendUpdateOnStream([]string{"ROOM:" + req.RoomId}, encAug)
	time.AfterFunc(time.Duration(1)*time.Second, func() {
		delete(m, "update")
		m["exit"] = "room"
		encAug, _ = json.Marshal(m)
		sendUpdateOnStream([]string{"SELF:" + userId}, encAug)
	})
	g.JSON(200, gin.H{"success": true})
}

func exitGroupHandler(g *gin.Context) {
	var req exitGroupRequest
	if err := g.BindJSON(&req); err != nil {
		log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
		return
	}
	var userId string = req.User[0]
	user, e := getUsers([]string{userId})
	var user_udt = []User_udt{}
	for _, curr := range user {
		user_udt = append(user_udt, User_udt{Name: curr.Name, Userid: curr.Userid})
	}
	if e != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": e.Error()})
		return
	}
	err := deleteGroupFromUser(&GroupsListOfUserUpdate{Userid: userId, Groupslist: []string{req.GroupId}})
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	er := deleteUserFromGroup(&UsersListOfGroupUpdate{Groupid: req.GroupId, Userslist: user_udt})
	if er != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": er.Error()})
		return
	}
	obj, err := getGroupMetadata(req.GroupId)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	encObj, err := json.Marshal(obj)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	m := make(map[string]interface{})
	_ = json.Unmarshal(encObj, &m)
	m["update"] = "group"
	m["delUser"] = userId
	encAug, _ := json.Marshal(m)
	sendUpdateOnStream([]string{"GROUP:" + req.GroupId}, encAug)
	time.AfterFunc(time.Duration(1)*time.Second, func() {
		delete(m, "update")
		m["exit"] = "group"
		encAug, _ = json.Marshal(m)
		sendUpdateOnStream([]string{"SELF:" + userId}, encAug)
	})
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

	if req.Status == SendRequest {
		// User sent friend request
		if err := addUserPendingRequest(&PendingListOfUserUpdate{Userid: req.UserId, Pendinglist: []string{userId}}); err != nil {
			g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
			return
		}
	} else if req.Status == AcceptRequest {
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
	} else if req.Status == RejectRequest {
		// User rejects friend request
		if err := removeUserPendingRequest(&PendingListOfUserUpdate{Userid: userId, Pendinglist: []string{req.UserId}}); err != nil {
			g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
			return
		}
	} else if req.Status == RemoveFriend {
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
	m := make(map[string]interface{})
	m["userId"] = req.UserId
	m["friendRequest"] = req.Status
	m["fromUser"] = userId
	if err := sendFriendRequestNotification(m); err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	g.JSON(200, gin.H{"success": true})

}

func updateLastReadHandler(g *gin.Context) {
	var req lastReadDetails
	if err := g.BindJSON(&req); err != nil {
		log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
		return
	}
	err := updateLastReadMetadata(&LastReadMetadata{Userid: req.UserId, Exchange_id: req.ExchangeId, Lastread: req.LastRead})
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	g.JSON(200, gin.H{"success": true})
}

func getLastReadHandler(g *gin.Context) {
	rawUserId, exists := g.Get("userId")
	if !exists {
		g.AbortWithStatusJSON(400, gin.H{"error": "user not authenticated"})
		return
	}
	userId := rawUserId.(string)
	data, err := getLastReadMetadata(userId)
	if err != nil {
		g.AbortWithStatusJSON(500, gin.H{"error": err.Error()})
		return
	}
	g.JSON(200, data)
}
