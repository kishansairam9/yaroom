# Messages
curl -XPUT -H 'Content-Type: application/json' 'http://localhost:9200/messages?pretty' -d '{
    "settings": { "keyspace":"messages" },
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

curl -X GET localhost:9200/messages/_mapping?pretty