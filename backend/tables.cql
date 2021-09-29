-- cql is case insensitive by default, need to add quotations around each to force case
-- don't unless necessary, just use all lower case 

-- TODO: PERFORM DENORMALIZATION CURRENT DESING IS BAD FOR SCHEMA DUE TO METADATA ACCESSES LOT OF READS

CREATE KEYSPACE yaroom WITH replication = 
    {'class': 'NetworkTopologyStrategy', 'DC1': 1};

CREATE TABLE yaroom.users (
    userid text,
    name text,
    username text,
    image text,
    tokens set<text>,
    friendslist set<text>,
    groupslist set<text>,
    roomslist set<text>,
    pendinglist set<text>,
    PRIMARY KEY (userid),
);

CREATE TYPE yaroom.user_udt (
    userid text,
    name text,
    image text
);

CREATE TABLE yaroom.groups (
    groupid text,
    name text,
    description text,
    image text,
    userslist set<frozen <user_udt>>,
    PRIMARY KEY (groupid)
);

CREATE TABLE yaroom.rooms (
    roomid text,
    name text,
    description text,
    image text,
    userslist map<text,frozen <user_udt>>,
    channelslist map<text, text>,
    PRIMARY KEY (roomid)
);

INSERT INTO yaroom.groups (groupid, name, description, image, userslist) VALUES ('group-demo-1', 'Group Demo 1', 'Group for demo purposes', 'https://news.blr.com/app/uploads/sites/3/2018/07/Demo-5.jpg', {{userid:'john-doe', name:'John Doe', image:'https://rahulsias.files.wordpress.com/2017/01/john-doe_text.jpg'}, {userid:'alice-jane', name:'Alice Jane', image:''}});
INSERT INTO yaroom.groups (groupid, name, description, image, userslist) VALUES ('group-demo-2', 'Group Demo 2', 'Group for demo purposes', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTDStpvuQWus5fPuovIQHlgytQhjXbAgCEP4A&usqp=CAU', {{userid:'john-doe', name:'John Doe', image:'https://rahulsias.files.wordpress.com/2017/01/john-doe_text.jpg'}, {userid:'alice-jane', name:'Alice Jane', image:''}});

INSERT INTO yaroom.rooms (roomid, name, description, image, userslist, channelslist) VALUES ('room-demo-1', 'Room Demo 1', 'Room for demo purposes', 'https://news.blr.com/app/uploads/sites/3/2018/07/Demo-5.jpg', {'john-doe':{userid:'john-doe', name:'John Doe', image:'https://rahulsias.files.wordpress.com/2017/01/john-doe_text.jpg'}, 'alice-jane':{userid:'alice-jane', name:'Alice Jane', image:''}}, {'chan1': 'Channel 1', 'chan2': 'Channel 2', 'chan3': 'Channel 3'});
INSERT INTO yaroom.rooms (roomid, name, description, image, userslist, channelslist) VALUES ('room-demo-2', 'Room Demo 2', 'Room for demo purposes', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTDStpvuQWus5fPuovIQHlgytQhjXbAgCEP4A&usqp=CAU', {'john-doe':{userid:'john-doe', name:'John Doe', image:'https://rahulsias.files.wordpress.com/2017/01/john-doe_text.jpg'}, 'alice-jane':{userid:'alice-jane', name:'Alice Jane', image:''}}, {'chan1': 'Channel 1', 'chan2': 'Channel 2', 'chan3': 'Channel 3'});

INSERT INTO yaroom.users (userid, name, username, image, groupslist, roomslist) VALUES ('john-doe', 'John Doe', 'johndoe_demo', 'https://rahulsias.files.wordpress.com/2017/01/john-doe_text.jpg', {'group-demo-1', 'group-demo-2'}, {'room-demo-1', 'room-demo-2'});
INSERT INTO yaroom.users (userid, name, username, image, groupslist, roomslist) VALUES ('alice-jane', 'Alice Jane', 'alicejane_demo', '', {'group-demo-1', 'group-demo-2'}, {'room-demo-1', 'room-demo-2'});

-- exchange_id should be present for all messages, and it is partition key and for all tables
-- use (exchange_id, msgid) as PRIMARY KEY, exchange_id can be same but msgid won't be hence unique

-- here exchange_id is parition key and msgid is clustering key (or sort key)
-- CLUSTERING ORDER BY (msgid DESC) is used to cluster in desc, this acts as time cluster
-- as first part of msgid (using xid) depends on time and ordering by orders by time of msg
-- this is done so that msgs are sorted by time and this makes consecutive in time reads optimal

-- `exchange_id design` -> needs to be deterministic, shouldn't depend on who is sending message
-- STICK TO THIS, MEDIA ACCESS CONTROLS ALSO DEPENDS ON THIS
-- DMs -> sort user ids and u1 < u2 => exchange_id = `u1:u2`
-- Group -> exchange_id = `groupdId` 
-- Room -> exchange_id = `roomId@channelId` 

CREATE TABLE yaroom.chat_messages (
    exchange_id text,
    msgid text,
    fromuser text,
    touser text,
    msgtime timestamp,
    content text,
    mediaid text,
    replyto text,
    es_query text,
    es_options text,
    PRIMARY KEY (exchange_id, msgid)
) WITH CLUSTERING ORDER BY (msgid DESC);

CREATE TABLE yaroom.group_messages (
    exchange_id text,
    msgid text,
    fromuser text,
    groupid text,
    msgtime timestamp,
    content text,
    mediaid text,
    replyto text,
    es_query text,
    es_options text,
    PRIMARY KEY (exchange_id, msgid)
) WITH CLUSTERING ORDER BY (msgid DESC);

CREATE TABLE yaroom.room_messages (
    exchange_id text,
    msgid text,
    fromuser text,
    roomid text,
    channelid text,
    msgtime timestamp,
    content text,
    mediaid text,
    replyto text,
    es_query text,
    es_options text,
    PRIMARY KEY (exchange_id, msgid)
) WITH CLUSTERING ORDER BY (msgid DESC);

CREATE INDEX chat_messages_from_index ON yaroom.chat_messages (fromuser);
CREATE INDEX chat_messages_to_index ON yaroom.chat_messages (touser);
-- group id and room id don't need indexes, the exchange id itself is same, which being primary key is already indexed
-- CREATE INDEX group_messages_index ON yaroom.group_messages (groupid);
-- CREATE INDEX room_messages_room_index ON yaroom.room_messages (roomid);
CREATE INDEX room_messages_channel_index ON yaroom.room_messages (channelid);

