package main

import (
	"errors"
	"reflect"

	"github.com/gocql/gocql"
	"github.com/rs/zerolog/log"
	"github.com/scylladb/gocqlx/qb"
	"github.com/scylladb/gocqlx/v2"
	"github.com/scylladb/gocqlx/v2/table"
)

var UsersTableMetadata = table.Metadata{
	Name:    "yaroom.users",
	Columns: []string{"userid", "name", "image", "username", "tokens", "groupslist", "roomslist", "friendslist"},
	PartKey: []string{"userid"},
}

var GroupsTableMetadata = table.Metadata{
	Name:    "yaroom.groups",
	Columns: []string{"groupid", "name", "image", "description", "userslist"},
	PartKey: []string{"groupid"},
}

var RoomsTableMetadata = table.Metadata{
	Name:    "yaroom.rooms",
	Columns: []string{"rooomid", "name", "image", "description", "userslist", "channelslist"},
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
