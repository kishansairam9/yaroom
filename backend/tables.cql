-- cql is case insensitive by default, need to add quotations around each to force case
-- don't unless necessary, just use all lower case 
-- DROP KEYSPACE messages;
CREATE KEYSPACE messages WITH replication = 
    {'class': 'NetworkTopologyStrategy', 'DC1': 1};

-- exchange_id should be present for all messages, and it is partition key and for all tables
-- use (exchange_id, msgid) as PRIMARY KEY, exchange_id can be same but msgid won't be hence unique

-- here exchange_id is parition key and msgid is clustering key (or sort key)
-- CLUSTERING ORDER BY (msgid DESC) is used to cluster in desc, this acts as time cluster
-- as first part of msgid (using xid) depends on time and ordering by orders by time of msg
-- this is done so that msgs are sorted by time and this makes consecutive in time reads optimal

-- `exchange_id design` -> needs to be deterministic, shouldn't depend on who is sending message
-- STICK TO THIS, MEDIA ACCESS CONTROLS ALSO DEPENDS ON THIS
-- DMs -> sort user ids and u1 < u2 => exchange_id = `u1:u2`
-- Groups -> exchange_id = `groupdId` 
-- Rooms -> exchange_id = `roomId` 

CREATE TABLE messages.chat_messages (
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

CREATE TABLE messages.rooms_messages (
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

CREATE INDEX chat_messages_from_index ON messages.chat_messages (fromuser);
CREATE INDEX chat_messages_to_index ON messages.chat_messages (touser);

