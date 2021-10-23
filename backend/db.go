package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
	"strings"

	"github.com/gocql/gocql"
	"github.com/rs/xid"
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

var GroupTableMetadata = table.Metadata{
	Name:    "yaroom.groups",
	Columns: []string{"groupid", "name", "image", "description", "userslist"},
	PartKey: []string{"groupid"},
}

var RoomTableMetadata = table.Metadata{
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

var AddGroupToUser *gocqlx.Queryx
var DeleteGroupFromUser *gocqlx.Queryx
var SelectGroupsOfUser *gocqlx.Queryx

var AddRoomToUser *gocqlx.Queryx
var DeleteRoomFromUser *gocqlx.Queryx
var SelectRoomsOfUser *gocqlx.Queryx

// var AddUserToGroup *gocqlx.Queryx
// var DeleteUserFromGroup *gocqlx.Queryx
var SelectUsersOfGroup *gocqlx.Queryx
var SelectUsersOfRoom *gocqlx.Queryx

func setupDB() {
	UserMetadataTable = table.New(UsersTableMetadata)
	SelectUserMetadata = UserMetadataTable.SelectQuery(dbSession)
	UpdateUserMetadata = UserMetadataTable.UpdateQuery(dbSession)

	GroupMetadataTable = table.New(GroupTableMetadata)
	SelectGroupMetadata = GroupMetadataTable.SelectQuery(dbSession)
	UpdateGroupMetadata = GroupMetadataTable.UpdateQuery(dbSession)

	RoomMetadataTable = table.New(RoomTableMetadata)
	SelectRoomMetadata = RoomMetadataTable.SelectQuery(dbSession)

	AddUserFCMToken = UserMetadataTable.UpdateBuilder().Add("tokens").Query(dbSession)
	DeleteUserFCMToken = UserMetadataTable.UpdateBuilder().Remove("tokens").Query(dbSession)

	AddUserPendingRequest = UserMetadataTable.UpdateBuilder().Add("pendinglist").Query(dbSession)
	DeleteUserPendingRequest = UserMetadataTable.UpdateBuilder().Remove("pendinglist").Query(dbSession)
	SelectUserPendingRequest = UserMetadataTable.SelectBuilder("pendinglist").Query(dbSession)

	AddUserFriend = UserMetadataTable.UpdateBuilder().Add("friendslist").Query(dbSession)
	DeleteUserFriend = UserMetadataTable.UpdateBuilder().Remove("friendslist").Query(dbSession)
	SelectUserFriend = UserMetadataTable.SelectBuilder("friendslist").Query(dbSession)

	AddGroupToUser = UserMetadataTable.UpdateBuilder().Add("groupslist").Query(dbSession)
	DeleteGroupFromUser = UserMetadataTable.UpdateBuilder().Remove("groupslist").Query(dbSession)
	SelectGroupsOfUser = UserMetadataTable.SelectBuilder("groupslist").Query(dbSession)

	AddRoomToUser = UserMetadataTable.UpdateBuilder().Add("roomslist").Query(dbSession)
	DeleteRoomFromUser = UserMetadataTable.UpdateBuilder().Remove("roomslist").Query(dbSession)
	SelectRoomsOfUser = UserMetadataTable.SelectBuilder("roomslist").Query(dbSession)

	// AddUserToGroup = GroupMetadataTable.UpdateBuilder().Add("userslist").Query(dbSession)
	// DeleteUserFromGroup = GroupMetadataTable.UpdateBuilder().Remove("userslist").Query(dbSession)
	SelectUsersOfGroup = GroupMetadataTable.SelectBuilder("userslist").Query(dbSession)

	SelectUsersOfRoom = RoomMetadataTable.SelectBuilder("userslist").Query(dbSession)

	ChatMessageTable = table.New(ChatMessageMetadata)
	InsertChatMessage = ChatMessageTable.InsertQuery(dbSession)
	GroupMessageTable = table.New(GroupMessageMetadata)
	InsertGroupMessage = GroupMessageTable.InsertQuery(dbSession)
	RoomMessageTable = table.New(RoomMessageMetadata)
	InsertRoomMessage = RoomMessageTable.InsertQuery(dbSession)
}

type User_udt struct {
	gocqlx.UDT
	Userid string  `json:"userId" db:"userid"`
	Name   string  `json:"name" db:"name"`
	Image  *string `json:"profileImg" db:"image"`
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
	Userslist   []User_udt
}

type RoomMetadata struct {
	Roomid       string
	Name         string
	Description  *string
	Image        *string
	Userslist    []User_udt
	Channelslist map[string]string
}

type UserDetails struct {
	UserData  UserMetadata
	GroupData []GroupMetadata
	RoomData  []RoomMetadata
	Users     []User
}

type RoomsListOfUserUpdate struct {
	Userid    string
	Roomslist []string
}

type UserFCMTokenUpdate struct {
	Userid string
	Tokens []string
}

type GroupsListOfUserUpdate struct {
	Userid     string
	Groupslist []string
}

type FriendsListOfUserUpdate struct {
	Userid      string
	Friendslist []string
}

type PendingListOfUserUpdate struct {
	Userid      string
	Pendinglist []string
}

type UsersListOfGroupUpdate struct {
	Groupid   string
	Userslist []User_udt
}

type UsersListOfRoomUpdate struct {
	Roomid    string
	Userslist []User_udt
}

type User struct {
	Userid string  `json:"userId" db:"userid"`
	Name   string  `json:"name" db:"name"`
	Image  *string `json:"profileImg" db:"image"`
}

func updateUserMetadata(data *UserMetadata) error {
	in := dbSession.Query(qb.Update("yaroom.users").SetLit("name", "'"+data.Name+"'").SetLit("username", "'"+*data.Username+"'").Where(qb.EqLit("userid", "'"+data.Userid+"'")).ToCql())
	if err := in.ExecRelease(); err != nil {
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
	if groupId == "" {
		return nil, nil
	}
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

func convertSetToString(data []User_udt) string {
	if len(data) == 0 {
		return "null"
	}
	var s string
	s += "{"
	for _, val := range data {
		// fmt.Println(key, val)
		if val.Image != nil {
			s += fmt.Sprintf("{userid:'%s', name:'%s', image:'%s'},", val.Userid, val.Name, *val.Image)
		} else {
			s += fmt.Sprintf("{userid:'%s', name:'%s', image:''},", val.Userid, val.Name)
		}
	}
	s = s[:len(s)-1]
	s += "}"
	return s
}

func convertMapToString(data map[string]string) string {
	var s string
	s += "{"
	for key, val := range data {
		// fmt.Println(key, val)
		s += fmt.Sprintf("'%s':'%s',", key, val)
	}
	s = s[:len(s)-1]
	s += "}"
	return s
}

func updateGroupMetadata(data *GroupMetadata) (*GroupMetadata, error) {
	if data.Groupid == "" {
		data.Groupid = xid.New().String()
	}
	paddedGroupId := "'" + data.Groupid + "'"
	groupMeta, err := getGroupMetadata(data.Groupid)
	if err != nil {
		log.Error().Str("where", "get group details").Str("type", "error occured in retrieving group metadata").Msg(err.Error())
		return nil, err
	}
	if groupMeta == nil {
		in := dbSession.Query(qb.Insert("yaroom.groups").LitColumn("groupid", paddedGroupId).LitColumn("name", "'"+data.Name+"'").LitColumn("image", "'"+*data.Image+"'").LitColumn("description", "'"+*data.Description+"'").LitColumn("userslist", convertSetToString(data.Userslist)).ToCql())
		if err := in.ExecRelease(); err != nil {
			return nil, err
		}
		for _, user := range data.Userslist {
			if err := addGroupToUser(&GroupsListOfUserUpdate{Userid: user.Userid, Groupslist: []string{data.Groupid}}); err != nil {
				return nil, err
			}
		}
		if err := addUserToGroup(&UsersListOfGroupUpdate{Groupid: data.Groupid, Userslist: data.Userslist}); err != nil {
			return nil, err
		}
	} else {
		in := dbSession.Query(qb.Update("yaroom.groups").SetLit("name", "'"+data.Name+"'").SetLit("description", "'"+*data.Description+"'").SetLit("image", "'"+*data.Image+"'").Where(qb.EqLit("groupid", "'"+data.Groupid+"'")).ToCql())
		if err := in.ExecRelease(); err != nil {
			log.Error().Str("where", "update Group metadata").Str("type", "failed to execute query").Msg(err.Error())
			return nil, errors.New("internal server error")
		}
		for _, user := range data.Userslist {
			if err := addGroupToUser(&GroupsListOfUserUpdate{Userid: user.Userid, Groupslist: []string{data.Groupid}}); err != nil {
				return nil, err
			}
		}
		if err := addUserToGroup(&UsersListOfGroupUpdate{Groupid: data.Groupid, Userslist: data.Userslist}); err != nil {
			return nil, err
		}
	}
	return data, nil
}

func updateRoomMetadata(data *RoomMetadata) (*RoomMetadata, error) {
	if data.Roomid == "" {
		data.Roomid = xid.New().String()
	}
	paddedRoomId := "'" + data.Roomid + "'"
	roomMeta, err := getRoomMetadata(data.Roomid)
	if err != nil {
		log.Error().Str("where", "get Room details").Str("type", "error occured in retrieving room metadata").Msg(err.Error())
		return nil, err
	}
	temp := make(map[string]string)
	for key, val := range data.Channelslist {
		if key == "" {
			temp[xid.New().String()] = val
		} else {
			temp[key] = val
		}
	}
	data.Channelslist = temp

	if roomMeta == nil {
		in := dbSession.Query(qb.Insert("yaroom.rooms").LitColumn("roomid", paddedRoomId).LitColumn("name", "'"+data.Name+"'").LitColumn("image", "'"+*data.Image+"'").LitColumn("description", "'"+*data.Description+"'").LitColumn("userslist", convertSetToString(data.Userslist)).LitColumn("channelslist", convertMapToString(data.Channelslist)).ToCql())
		if err := in.ExecRelease(); err != nil {
			return nil, err
		}
		for _, user := range data.Userslist {
			if err := addRoomToUser(&RoomsListOfUserUpdate{Userid: user.Userid, Roomslist: []string{data.Roomid}}); err != nil {
				return nil, err
			}
		}
		if err := addUserToRoom(&UsersListOfRoomUpdate{Roomid: data.Roomid, Userslist: data.Userslist}); err != nil {
			return nil, err
		}
	} else {
		in := dbSession.Query(qb.Update("yaroom.rooms").SetLit("name", "'"+data.Name+"'").SetLit("description", "'"+*data.Description+"'").SetLit("image", "'"+*data.Image+"'").SetLit("channelslist", convertMapToString(data.Channelslist)).Where(qb.EqLit("roomid", "'"+data.Roomid+"'")).ToCql())
		if err := in.ExecRelease(); err != nil {
			log.Error().Str("where", "update Room metadata").Str("type", "failed to execute query").Msg(err.Error())
			return nil, errors.New("internal server error")
		}
		for _, user := range data.Userslist {
			if err := addRoomToUser(&RoomsListOfUserUpdate{Userid: user.Userid, Roomslist: []string{data.Roomid}}); err != nil {
				return nil, err
			}
		}
		if err := addUserToRoom(&UsersListOfRoomUpdate{Roomid: data.Roomid, Userslist: data.Userslist}); err != nil {
			return nil, err
		}
	}
	return data, nil
}

func addRoomToUser(user *RoomsListOfUserUpdate) error {
	if q := AddRoomToUser.BindStruct(user); q.Err() != nil {
		log.Error().Str("where", "add room to user").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return errors.New("internal server error")
	}
	if err := AddRoomToUser.Exec(); err != nil {
		log.Error().Str("where", "add room to user").Str("type", "failed to execute query").Msg(err.Error())
		return errors.New("internal server error")
	}
	return nil
}

func deleteRoomFromUser(user *RoomsListOfUserUpdate) error {
	if q := DeleteRoomFromUser.BindStruct(user); q.Err() != nil {
		log.Error().Str("where", "delete room from user").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return errors.New("internal server error")
	}
	if err := DeleteRoomFromUser.Exec(); err != nil {
		log.Error().Str("where", "delete room from user").Str("type", "failed to execute query").Msg(err.Error())
		return errors.New("internal server error")
	}
	return nil
}

func selectRoomsOfUser(userId string) ([]RoomsListOfUserUpdate, error) {
	if q := SelectRoomsOfUser.BindMap(qb.M{"userid": userId}); q.Err() != nil {
		log.Error().Str("where", "get rooms of user").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return nil, errors.New("internal server error")
	}
	rows := make([]RoomsListOfUserUpdate, 1)
	if err := SelectRoomsOfUser.Select(&rows); err != nil {
		log.Error().Str("where", "get rooms of user").Str("type", "failed to execute query").Msg(err.Error())
		return nil, errors.New("internal server error")
	}
	return rows, nil
}

func addUserToRoom(room *UsersListOfRoomUpdate) error {
	in := dbSession.Query(qb.Update("yaroom.rooms").AddLit("userslist", convertSetToString(room.Userslist)).Where(qb.EqLit("roomid", "'"+room.Roomid+"'")).ToCql())
	if err := in.ExecRelease(); err != nil {
		log.Error().Str("where", "add user to group").Str("type", "failed to execute query").Msg(err.Error())
		return err
	}
	return nil
}

func deleteUserFromRoom(user *UsersListOfRoomUpdate) error {
	in := dbSession.Query(qb.Update("yaroom.rooms").RemoveLit("userslist", convertSetToString(user.Userslist)).Where(qb.EqLit("roomid", "'"+user.Roomid+"'")).ToCql())
	if err := in.ExecRelease(); err != nil {
		log.Error().Str("where", "delete user from room").Str("type", "failed to execute query").Msg(err.Error())
		return err
	}
	return nil
}

func selectUsersFromRoom(userId string) ([]UsersListOfRoomUpdate, error) {
	if q := SelectUsersOfRoom.BindMap(qb.M{"userid": userId}); q.Err() != nil {
		log.Error().Str("where", "get users of room").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return nil, errors.New("internal server error")
	}
	rows := make([]UsersListOfRoomUpdate, 1)
	if err := SelectUsersOfGroup.Select(&rows); err != nil {
		log.Error().Str("where", "get users of room").Str("type", "failed to execute query").Msg(err.Error())
		return nil, errors.New("internal server error")
	}
	return rows, nil
}

func getRoomMetadata(roomId string) (*RoomMetadata, error) {
	if roomId == "" {
		return nil, nil
	}
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

func getUserDetails(userId string, name string) (*UserDetails, error) {
	paddedUserId := "'" + userId + "'"
	paddedName := "'" + name + "'"
	userMeta, err := getUserMetadata(userId)
	if err != nil {
		log.Error().Str("where", "get user details").Str("type", "error occured in retrieving user metadata").Msg(err.Error())
		return nil, err
	}
	if userMeta == nil {
		// New user, add user to demo rooms and groups
		in := dbSession.Query(qb.Insert("yaroom.users").LitColumn("userid", paddedUserId).LitColumn("name", paddedName).LitColumn("image", "''").LitColumn("username", paddedName).LitColumn("groupslist", "{'group-demo-1', 'group-demo-2'}").LitColumn("roomslist", "{'room-demo-1', 'room-demo-2'}").ToCql())
		if err := in.ExecRelease(); err != nil {
			return nil, err
		}
		err := addUserFriend(&FriendsListOfUserUpdate{
			Userid:      userId,
			Friendslist: []string{"john-doe", "alice-jane"},
		})
		if err != nil {
			log.Error().Str("where", "adding new user").Str("type", "error occured in db op").Msg(err.Error())
			return nil, err
		}
		err = addUserFriend(&FriendsListOfUserUpdate{
			Userid:      "alice-jane",
			Friendslist: []string{userId},
		})
		if err != nil {
			log.Error().Str("where", "adding new user").Str("type", "error occured in db op").Msg(err.Error())
			return nil, err
		}
		err = addUserFriend(&FriendsListOfUserUpdate{
			Userid:      "john-doe",
			Friendslist: []string{userId},
		})
		if err != nil {
			log.Error().Str("where", "adding new user").Str("type", "error occured in db op").Msg(err.Error())
			return nil, err
		}
		if err = addUserToGroup(&UsersListOfGroupUpdate{Groupid: "group-demo-1", Userslist: []User_udt{{Userid: userId, Name: name}}}); err != nil {
			log.Error().Str("where", "adding new user").Str("type", "error occured in db op").Msg(err.Error())
			return nil, err
		}
		if err = addUserToGroup(&UsersListOfGroupUpdate{Groupid: "group-demo-2", Userslist: []User_udt{{Userid: userId, Name: name}}}); err != nil {
			log.Error().Str("where", "adding new user").Str("type", "error occured in db op").Msg(err.Error())
			return nil, err
		}
		gids := []string{"group-demo-1", "group-demo-2"}
		for _, gid := range gids {
			obj, err := getGroupMetadata(gid)
			if err != nil {
				return nil, err
			}
			encObj, err := json.Marshal(*obj)
			if err != nil {
				return nil, err
			}
			m := make(map[string]interface{})
			_ = json.Unmarshal(encObj, &m)
			m["update"] = "group"
			encAug, _ := json.Marshal(m)
			sendUpdateOnStream([]string{"GROUP:" + gid}, encAug)
		}
		if err = addUserToRoom(&UsersListOfRoomUpdate{Roomid: "room-demo-1", Userslist: []User_udt{{Userid: userId, Name: name}}}); err != nil {
			log.Error().Str("where", "adding new user to room").Str("type", "error occured in db op").Msg(err.Error())
			return nil, err
		}
		if err = addUserToRoom(&UsersListOfRoomUpdate{Roomid: "room-demo-2", Userslist: []User_udt{{Userid: userId, Name: name}}}); err != nil {
			log.Error().Str("where", "adding new user to room").Str("type", "error occured in db op").Msg(err.Error())
			return nil, err
		}
		rids := []string{"room-demo-1", "room-demo-2"}
		for _, rid := range rids {
			obj, err := getRoomMetadata(rid)
			if err != nil {
				return nil, err
			}
			encObj, err := json.Marshal(*obj)
			if err != nil {
				return nil, err
			}
			m := make(map[string]interface{})
			_ = json.Unmarshal(encObj, &m)
			m["update"] = "room"
			encAug, _ := json.Marshal(m)
			sendUpdateOnStream([]string{"ROOM:" + rid}, encAug)
		}
		userMeta, err = getUserMetadata(userId)
		if err != nil {
			log.Error().Str("where", "adding new user").Str("type", "error occured in db op").Msg(err.Error())
			return nil, err
		}
	}
	var ret UserDetails
	ret.UserData = *userMeta
	ret.GroupData = make([]GroupMetadata, 0)
	usersList := make([]string, 0)
	usersList = append(usersList, userMeta.Friendslist...)
	usersList = append(usersList, userMeta.Pendinglist...)
	println("********************************************************************")
	for _, k := range usersList {
		fmt.Printf("USERSLIST %v ---------------\n", k)
	}
	ret.Users, err = getUsers(usersList)
	if err != nil {
		log.Error().Str("where", "get users").Str("type", "error occured in retrieving friends and pending users").Msg(err.Error())
	}
	for _, group := range userMeta.Groupslist {
		val, err := getGroupMetadata(group)
		if err != nil {
			log.Error().Str("where", "get group metadata").Str("type", "error occured in retrieving group metadata").Msg(err.Error())
			continue
		}
		if val == nil {
			log.Error().Str("where", "get group metadata").Str("type", "error occured in retrieving group metadata").Msg(err.Error())
			continue
		}
		ret.GroupData = append(ret.GroupData, *val)
	}
	ret.RoomData = make([]RoomMetadata, 0)
	for _, room := range userMeta.Roomslist {
		val, err := getRoomMetadata(room)
		if err != nil {
			log.Error().Str("where", "get room metadata").Str("type", "error occured in retrieving room metadata").Msg(err.Error())
			continue
		}
		if val == nil {
			log.Error().Str("where", "get room metadata").Str("type", "error occured in retrieving room metadata").Msg(err.Error())
			continue
		}
		ret.RoomData = append(ret.RoomData, *val)
	}
	return &ret, nil
}

func addGroupToUser(user *GroupsListOfUserUpdate) error {
	if q := AddGroupToUser.BindStruct(user); q.Err() != nil {
		log.Error().Str("where", "add group to user").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return errors.New("internal server error")
	}
	if err := AddGroupToUser.Exec(); err != nil {
		log.Error().Str("where", "add group to user").Str("type", "failed to execute query").Msg(err.Error())
		return errors.New("internal server error")
	}
	return nil
}

func deleteGroupFromUser(user *GroupsListOfUserUpdate) error {
	if q := DeleteGroupFromUser.BindStruct(user); q.Err() != nil {
		log.Error().Str("where", "delete group from user").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return errors.New("internal server error")
	}
	if err := DeleteGroupFromUser.Exec(); err != nil {
		log.Error().Str("where", "delete group from user").Str("type", "failed to execute query").Msg(err.Error())
		return errors.New("internal server error")
	}
	return nil
}

func selectGroupsOfUser(userId string) ([]GroupsListOfUserUpdate, error) {
	if q := SelectGroupsOfUser.BindMap(qb.M{"userid": userId}); q.Err() != nil {
		log.Error().Str("where", "get groups of user").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return nil, errors.New("internal server error")
	}
	rows := make([]GroupsListOfUserUpdate, 1)
	if err := SelectGroupsOfUser.Select(&rows); err != nil {
		log.Error().Str("where", "get groups of user").Str("type", "failed to execute query").Msg(err.Error())
		return nil, errors.New("internal server error")
	}
	return rows, nil
}

func addUserToGroup(group *UsersListOfGroupUpdate) error {
	in := dbSession.Query(qb.Update("yaroom.groups").AddLit("userslist", convertSetToString(group.Userslist)).Where(qb.EqLit("groupid", "'"+group.Groupid+"'")).ToCql())
	if err := in.ExecRelease(); err != nil {
		log.Error().Str("where", "add user to group").Str("type", "failed to execute query").Msg(err.Error())
		return err
	}
	return nil
}

func deleteUserFromGroup(user *UsersListOfGroupUpdate) error {
	in := dbSession.Query(qb.Update("yaroom.groups").RemoveLit("userslist", convertSetToString(user.Userslist)).Where(qb.EqLit("groupid", "'"+user.Groupid+"'")).ToCql())
	if err := in.ExecRelease(); err != nil {
		log.Error().Str("where", "delete user from group").Str("type", "failed to execute query").Msg(err.Error())
		return err
	}
	return nil
}

func selectUsersFromGroup(groupId string) ([]UsersListOfGroupUpdate, error) {
	if q := SelectUsersOfGroup.BindMap(qb.M{"groupid": groupId}); q.Err() != nil {
		log.Error().Str("where", "get users of group").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return nil, errors.New("internal server error")
	}
	rows := make([]UsersListOfGroupUpdate, 1)
	if err := SelectUsersOfGroup.Select(&rows); err != nil {
		log.Error().Str("where", "get users of group").Str("type", "failed to execute query").Msg(err.Error())
		return nil, errors.New("internal server error")
	}
	return rows, nil
}

func addUserPendingRequest(user *PendingListOfUserUpdate) error {
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

func removeUserPendingRequest(user *PendingListOfUserUpdate) error {
	if q := DeleteUserPendingRequest.BindStruct(user); q.Err() != nil {
		log.Error().Str("where", "delete pending friend request").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return errors.New("internal server error")
	}
	if err := DeleteUserPendingRequest.Exec(); err != nil {
		log.Error().Str("where", "delete pending friend request").Str("type", "failed to execute query").Msg(err.Error())
		return errors.New("internal server error")
	}
	return nil
}

func selectUserPendingRequest(userId string) ([]PendingListOfUserUpdate, error) {
	if q := SelectUserPendingRequest.BindMap(qb.M{"userid": userId}); q.Err() != nil {
		log.Error().Str("where", "get pending requests").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return nil, errors.New("internal server error")
	}
	rows := make([]PendingListOfUserUpdate, 1)
	if err := SelectUserPendingRequest.Select(&rows); err != nil {
		log.Error().Str("where", "get pending requests").Str("type", "failed to execute query").Msg(err.Error())
		return nil, errors.New("internal server error")
	}
	return rows, nil
}

func addUserFriend(user *FriendsListOfUserUpdate) error {
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

func removeUserFriend(user *FriendsListOfUserUpdate) error {
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

func selectUserFriend(userid string) ([]FriendsListOfUserUpdate, error) {
	if q := SelectUserFriend.BindMap(qb.M{"userid": userid}); q.Err() != nil {
		log.Error().Str("where", "get friends list").Str("type", "failed to bind struct").Msg(q.Err().Error())
		return nil, errors.New("internal server error")
	}
	rows := make([]FriendsListOfUserUpdate, 1)
	if err := SelectUserFriend.Select(&rows); err != nil {
		log.Error().Str("where", "get friends list").Str("type", "failed to execute query").Msg(err.Error())
		return nil, errors.New("internal server error")
	}
	return rows, nil
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

func getUsers(userList []string) ([]User, error) {
	final := "("
	final += "'" + strings.Join(userList, "', '") + "'"
	final += ")"
	in := dbSession.Query(qb.Select("yaroom.users").Columns("userid", "name", "image").Where(qb.InLit("userid", final)).AllowFiltering().ToCql())
	rows := make([]User, 1)
	if err := in.SelectRelease(&rows); err != nil {
		log.Error().Str("where", "getting user data").Str("type", "failed to execute query").Msg(err.Error())
		return nil, err
	}
	return rows, nil
}

func getFriends(userid string) ([]string, error) {
	friends, err := selectUserFriend(userid)
	pending, err := selectUserPendingRequest(userid)
	usersList := []string{}
	for _, user := range friends[0].Friendslist {
		usersList = append(usersList, user)
	}
	for _, user := range pending[0].Pendinglist {
		usersList = append(usersList, user)
	}
	return usersList, err
}
