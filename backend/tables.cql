-- cql is case insensitive by default, need to add quotations around each to force case

CREATE KEYSPACE messages WITH replication = 
    {'class': 'NetworkTopologyStrategy', 'DC1': 1};

CREATE TABLE messages.chat_messages (
    exchange_id text,
    msgid text,
    fromuser text,
    touser text,
    msgtime timestamp,
    content text,
    media text,
    replyto text,
    es_query text,
    es_options text,
    PRIMARY KEY (exchange_id, msgtime, msgid)
) WITH CLUSTERING ORDER BY (msgtime DESC);

CREATE INDEX chat_messages_from_index ON messages.chat_messages (fromuser);
CREATE INDEX chat_messages_to_index ON messages.chat_messages (touser);

