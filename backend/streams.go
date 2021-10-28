package main

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/nats-io/nats.go"
	"github.com/rs/zerolog/log"
)

type ActiveStatus struct {
	Active bool   `json:"active"`
	Userid string `json:"userId"`
}

func ensureStreamsExist(streams []string) error {
	// If multiple errors return first error, need to abort fatal error on server side
	for _, st := range streams {
		// Retention and Storage configured keeping in mind that these active statuses are not permanent & critical
		_, err := jsContext.AddStream(&nats.StreamConfig{Name: st, Retention: nats.InterestPolicy, Storage: nats.MemoryStorage, MaxAge: 10 * time.Second})
		if err != nil {
			return err
		}
	}
	return nil
}

func monitorStreams(userId string, streams []string, inputChan <-chan interface{}, quit <-chan bool) {
	// Not a fatal errors here, so don't need to close conn to user for this
	currentActivity := true
	lastGotTrue := time.Now()
	lastActiveSent := time.Now().AddDate(0, 0, -1)
	lastSent := false
	var sendState = func(cur, last bool) bool {
		if last && (time.Since(lastGotTrue).Seconds() > 10) {
			fmt.Println("DEBUG PRINT setting inactive after timeout")
			cur = false
		}
		data := ActiveStatus{Userid: userId, Active: cur}
		enc, _ := json.Marshal(data)
		err := userSendOnStream(userId, streams, enc)
		if err != nil {
			log.Warn().Str("where", "send data on stream").Str("type", "failed to send data").Msg(err.Error())
		}
		lastActiveSent = time.Now()
		return cur
	}
	for {
		select {
		case data := <-inputChan:
			_, ok := data.(ActiveStatus)
			// if ok, then active status
			if !ok {
				enc, _ := json.Marshal(data)
				err := userSendOnStream(userId, streams, enc)
				if err != nil {
					log.Warn().Str("where", "send data on stream").Str("type", "failed to send data").Msg(err.Error())
				}
			} else {
				currentActivity = true
				lastGotTrue = time.Now()
			}
			if time.Since(lastActiveSent).Seconds() > 3 {
				currentActivity = sendState(currentActivity, lastSent)
				lastSent = currentActivity
			}
		case <-time.After(3 * time.Second):
			currentActivity = sendState(currentActivity, lastSent)
			lastSent = currentActivity
		case <-quit:
			data := ActiveStatus{Userid: userId, Active: false}
			enc, _ := json.Marshal(data)
			err := userSendOnStream(userId, streams, enc)
			if err != nil {
				log.Warn().Str("where", "send data on stream").Str("type", "failed to send data").Msg(err.Error())
			}
			return
		}
	}
}

func userSendOnStream(userId string, streams []string, data []byte) error {
	// If multiple errors only return the first one, not fatal error, it's okay to have failures but log them on console as WARN for debugging
	var err error = nil
	// send to current user's stream
	err = ensureStreamsExist([]string{"USER:" + userId})
	if err != nil {
		return err
	}
	_, err = jsContext.Publish("USER:"+userId, data)
	if err != nil {
		log.Warn().Str("where", "send data on stream").Str("type", "failed to add messsage to stream "+"USER:"+userId).Msg(err.Error())
	}
	for _, st := range streams {
		// Send only to groups and rooms other than current user
		split := strings.Split(st, ":")
		if split[0] == "USER" {
			continue
		}
		_, err = jsContext.Publish(st, data)
		if err != nil {
			log.Warn().Str("where", "send data on stream").Str("type", "failed to add messsage to stream "+st).Msg(err.Error())
		}
	}
	return err
}

func userSubscribeTo(userId string, streams []string, outputChan chan<- []byte, quit <-chan bool) {
	// Log errors on console for debugging
	dataCh := make(chan *nats.Msg)
	for _, st := range streams {
		// Deliver policy is to send only new messages to consumers as no point in receiving older ones, Ack explicit as we don't want to ignore any msgs
		fmt.Println("Subscribed to " + st)
		_, err := jsContext.ChanSubscribe(st, dataCh, nats.DeliverNew(), nats.AckExplicit())
		if err != nil {
			log.Warn().Str("where", "send active status").Str("type", "failed to add messsage to stream "+st).Msg(err.Error())
		}
	}
	lastSentActive := make(map[string][]byte)
	activeStatusBuffer := make(map[string][]byte)
	ctr := 0
	bufEdgeHandle := 40
	for {
		ctr = (ctr + 1) % (bufEdgeHandle + 1)
		select {
		case <-time.After(2 * time.Second):
			for k, v := range activeStatusBuffer {
				if v != nil && string(lastSentActive[k]) != string(v) {
					outputChan <- v
					lastSentActive[k] = v
				}
			}
			activeStatusBuffer = make(map[string][]byte)
		case msg := <-dataCh:
			// fmt.Println("got msg ", string(msg.Data))
			subTest := strings.Split(string(msg.Data), "-")
			if subTest[0] == "SUB" {
				st := subTest[1]
				found := false
				for _, v := range streams {
					if v == st {
						found = true
					}
				}
				if !found {
					fmt.Println(userId + " Subscribed to " + st)
					_, err := jsContext.ChanSubscribe(st, dataCh, nats.DeliverNew(), nats.AckExplicit())
					if err != nil {
						log.Warn().Str("where", "send active status").Str("type", "failed to add messsage to stream "+st).Msg(err.Error())
					}
					streams = append(streams, st)
				}
				msg.AckSync()
				fmt.Println(userId + "Sub done continue")
				continue
			}
			var store ActiveStatus
			err := json.Unmarshal(msg.Data, &store)
			// if error is nil then active status
			if err == nil {
				if store.Userid != userId {
					activeStatusBuffer[store.Userid] = msg.Data
				}
				msg.AckSync()
			} else {
				outputChan <- msg.Data
				msg.AckSync()
			}
			// Handle edge case of not going into after timeout for buffer flush
			if ctr == bufEdgeHandle {
				for k, v := range activeStatusBuffer {
					if v != nil && string(lastSentActive[k]) != string(v) {
						outputChan <- v
						lastSentActive[k] = v
					}
				}
				activeStatusBuffer = make(map[string][]byte)
			}
		case <-quit:
			return
		}
	}
}

func sendUpdateOnStream(streams []string, data []byte) error {
	// Rejects sending on user streams, user streams only serve purpose for active status of friends
	// If multiple errors only return the first one, not fatal error, it's okay to have failures but log them on console as WARN for debugging
	var err error = nil
	for _, st := range streams {
		// Send only to groups and rooms
		split := strings.Split(st, ":")
		if split[0] == "USER" {
			continue
		}
		_, err = jsContext.Publish(st, data)
		if err != nil {
			log.Warn().Str("where", "send data on stream").Str("type", "failed to add messsage to stream "+st).Msg(err.Error())
		}
	}
	return err
}
