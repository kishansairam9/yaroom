curl -XPUT -H 'Content-Type: application/json' 'http://localhost:9200/chat_messages?pretty' -d '{
    "settings": {"keyspace":"yaroom"},
    "mappings": {
        "chat_messages" : {
            "discover":"(msgtime|fromuser|touser|exchange_id)",
            "properties": {
                "content": {
                    "type": "text",
                    "cql_collection" : "singleton"
                }
            }
        }
    }
}'

curl -XPUT -H 'Content-Type: application/json' 'http://localhost:9200/group_messages?pretty' -d '{
    "settings": {"keyspace":"yaroom"},
    "mappings": {
        "group_messages" : {
            "discover":"(msgtime|groupid|exchange_id)",
            "properties": {
                "content": {
                    "type": "text",
                    "cql_collection" : "singleton"
                }
            }
        }
    }
}'

curl -XPUT -H 'Content-Type: application/json' 'http://localhost:9200/room_messages?pretty' -d '{
    "settings": {"keyspace":"yaroom"},
    "mappings": {
        "room_messages" : {
            "discover":"(msgtime|roomid|channelid|exchange_id)",
            "properties": {
                "content": {
                    "type": "text",
                    "cql_collection" : "singleton"
                }
            }
        }
    }
}'

# curl -X GET localhost:9200/chat_messages/_mapping?pretty
# curl -X GET localhost:9200/group_messages/_mapping?pretty
# curl -X GET localhost:9200/room_messages/_mapping?pretty

# docker exec -i yaroom-elassandra nodetool rebuild_index yaroom chat_messages elastic_chat_messages_idx
# docker exec -i yaroom-elassandra nodetool rebuild_index yaroom group_messages elastic_group_messages_idx
# docker exec -i yaroom-elassandra nodetool rebuild_index yaroom room_messages elastic_room_messages_idx