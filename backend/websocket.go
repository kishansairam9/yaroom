package main

import (
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

var wsUpgrader = websocket.Upgrader{ReadBufferSize: 1024, WriteBufferSize: 1024}

func wsHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := wsUpgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("Failed to upgrade conn to ws %v", err)
	}
	for {
		msgType, msg, err := conn.ReadMessage()
		if err != nil {
			log.Printf("Error while reading message from client: %v", err)
			break
		}
		conn.WriteMessage(msgType, msg)
	}
}
