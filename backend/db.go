package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"reflect"
	"sort"
	"time"

	"github.com/gocql/gocql"
	"github.com/minio/minio-go/v7"
	"github.com/rs/xid"
	"github.com/rs/zerolog/log"
	"github.com/scylladb/gocqlx/qb"
	"github.com/scylladb/gocqlx/v2"
	"github.com/scylladb/gocqlx/v2/table"
)

var UsersTableMetadata = table.Metadata{
	Name:    "yaroom.users",
	Columns: []string{"userid", "name", "image", "username", "tokens", "groups"},
	PartKey: []string{"userid"},
}

var GroupsTableMetadata = table.Metadata{
	Name:    "yaroom.groups",
	Columns: []string{"groupid", "name", "image", "description", "users"},
	PartKey: []string{"groupid"},
}

var RoomsTableMetadata = table.Metadata{
	Name:    "yaroom.rooms",
	Columns: []string{"rooomid", "name", "image", "description", "users", "channels"},
	PartKey: []string{"roomid"},
}

var UserMetadataTable *table.Table
var UpdateUserMetadata *gocqlx.Queryx
var SelectUserMetadata *gocqlx.Queryx

var GroupMetadataTable *table.Table
var UpdateGroupMetadata *gocqlx.Queryx
var SelectGroupMetadata *gocqlx.Queryx

var RoomMetadataTable *table.Table
var UpdateRoomMetadata *gocqlx.Queryx
var SelectRoomMetadata *gocqlx.Queryx

var AddUserFCMToken *gocqlx.Queryx
var DeleteUserFCMToken *gocqlx.Queryx
var SelectUserFCMToken *gocqlx.Queryx

var AddUserPendingRequest *gocqlx.Queryx
var DeleteUserPendingRequest *gocqlx.Queryx
var SelectUserPendingRequest *gocqlx.Queryx

var AddUserFriend *gocqlx.Queryx
var DeleteUserFriend *gocqlx.Queryx
var SelectUserFriend *gocqlx.Queryx

var ChatMessageMetadata = table.Metadata{
	Name:    "yaroom.chat_messages",
	Columns: []string{"exchange_id", "msgid", "fromuser", "touser", "msgtime", "content", "mediaid", "replyto", "es_query", "es_options"},
	PartKey: []string{"exchange_id"},
	SortKey: []string{"msgid"},
}

var GroupsMessageMetadata = table.Metadata{
	Name:    "yaroom.groups_messages",
	Columns: []string{"exchange_id", "msgid", "fromuser", "groupid", "msgtime", "content", "mediaid", "replyto", "es_query", "es_options"},
	PartKey: []string{"exchange_id"},
	SortKey: []string{"msgid"},
}

var RoomsMessageMetadata = table.Metadata{
	Name:    "yaroom.rooms_messages",
	Columns: []string{"exchange_id", "msgid", "fromuser", "roomid", "channelid", "msgtime", "content", "mediaid", "replyto", "es_query", "es_options"},
	PartKey: []string{"exchange_id"},
	SortKey: []string{"msgid"},
}

var ChatMessageTable *table.Table

var RoomsMessageTable *table.Table

var GroupsMessageTable *table.Table

var InsertChatMessage *gocqlx.Queryx

var InsertGroupsMessage *gocqlx.Queryx

var InsertRoomsMessage *gocqlx.Queryx

func setupDB() {
	UserMetadataTable = table.New(UsersTableMetadata)
	SelectUserMetadata = UserMetadataTable.SelectQuery(dbSession)
	UpdateUserMetadata = UserMetadataTable.UpdateQuery(dbSession)

	GroupMetadataTable = table.New(GroupsTableMetadata)
	SelectGroupMetadata = GroupMetadataTable.SelectQuery(dbSession)

	RoomMetadataTable = table.New(RoomsTableMetadata)
	SelectRoomMetadata = RoomMetadataTable.SelectQuery(dbSession)

	AddUserFCMToken = UserMetadataTable.UpdateBuilder().Add("tokens").Query(dbSession)
	DeleteUserFCMToken = UserMetadataTable.UpdateBuilder().Remove("tokens").Query(dbSession)

	AddUserPendingRequest = UserMetadataTable.UpdateBuilder().Add("pendinglist").Query(dbSession)
	DeleteUserPendingRequest = UserMetadataTable.UpdateBuilder().Remove("pendinglist").Query(dbSession)
	SelectUserPendingRequest = UserMetadataTable.SelectBuilder("pendinglist").Query(dbSession)

	AddUserFriend = UserMetadataTable.UpdateBuilder().Add("friendslist").Query(dbSession)
	DeleteUserFriend = UserMetadataTable.UpdateBuilder().Remove("friendslist").Query(dbSession)
	SelectUserFriend = UserMetadataTable.SelectBuilder("friendslist").Query(dbSession)

	ChatMessageTable = table.New(ChatMessageMetadata)
	InsertChatMessage = ChatMessageTable.InsertQuery(dbSession)
	GroupsMessageTable = table.New(GroupsMessageMetadata)
	InsertGroupsMessage = GroupsMessageTable.InsertQuery(dbSession)
	RoomsMessageTable = table.New(RoomsMessageMetadata)
	InsertRoomsMessage = RoomsMessageTable.InsertQuery(dbSession)
}

type User_udt struct {
	gocqlx.UDT
	Userid string
	Name   string
	Image  *string
}

// MarshalUDT implements UDTMarshaler.
func (u User_udt) MarshalUDT(name string, info gocql.TypeInfo) ([]byte, error) {
	f := gocqlx.DefaultMapper.FieldByName(reflect.ValueOf(u), name)
	return gocql.Marshal(info, f.Interface())
}

// UnmarshalUDT implements UDTUnmarshaler.
func (u *User_udt) UnmarshalUDT(name string, info gocql.TypeInfo, data []byte) error {
	f := gocqlx.DefaultMapper.FieldByName(reflect.ValueOf(u), name)
	return gocql.Unmarshal(info, data, f.Addr().Interface())
}

type UserMetadata struct {
	Userid      string
	Name        string
	Username    *string
	Image       *string
	Tokens      []string
	Groupslist  []string
	Roomslist   []string
	Pendinglist []string
	Friendslist []string
}

type GroupMetadata struct {
	Groupid     string
	Name        string
	Description *string
	Image       *string
	Userslist   map[string]User_udt
}

type RoomMetadata struct {
	Roomid       string
	Name         string
	Description  *string
	Image        *string
	Userslist    map[string]User_udt
	Channelslist map[string]string
}

func updateUserMetadata(data *UserMetadata) error {
	if q := UpdateUserMetadata.BindStruct(data); q.Err() != nil {
		log.Error().Str("where", "update user metadata").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return errors.New("internal server error")
	}
	if err := UpdateUserMetadata.Exec(); err != nil {
		log.Error().Str("where", "update user metadata").Str("type", "failed to execute query").Msg(err.Error())
		return errors.New("internal server error")
	}
	return nil
}

func getUserMetadata(userId string) (*UserMetadata, error) {
	if q := SelectUserMetadata.BindMap(qb.M{"userid": userId}); q.Err() != nil {
		log.Error().Str("where", "get user metadata").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return nil, errors.New("internal server error")
	}
	rows := make([]*UserMetadata, 1)
	if err := SelectUserMetadata.Select(&rows); err != nil {
		log.Error().Str("where", "get user metadata").Str("type", "failed to execute query").Msg(err.Error())
		return nil, errors.New("internal server error")
	}
	return rows[0], nil
}

func getGroupMetadata(groupId string) (*GroupMetadata, error) {
	if q := SelectGroupMetadata.BindMap(qb.M{"groupid": groupId}); q.Err() != nil {
		log.Error().Str("where", "get group metadata").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return nil, errors.New("internal server error")
	}
	rows := make([]*GroupMetadata, 1)
	if err := SelectGroupMetadata.Select(&rows); err != nil {
		log.Error().Str("where", "get group metadata").Str("type", "failed to execute query").Msg(err.Error())
		return nil, errors.New("internal server error")
	}
	return rows[0], nil
}

func getRoomMetadata(roomId string) (*RoomMetadata, error) {
	if q := SelectRoomMetadata.BindMap(qb.M{"roomid": roomId}); q.Err() != nil {
		log.Error().Str("where", "get room metadata").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return nil, errors.New("internal server error")
	}
	rows := make([]*RoomMetadata, 1)
	if err := SelectRoomMetadata.Select(&rows); err != nil {
		log.Error().Str("where", "get room metadata").Str("type", "failed to execute query").Msg(err.Error())
		return nil, errors.New("internal server error")
	}
	return rows[0], nil
}

type UserPendingListUpdate struct {
	Userid      string
	Pendinglist []string
}

func addUserPendingRequest(user *UserPendingListUpdate) error {
	if q := AddUserPendingRequest.BindStruct(user); q.Err() != nil {
		log.Error().Str("where", "add pending friend request").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return errors.New("internal server error")
	}
	if err := AddUserPendingRequest.Exec(); err != nil {
		log.Error().Str("where", "add pending friend request").Str("type", "failed to execute query").Msg(err.Error())
		return errors.New("internal server error")
	}
	return nil
}

func removeUserPendingRequest(userId *UserPendingListUpdate) error {
	if q := DeleteUserPendingRequest.BindStruct(userId); q.Err() != nil {
		log.Error().Str("where", "delete pending friend request").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return errors.New("internal server error")
	}
	if err := DeleteUserPendingRequest.Exec(); err != nil {
		log.Error().Str("where", "delete pending friend request").Str("type", "failed to execute query").Msg(err.Error())
		return errors.New("internal server error")
	}
	return nil
}

func selectUserPendingRequest(userId string) ([]UserPendingListUpdate, error) {
	if q := SelectUserPendingRequest.BindMap(qb.M{"userid": userId}); q.Err() != nil {
		log.Error().Str("where", "get user metadata").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return nil, errors.New("internal server error")
	}
	rows := make([]UserPendingListUpdate, 1)
	if err := SelectUserPendingRequest.Select(&rows); err != nil {
		log.Error().Str("where", "get user metadata").Str("type", "failed to execute query").Msg(err.Error())
		return nil, errors.New("internal server error")
	}
	return rows, nil
}

// Gotta remove user id somehow
type UserFriendListUpdate struct {
	Userid string
	// Username    string
	Friendslist []string
}

func addUserFriend(user *UserFriendListUpdate) error {
	if q := AddUserFriend.BindStruct(user); q.Err() != nil {
		log.Error().Str("where", "add friend").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return errors.New("internal server error")
	}
	if err := AddUserFriend.Exec(); err != nil {
		log.Error().Str("where", "add friend").Str("type", "failed to execute query").Msg(err.Error())
		return errors.New("internal server error")
	}
	return nil
}

func removeUserFriend(user *UserFriendListUpdate) error {
	if q := DeleteUserFriend.BindStruct(user); q.Err() != nil {
		log.Error().Str("where", "delete friend").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return errors.New("internal server error")
	}
	if err := DeleteUserFriend.Exec(); err != nil {
		log.Error().Str("where", "delete friend").Str("type", "failed to execute query").Msg(err.Error())
		return errors.New("internal server error")
	}
	return nil
}

func selectUserFriend(userid string) ([]UserFriendListUpdate, error) {
	if q := SelectUserFriend.BindMap(qb.M{"userid": userid}); q.Err() != nil {
		log.Error().Str("where", "get friends list").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return nil, errors.New("internal server error")
	}
	rows := make([]UserFriendListUpdate, 1)
	if err := SelectUserFriend.Select(&rows); err != nil {
		log.Error().Str("where", "get friends list").Str("type", "failed to execute query").Msg(err.Error())
		return nil, errors.New("internal server error")
	}
	return rows, nil
}

// TODO: Remove receiving name and image, backend should have it already
type UserFCMTokenUpdate struct {
	Userid string
	Tokens []string
	Image  string
	Name   string
}

func addFCMToken(tok *UserFCMTokenUpdate) error {
	if q := AddUserFCMToken.BindStruct(tok); q.Err() != nil {
		log.Error().Str("where", "add fcm token").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return errors.New("internal server error")
	}
	if err := AddUserFCMToken.Exec(); err != nil {
		log.Error().Str("where", "add fcm token").Str("type", "failed to execute query").Msg(err.Error())
		return errors.New("internal server error")
	}
	return nil
}

func removeFCMToken(tok *UserFCMTokenUpdate) error {
	if q := DeleteUserFCMToken.BindStruct(tok); q.Err() != nil {
		log.Error().Str("where", "delete fcm token").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return errors.New("internal server error")
	}
	if err := DeleteUserFCMToken.Exec(); err != nil {
		log.Error().Str("where", "delete fcm token").Str("type", "failed to execute query").Msg(err.Error())
		return errors.New("internal server error")
	}
	return nil
}

type ChatMessage struct {
	Exchange_id string    `json:"exchange_id,omitempty"`
	Msgid       string    `json:"msgId,omitempty"`
	Fromuser    string    `json:"fromUser"`
	Touser      string    `json:"toUser"`
	Msgtime     time.Time `json:"time"`
	Content     *string   `json:"content,omitempty"`
	Mediaid     *string   `json:"media,omitempty"`
	Replyto     *string   `json:"replyTo,omitempty"`
	Es_query    string    `json:"es_query,omitempty"`
	Es_options  string    `json:"es_options,omitempty"`
}

type GroupsMessage struct {
	Exchange_id string    `json:"exchange_id,omitempty"`
	Msgid       string    `json:"msgId,omitempty"`
	Fromuser    string    `json:"fromUser"`
	Groupid     string    `json:"groupId"`
	Msgtime     time.Time `json:"time"`
	Content     *string   `json:"content,omitempty"`
	Mediaid     *string   `json:"media,omitempty"`
	Replyto     *string   `json:"replyTo,omitempty"`
	Es_query    string    `json:"es_query,omitempty"`
	Es_options  string    `json:"es_options,omitempty"`
}

type RoomsMessage struct {
	Exchange_id string    `json:"exchange_id,omitempty"`
	Msgid       string    `json:"msgId,omitempty"`
	Fromuser    string    `json:"fromUser"`
	Roomid      string    `json:"roomid"`
	Channelid   string    `json:"channelid"`
	Msgtime     time.Time `json:"time"`
	Content     *string   `json:"content,omitempty"`
	Mediaid     *string   `json:"media,omitempty"`
	Replyto     *string   `json:"replyTo,omitempty"`
	Es_query    string    `json:"es_query,omitempty"`
	Es_options  string    `json:"es_options,omitempty"`
}

func getExchangeId(msg *WSMessage) (string, error) {
	switch msg.Type {
	case "ChatMessage":
		uids := []string{msg.FromUser, msg.ToUser}
		sort.Strings(uids)
		return uids[0] + ":" + uids[1], nil
	case "GroupsMessage":
		uids := []string{msg.GroupId}
		sort.Strings(uids)
		return uids[0], nil
	case "RoomsMessage":
		uids := []string{msg.RoomId}
		sort.Strings(uids)
		return uids[0], nil
	default:
		return "", errors.New("unknown message type")
	}
}

func addMessage(msg *WSMessage) error {
	// Get exchange id
	exchange_id, err := getExchangeId(msg)
	if err != nil {
		return err
	}

	// Handle media content
	if msg.MediaData != nil {
		if msg.MediaData.Name == "" || len(msg.MediaData.Bytes) == 0 {
			return errors.New("invalid media file, check non empty name, bytes > 0")
		}
		// TODO: COMPRESS AND STORE TO SAVE STORAGE SPACE (LATER)
		mediaBytes, _ := json.Marshal(msg.MediaData)
		mediaId := xid.New().String()

		if _, err := minioClient.PutObject(context.Background(), miniobucket, mediaId, bytes.NewReader(mediaBytes), -1, minio.PutObjectOptions{ContentType: "application/json", UserMetadata: map[string]string{"x-amz-meta-key": exchange_id}}); err != nil {
			log.Error().Str("where", "ws read routine").Str("type", "uploading to minio failed at put object").Msg(err.Error())
			return errors.New("internal server error")
		}
		msg.Media = mediaId
		msg.MediaData = nil
	}

	// Use current time of server // We don't care about user sending time, we use receiving time
	msg.Time = time.Now()
	jsonBytes, _ := json.Marshal(msg)

	msgId := xid.New().String()

	// Handle different message types
	switch msg.Type {
	case "ChatMessage":
		var data ChatMessage
		if err := json.Unmarshal(jsonBytes, &data); err != nil {
			return err
		}
		data.Exchange_id = exchange_id
		data.Msgid = msgId
		data.Msgtime = time.Now()
		if q := InsertChatMessage.BindStruct(data); q.Err() != nil {
			log.Error().Str("where", "insert chat message").Str("type", "failed to bind struct").Msg(q.Err().Error())
			return errors.New("internal server error")
		}
		if err := InsertChatMessage.Exec(); err != nil {
			log.Error().Str("where", "insert chat message").Str("type", "failed to execute query").Msg(err.Error())
			return errors.New("internal server error")
		}
	case "GroupsMessage":
		var data GroupsMessage
		if err := json.Unmarshal(jsonBytes, &data); err != nil {
			return err
		}
		data.Exchange_id = exchange_id
		data.Msgid = msgId
		data.Msgtime = time.Now()
		if q := InsertGroupsMessage.BindStruct(data); q.Err() != nil {
			log.Error().Str("where", "insert chat message").Str("type", "failed to bind struct").Msg(q.Err().Error())
			return errors.New("internal server error")
		}
		if err := InsertGroupsMessage.Exec(); err != nil {
			log.Error().Str("where", "insert groups message").Str("type", "failed to execute query").Msg(err.Error())
			return errors.New("internal server error")
		}
	case "RoomsMessage":
		var data RoomsMessage
		if err := json.Unmarshal(jsonBytes, &data); err != nil {
			return err
		}
		data.Exchange_id = exchange_id
		data.Msgid = msgId
		data.Msgtime = time.Now()
		if q := InsertRoomsMessage.BindStruct(data); q.Err() != nil {
			log.Error().Str("where", "insert rooms message").Str("type", "failed to bind struct").Msg(q.Err().Error())
			return errors.New("internal server error")
		}
		if err := InsertRoomsMessage.Exec(); err != nil {
			log.Error().Str("where", "insert rooms message").Str("type", "failed to execute query").Msg(err.Error())
			return errors.New("internal server error")
		}
	default:
		return errors.New("unknown message type")
	}

	msg.MsgId = msgId
	return nil
}

func dbInsertRoutine(inChannel <-chan interface{}, outChannel chan<- interface{}, quit <-chan bool) {
	var err error
	for {
		select {
		case data := <-inChannel:
			msg, _ := data.(WSMessage)
			err = addMessage(&msg)
			if err != nil {
				var emsg string
				if err.Error() == "unknown message type" {
					emsg = "Unknown message type"
				} else {
					emsg = "Server error, contact support"
					log.Error().Str("where", "add message").Str("type", "failed to add messsage to db").Msg(err.Error())
				}
				outChannel <- WSError{Error: emsg}
			} else {
				outChannel <- msg
			}
		case <-quit:
			return
		}
	}
}
