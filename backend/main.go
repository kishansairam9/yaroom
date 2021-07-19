package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"go.mongodb.org/mongo-driver/mongo/readpref"
)

var db *mongo.Database

func main() {
	// Database
	{
		uri := "mongodb://root:password@127.0.0.1:27017/"
		dbctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()

		client, err := mongo.Connect(dbctx, options.Client().ApplyURI(uri))
		if err != nil {
			log.Fatal().Str("where", "mongo connect").Str("type", "failed to connect to db").Msg(err.Error())
		}
		defer func() {
			if err = client.Disconnect(dbctx); err != nil {
				log.Fatal().Str("where", "mongo disconnect").Str("type", "failed to disconnect db").Msg(err.Error())
			}
		}()
		// Ping the primary
		if err := client.Ping(dbctx, readpref.Primary()); err != nil {
			panic(err)
		}
		log.Info().Msg("Database succesfully connected and pinged")

		db = client.Database("testing")

		chatMsgCol = db.Collection("ChatMessages")

		createIndexes(dbctx)
	}

	// Server
	r := gin.Default()
	r.Use(cors.Default())
	wsUpgrader.CheckOrigin = func(r *http.Request) bool { return true }

	// Dummy route
	r.GET("/ping", func(g *gin.Context) {
		g.JSON(200, gin.H{"text": "Hello from public"})
	})

	// Websocket mock
	r.GET("/", func(c *gin.Context) {
		wsHandler(c)
	})

	// Protected routes // TODO: Protect all at later stage, currently only testing
	secured := r.Group("/secured", jwtHandler)
	{
		secured.GET("/ping", func(g *gin.Context) {
			rawUserId, _ := g.Get("userId")
			userId := rawUserId.(string)
			g.JSON(200, gin.H{"text": "Hello from private " + userId})
		})
	}

	// Testing routes. Take user id from url (instead of jwt)
	getUserIdFromTestRoute := func(g *gin.Context) {
		var user testingUser
		if err := g.BindUri(&user); err != nil {
			return
		}
		g.Set("userId", user.UserId)
	}
	testing := r.Group("/testing/:userId", getUserIdFromTestRoute)
	{
		testing.POST("/", func(g *gin.Context) {
			rawUserId, _ := g.Get("userId")
			userId := rawUserId.(string)
			g.JSON(200, gin.H{"userId": userId})
		})

		testing.POST("/addMessage", func(g *gin.Context) {
			var msg WSMessage
			if err := g.BindJSON(&msg); err != nil {
				log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
				return
			}
			rawUserId, _ := g.Get("userId")
			userId := rawUserId.(string)
			if userId != msg.FromUser {
				g.AbortWithStatusJSON(400, gin.H{"error": "Request sender and msg fromUser don't match"})
				return
			}
			msg, err := addMessage(msg)
			if err != nil {
				if err.Error() == "unknown message type" {
					g.AbortWithStatusJSON(400, gin.H{"error": "Unknown message type"})
					return
				}
				log.Error().Str("where", "add message").Str("type", "failed to add message to db").Msg(err.Error())
				g.AbortWithStatus(500)
				return
			}
			g.JSON(200, msg)
		})
	}

	// Server Graceful exit
	{
		srv := &http.Server{
			Addr:    ":" + string(os.Getenv("PORT")),
			Handler: r,
		}

		go func() {
			if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
				log.Fatal().Str("where", "listen and serve").Str("type", "failed to start server").Msg("Listen: " + err.Error())
			}
		}()

		// Wait for interrupt signal to gracefully shutdown the server with
		// a timeout of 5 seconds.
		quit := make(chan os.Signal, 1)
		// kill (no param) default send syscall.SIGTERM
		// kill -2 is syscall.SIGINT
		// kill -9 is syscall.SIGKILL but can't be catch, so don't need add it
		signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
		<-quit
		log.Info().Msg("Shutting down server...")

		// The context is used to inform the server it has 5 seconds to finish
		// the request it is currently handling
		shutdownctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := srv.Shutdown(shutdownctx); err != nil {
			log.Warn().Msg("Server forced to shutdown: " + err.Error())
		}

		log.Info().Msg("Server exiting")
	}
}
