package main

import (
	"encoding/json"

	"github.com/rs/zerolog/log"
	"github.com/streadway/amqp"
)

func msgQueueSendToUser(userId string, msg WSMessage) error {
	handleError := func(errType string, err error) {
		log.Error().Str("where", "msg queue routine").Str("type", errType).Msg(err.Error())
	}

	rmqCh, err := rmqConn.Channel()
	if err != nil {
		handleError("create rmq channel", err)
		return err
	}
	defer rmqCh.Close()

	err = rmqCh.ExchangeDeclare(userId, "fanout", true, false, false, false, nil)
	if err != nil {
		handleError("declare exchange", err)
		return err
	}

	data, _ := json.Marshal(msg)
	err = rmqCh.Publish(
		userId, "", false, false,
		amqp.Publishing{ContentType: "text/plain", Body: data},
	)
	if err != nil {
		handleError("rmqCh Publish", err)
		return err
	}
	return nil
}

func msgQueueReadRoutine(userId string, outputChan chan<- interface{}, quit chan bool) {
	handleError := func(errType string, err error) {
		log.Error().Str("where", "msg queue routine").Str("type", errType).Msg(err.Error())
		quit <- true
	}

	rmqCh, err := rmqConn.Channel()
	if err != nil {
		handleError("create rmq channel", err)
		return
	}
	defer rmqCh.Close()

	err = rmqCh.ExchangeDeclare(userId, "fanout", true, false, false, false, nil)
	if err != nil {
		handleError("declare exchange", err)
		return
	}

	q, err := rmqCh.QueueDeclare("", false, false, true, false, nil)
	if err != nil {
		handleError("queue declare", err)
		return
	}

	err = rmqCh.QueueBind(q.Name, "", userId, false, nil)
	if err != nil {
		handleError("queue bind", err)
		return
	}

	dataCh, err := rmqCh.Consume(q.Name, "", false, false, false, false, nil)
	if err != nil {
		handleError("consume queue", err)
		return
	}

	for {
		select {
		case d := <-dataCh:
			var msg WSMessage
			if err := json.Unmarshal(d.Body, &msg); err != nil {
				log.Error().Str("where", "queue read").Str("type", "failed to parse message").Msg(err.Error())
			}
			err = addMessage(&msg)
			if err != nil {
				log.Error().Str("where", "add message").Str("type", "failed to add messsage to db").Msg(err.Error())
			} else {
				outputChan <- msg
			}
			d.Ack(false)
		case <-quit:
			return
		}
	}
}
