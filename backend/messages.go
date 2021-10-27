package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/rs/xid"
	"github.com/rs/zerolog/log"
	"github.com/scylladb/gocqlx/qb"
	"github.com/scylladb/gocqlx/v2"
	"github.com/scylladb/gocqlx/v2/table"
)

var ChatMessageMetadata = table.Metadata{
	Name:    "yaroom.chat_messages",
	Columns: []string{"exchange_id", "msgid", "fromuser", "touser", "msgtime", "content", "mediaid", "replyto", "es_query", "es_options"},
	PartKey: []string{"exchange_id"},
	SortKey: []string{"msgid"},
}

var GroupMessageMetadata = table.Metadata{
	Name:    "yaroom.group_messages",
	Columns: []string{"exchange_id", "msgid", "fromuser", "groupid", "msgtime", "content", "mediaid", "replyto", "es_query", "es_options"},
	PartKey: []string{"exchange_id"},
	SortKey: []string{"msgid"},
}

var RoomMessageMetadata = table.Metadata{
	Name:    "yaroom.room_messages",
	Columns: []string{"exchange_id", "msgid", "fromuser", "roomid", "channelid", "msgtime", "content", "mediaid", "replyto", "es_query", "es_options"},
	PartKey: []string{"exchange_id"},
	SortKey: []string{"msgid"},
}

var ChatMessageTable *table.Table

var RoomMessageTable *table.Table

var GroupMessageTable *table.Table

var InsertChatMessage *gocqlx.Queryx

var InsertGroupMessage *gocqlx.Queryx

var InsertRoomMessage *gocqlx.Queryx

type DBMessage struct {
	Exchange_id string    `json:"exchange_id,omitempty"`
	Msgid       string    `json:"msgId,omitempty"`
	Fromuser    string    `json:"fromUser"`
	Touser      *string   `json:"toUser,omitempty"`
	Groupid     *string   `json:"groupId,omitempty"`
	Roomid      *string   `json:"roomId,omitempty"`
	Channelid   *string   `json:"channelId,omitempty"`
	Msgtime     time.Time `json:"time"`
	Type        string    `json:"type"`
	Content     *string   `json:"content,omitempty"`
	Mediaid     *string   `json:"media,omitempty"`
	Replyto     *string   `json:"replyTo,omitempty"`
	Es_query    *string   `json:"es_query,omitempty"`
	Es_options  *string   `json:"es_options,omitempty"`
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

type GroupMessage struct {
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

type RoomMessage struct {
	Exchange_id string    `json:"exchange_id,omitempty"`
	Msgid       string    `json:"msgId,omitempty"`
	Fromuser    string    `json:"fromUser"`
	Roomid      string    `json:"roomId"`
	Channelid   string    `json:"channelId"`
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
	case "GroupMessage":
		return msg.GroupId, nil
	case "RoomMessage":
		return msg.RoomId + "@" + msg.ChannelId, nil
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
	case "GroupMessage":
		var data GroupMessage
		if err := json.Unmarshal(jsonBytes, &data); err != nil {
			return err
		}
		data.Exchange_id = exchange_id
		data.Msgid = msgId
		data.Msgtime = time.Now()
		if q := InsertGroupMessage.BindStruct(data); q.Err() != nil {
			log.Error().Str("where", "insert chat message").Str("type", "failed to bind struct").Msg(q.Err().Error())
			return errors.New("internal server error")
		}
		if err := InsertGroupMessage.Exec(); err != nil {
			log.Error().Str("where", "insert groups message").Str("type", "failed to execute query").Msg(err.Error())
			return errors.New("internal server error")
		}
	case "RoomMessage":
		var data RoomMessage
		if err := json.Unmarshal(jsonBytes, &data); err != nil {
			return err
		}
		data.Exchange_id = exchange_id
		data.Msgid = msgId
		data.Msgtime = time.Now()
		if q := InsertRoomMessage.BindStruct(data); q.Err() != nil {
			log.Error().Str("where", "insert rooms message").Str("type", "failed to bind struct").Msg(q.Err().Error())
			return errors.New("internal server error")
		}
		if err := InsertRoomMessage.Exec(); err != nil {
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

func getOlderMessages(userId, lastMsgId, exchangeId, msgType string, limit uint) ([]DBMessage, error) {
	// Handle different message types
	var chat []DBMessage
	var table string
	switch msgType {
	case "ChatMessage":
		table = "yaroom.chat_messages"
	case "GroupMessage":
		table = "yaroom.group_messages"
	case "RoomMessage":
		table = "yaroom.room_messages"
	default:
		return nil, errors.New("unknown message type")
	}
	// Check if user has access to exchange id
	split_exchange_id := strings.Split(exchangeId, ":")
	switch len(split_exchange_id) {
	case 1:
		userMeta, err := getUserMetadata(userId)
		if err != nil {
			log.Error().Str("where", "media metadata check").Str("type", "error occured in retrieving data").Msg(err.Error())
			return nil, err
		}
		hasAccess := false
		for _, group := range userMeta.Groupslist {
			if split_exchange_id[0] == group {
				hasAccess = true
				break
			}
		}
		if hasAccess {
			break
		}
		room_id_split := strings.Split(split_exchange_id[0], "@")
		for _, room := range userMeta.Roomslist {
			if room_id_split[0] == room {
				hasAccess = true
				break
			}
		}
		if hasAccess {
			break
		}
		return nil, errors.New("user doesn't have access")
	case 2:
		if !(split_exchange_id[0] == userId || split_exchange_id[1] == userId) {
			return nil, errors.New("user doesn't have access")

		}
	default:
		return nil, errors.New("invalid exchange id")
	}
	lastMsgId = "'" + lastMsgId + "'"
	exchangeId = "'" + exchangeId + "'"
	q := dbSession.Query(qb.Select(table).Where(qb.EqLit("exchange_id", exchangeId)).Where(qb.LtLit("msgid", lastMsgId)).Limit(limit).AllowFiltering().ToCql())
	if err := q.SelectRelease(&chat); err != nil {
		return nil, err
	}
	return chat, nil
}

func getLaterMessages(userId, lastMsgId string) ([]DBMessage, error) {
	nonPadedUserId := userId
	userId = "'" + userId + "'"
	lastMsgId = "'" + lastMsgId + "'"
	userMeta, err := getUserMetadata(nonPadedUserId)
	if err != nil {
		log.Error().Str("where", "get later messages").Str("type", "error occured in retrieving user metadata").Msg(err.Error())
		return nil, err
	}

	if userMeta == nil {
		return nil, errors.New("user data doesn't exist")
	}

	groups := make([]string, 0)
	rooms := make([]string, 0)
	for _, group := range userMeta.Groupslist {
		groups = append(groups, "'"+group+"'")
	}
	for _, room := range userMeta.Roomslist {
		rooms = append(rooms, "'"+room+"'")
	}

	var chatfrom []DBMessage
	q := dbSession.Query(qb.Select("yaroom.chat_messages").Columns("*").Where(qb.GtLit("msgid", lastMsgId)).Where(qb.EqLit("fromuser", userId)).AllowFiltering().ToCql())
	if err := q.SelectRelease(&chatfrom); err != nil {
		return nil, err
	}
	for i := range chatfrom {
		chatfrom[i].Type = "ChatMessage"
	}
	var chatto []DBMessage
	q = dbSession.Query(qb.Select("yaroom.chat_messages").Columns("*").Where(qb.GtLit("msgid", lastMsgId)).Where(qb.EqLit("touser", userId)).AllowFiltering().ToCql())
	if err := q.SelectRelease(&chatto); err != nil {
		return nil, err
	}
	for i := range chatto {
		chatto[i].Type = "ChatMessage"
	}

	var groupchat []DBMessage
	if len(groups) > 0 {
		q = dbSession.Query(qb.Select("yaroom.group_messages").Columns("*").Where(qb.GtLit("msgid", lastMsgId)).Where(qb.InLit("exchange_id", "("+strings.Join(groups, ",")+")")).AllowFiltering().ToCql())
		if err := q.SelectRelease(&groupchat); err != nil {
			return nil, err
		}
	}
	for i := range groupchat {
		groupchat[i].Type = "GroupMessage"
	}

	var roomchat []DBMessage
	if len(rooms) > 0 {
		roomChannels := make([]string, 0)
		for _, room := range userMeta.Roomslist {
			rdata, err := selectChannelsOfRoom(room)
			if err != nil {
				fmt.Printf("err %v\n", err.Error())
			}
			for channel, _ := range rdata[0].Channelslist {
				roomChannels = append(roomChannels, "'"+room+"@"+channel+"'")
			}
		}
		q = dbSession.Query(qb.Select("yaroom.room_messages").Columns("*").Where(qb.GtLit("msgid", lastMsgId)).Where(qb.InLit("exchange_id", "("+strings.Join(roomChannels, ",")+")")).AllowFiltering().ToCql())
		if err := q.SelectRelease(&roomchat); err != nil {
			return nil, err
		}
	}
	for i := range roomchat {
		roomchat[i].Type = "RoomMessage"
	}

	all := make([]DBMessage, 0)
	all = append(all, chatfrom...)
	all = append(all, chatto...)
	all = append(all, groupchat...)
	all = append(all, roomchat...)
	if len(all) == 0 {
		return nil, nil // For consistency in API with other func calls
	}
	return all, nil
}

func searchQuery(userId, searchString, exchangeId, msgType string, limit uint) ([]DBMessage, error) {
	// Handle different message types
	var chat []DBMessage
	var table string
	es_options := "indices="
	switch msgType {
	case "ChatMessage":
		table = "yaroom.chat_messages"
		es_options += "chat_messages"
	case "GroupMessage":
		table = "yaroom.group_messages"
		es_options += "group_messages"
	case "RoomMessage":
		table = "yaroom.room_messages"
		es_options += "room_messages"
	default:
		return nil, errors.New("unknown message type")
	}
	// Check if user has access to exchange id
	split_exchange_id := strings.Split(exchangeId, ":")
	switch len(split_exchange_id) {
	case 1:
		userMeta, err := getUserMetadata(userId)
		if err != nil {
			log.Error().Str("where", "media metadata check").Str("type", "error occured in retrieving data").Msg(err.Error())
			return nil, err
		}
		hasAccess := false
		for _, group := range userMeta.Groupslist {
			if split_exchange_id[0] == group {
				hasAccess = true
				break
			}
		}
		if hasAccess {
			break
		}
		room_id_split := strings.Split(split_exchange_id[0], "@")
		for _, room := range userMeta.Roomslist {
			if room_id_split[0] == room {
				hasAccess = true
				break
			}
		}
		if hasAccess {
			break
		}
		return nil, errors.New("user doesn't have access")
	case 2:
		if !(split_exchange_id[0] == userId || split_exchange_id[1] == userId) {
			return nil, errors.New("user doesn't have access")

		}
	default:
		return nil, errors.New("invalid exchange id")
	}
	es_options = "'" + es_options + "'"
	exchangeId = "'" + exchangeId + "'"
	es_query := fmt.Sprintf("'{\"query\":{\"query_string\":{\"query\":\"*%v*\"}}}'", searchString)
	q := dbSession.Query(qb.Select(table).Where(qb.EqLit("exchange_id", exchangeId)).Where(qb.EqLit("es_query", es_query)).Where(qb.EqLit("es_options", es_options)).Limit(limit).AllowFiltering().ToCql())
	if err := q.SelectRelease(&chat); err != nil {
		return nil, err
	}
	return chat, nil
}
