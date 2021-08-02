package main

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/nats-io/nats.go"
	"github.com/rs/zerolog/log"
)

type ActiveStatus struct {
	Active bool   `json:"active"`
	Userid string `json:"userId"`
}

func ensureActiveStatusStreamsExist(streams []string) error {
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

func monitorActivity(userId string, activeStatusStreams []string, inputChan <-chan bool, quit <-chan bool) {
	// Not a fatal errors here, so don't need to close conn to user for this
	for {
		select {
		case <-inputChan:
			// TODO Remove debug print
			fmt.Println("recived active from " + userId)
			err := sendActiveStatus(userId, activeStatusStreams, true)
			if err != nil {
				log.Warn().Str("where", "send active status").Str("type", "failed to send status").Msg(err.Error())
			}
		case <-time.After(3 * time.Second):
			err := sendActiveStatus(userId, activeStatusStreams, false)
			if err != nil {
				log.Warn().Str("where", "send active status").Str("type", "failed to send status").Msg(err.Error())
			}
		case <-quit:
			err := sendActiveStatus(userId, activeStatusStreams, false)
			if err != nil {
				log.Warn().Str("where", "send active status").Str("type", "failed to send status").Msg(err.Error())
			}
			return
		}
	}
}

func sendActiveStatus(userId string, streams []string, active bool) error {
	// If multiple errors only return the first one, not fatal error, it's okay to have failures but log them on console as WARN for debugging
	var err error = nil
	for _, st := range streams {
		// Send only to groups and rooms
		split := strings.Split(st, ":")
		if split[0] == "USER" {
			continue
		}
		fmt.Printf("Published %v to %v\n", fmt.Sprintf("%v:%v", userId, active), st)
		_, err = jsContext.Publish(st, []byte(fmt.Sprintf("%v:%v", userId, active)))
		if err != nil {
			log.Warn().Str("where", "send active status").Str("type", "failed to add messsage to stream "+st).Msg(err.Error())
		}
	}
	return err
}

func subscribeToActiveStatus(streams []string, outputChan chan<- interface{}, quit <-chan bool) {
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
	for {
		select {
		case msg := <-dataCh:
			fmt.Println("got msg ", string(msg.Data))
			status := strings.Split(string(msg.Data), ":")
			a, _ := strconv.ParseBool(status[1])
			outputChan <- ActiveStatus{Userid: status[0], Active: a}
			msg.AckSync()
		case <-quit:
			return
		}
	}
}
