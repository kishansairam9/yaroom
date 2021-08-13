package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/appleboy/go-fcm"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/gocql/gocql"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"github.com/nats-io/nats.go"
	"github.com/rs/zerolog/log"
	"github.com/scylladb/gocqlx/v2"
)

var dbSession gocqlx.Session
var minioClient *minio.Client
var fcmClient *fcm.Client
var jsContext nats.JetStreamContext

const miniobucket = "yaroom-test"

func main() {
	var err error
	// Jet stream
	{
		nc, err := nats.Connect("localhost:4222")
		if err != nil {
			log.Fatal().Str("where", "nats connect").Str("type", "failed to connect to nats").Msg(err.Error())
		}
		defer nc.Close()
		jsContext, err = nc.JetStream()
		if err != nil {
			log.Fatal().Str("where", "nats jetstream").Str("type", "failed to create jet stream context").Msg(err.Error())
		}
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

	// FCM Client
	fcmClient, err = fcm.NewClient("AAAALzycFws:APA91bGVejj4KK3TmZDUmzR7GO89nJc_l_-OlJ-PzupG6KlQ0p5dlMJZHajbWGgPQmQEtk80wQQkYueTaAO9B8eDfUwUGi76zOMnCwJDCvggs9zO8FZuB-MUxVwrOHPthHr72h8l0YR_")
	if err != nil {
		log.Fatal().Str("where", "fcm create client").Str("type", "failed to create fcm client").Msg(err.Error())
		return
	}

	// Server
	r := gin.Default()
	r.Use(cors.Default())
	wsUpgrader.CheckOrigin = func(r *http.Request) bool { return true }

	// Protected routes
	secured := r.Group("/v1", jwtHandler)
	{
		secured.GET("/ping", func(g *gin.Context) {
			rawUserId, _ := g.Get("userId")
			userId := rawUserId.(string)
			g.JSON(200, gin.H{"text": "Hello from private " + userId})
		})

		// Web socket
		secured.GET("/ws", wsHandler)

		// Media handler
		secured.GET("/media/:objectid", mediaServerHandler)

		// Get messages
		secured.GET("/getLaterMessages", getLaterMessageHandler)
		secured.GET("/getOlderMessages", getOlderMessageHandler)
		secured.POST("/search", searchQueryHandler)

		// FCM Token
		secured.POST("/fcmTokenUpdate", fcmTokenUpdateHandler)
		secured.POST("/fcmTokenInvalidate", fcmTokenInvalidateHandler)
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

		// Get messages
		testing.GET("/getLaterMessages", getLaterMessageHandler)
		testing.GET("/getOlderMessages", getOlderMessageHandler)
		testing.POST("/search", searchQueryHandler)

		// Send active status
		testing.POST("/status", func(g *gin.Context) {
			var status testingActiveStatus
			if err := g.BindJSON(&status); err != nil {
				log.Info().Str("where", "bind json").Str("type", "failed to parse body to json").Msg(err.Error())
				return
			}

			rawUserId, _ := g.Get("userId")
			userId := rawUserId.(string)
			if userId != status.UserId {
				g.AbortWithStatusJSON(400, gin.H{"error": "Request sender and msg fromUser don't match"})
				return
			}

			stream := []string{fmt.Sprintf("USER:%v", userId)}
			if err = ensureActiveStatusStreamsExist(stream); err != nil {
				log.Error().Str("where", "ensure stream").Str("type", "failed to ensure stream exists").Msg(err.Error())
				g.AbortWithStatusJSON(500, gin.H{"error": "internal server error"})
				return
			}
			fmt.Printf("Published %v to %v\n", fmt.Sprintf("%v:%v", userId, status.Active), stream[0])
			_, err = jsContext.Publish(stream[0], []byte(fmt.Sprintf("%v:%v", userId, status.Active)))
			if err != nil {
				log.Error().Str("where", "active send to user").Str("type", "failed to send activity status").Msg(err.Error())
				g.AbortWithStatusJSON(500, gin.H{"error": "internal server error"})
				return
			}
		})

		// Message handler
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
			// if err = sendMessageNotification(msg.ToUser, msg); err != nil {
			// log.Error().Str("where", "fcm send to user").Str("type", "failed to send push notification").Msg(err.Error())
			// g.AbortWithStatusJSON(500, gin.H{"error": "internal server error"})
			// return
			// }
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
