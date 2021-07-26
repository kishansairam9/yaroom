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
	"github.com/gocql/gocql"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"github.com/rs/zerolog/log"
	"github.com/scylladb/gocqlx/v2"
	"github.com/streadway/amqp"
)

var rmqConn *amqp.Connection
var dbSession gocqlx.Session
var minioClient *minio.Client

const miniobucket = "yaroom-test"

func main() {
	var err error
	// Rabbit mq
	{
		rmqConn, err = amqp.Dial("amqp://guest:guest@localhost:5672/")
		if err != nil {
			log.Fatal().Str("where", "amqp dial").Str("type", "failed to connect to rabbit mq").Msg(err.Error())
		}
		defer rmqConn.Close()
	}

	// Database
	{
		cluster := gocql.NewCluster("localhost")
		dbSession, err = gocqlx.WrapSession(cluster.CreateSession())
		if err != nil {
			log.Fatal().Str("where", "gocqlx wrap session").Str("type", "failed to connect to cassandra").Msg(err.Error())
		}
		setupDB()
	}

	// Media store
	{
		endpoint := "localhost:9000"
		accessKeyID := "minio"
		secretAccessKey := "minio123"
		useSSL := false
		minioClient, err = minio.New(endpoint, &minio.Options{
			Creds:  credentials.NewStaticV4(accessKeyID, secretAccessKey, ""),
			Secure: useSSL,
		})
		if err != nil {
			log.Fatal().Str("where", "minio new").Str("type", "failed to connect to minio").Msg(err.Error())
		}
		found, err := minioClient.BucketExists(context.Background(), miniobucket)
		if err != nil {
			log.Fatal().Str("where", "minio check bucket").Str("type", "failed to check minio bucket exists").Msg(err.Error())
			return
		}
		if !found {
			// Create bucket
			err = minioClient.MakeBucket(context.Background(), miniobucket, minio.MakeBucketOptions{Region: "us-east-1", ObjectLocking: false})
			if err != nil {
				log.Fatal().Str("where", "minio create bucket").Str("type", "failed to create minio bucket").Msg(err.Error())
				return
			}
		}
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
	r.GET("/", wsHandler)

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

		// Media handler
		testing.GET("/media/:objectid", mediaServerHandler)

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

			err := addMessage(&msg)
			if err != nil {
				if err.Error() == "unknown message type" {
					g.AbortWithStatusJSON(400, gin.H{"error": "Unknown message type"})
					return
				}
				log.Error().Str("where", "add message").Str("type", "failed to add message to db").Msg(err.Error())
				g.AbortWithStatus(500)
				return
			}
			if err = msgQueueSendToUser(msg.ToUser, msg); err != nil {
				log.Error().Str("where", "msgQueue send to user").Str("type", "failed to write to user queue").Msg(err.Error())
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
