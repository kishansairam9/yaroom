package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/form3tech-oss/jwt-go"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"go.mongodb.org/mongo-driver/mongo/readpref"
)

func checkJWT() gin.HandlerFunc {
	return func(g *gin.Context) {
		if err := jwtMiddleware.CheckJWT(g.Writer, g.Request); err != nil {
			g.AbortWithStatus(401)
		}
	}
}

var db *mongo.Database

func main() {
	// Database
	// Replace the uri string with your MongoDB deployment's connection string.
	uri := "mongodb://root:password@127.0.0.1:27017/"
	dbctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	client, err := mongo.Connect(dbctx, options.Client().ApplyURI(uri))
	if err != nil {
		log.Fatal().Str("where", "mongo connect").Str("error", "failed to connect to db").Msg(err.Error())
	}
	defer func() {
		if err = client.Disconnect(dbctx); err != nil {
			log.Fatal().Str("where", "mongo disconnect").Str("error", "failed to disconnect db").Msg(err.Error())
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

	// Server
	r := gin.Default()
	r.Use(cors.Default())
	wsUpgrader.CheckOrigin = func(r *http.Request) bool { return true }

	r.GET("/ping", func(g *gin.Context) {
		g.JSON(200, gin.H{"text": "Hello from public"})
	})

	r.GET("/secured/ping", checkJWT(), func(g *gin.Context) {
		tokContext := g.Request.Context().Value("user")
		claims := tokContext.(*jwt.Token).Claims.(jwt.MapClaims)
		userId, ok := claims["userId"].(string)
		if !ok {
			log.Info().Str("where", "post JWT verify, userID extraction").Str("error", "token missing fields").Msg("Field userID not found in recieved JWT")
			g.AbortWithStatusJSON(400, gin.H{"error": "Invalid token format, missing fields"})
			return
		}
		g.JSON(200, gin.H{"text": "Hello from private " + userId})
	})

	type testingUser struct {
		UserId string
	}
	r.POST("/:userId", func(g *gin.Context) {
		var user testingUser
		if err := g.ShouldBindUri(&user); err != nil {
			g.AbortWithStatusJSON(400, gin.H{"msg": err.Error()})
		}
		g.JSON(200, gin.H{"userId": user.UserId})
	})

	r.GET("/", func(c *gin.Context) {
		wsHandler(c.Writer, c.Request)
	})

	srv := &http.Server{
		Addr:    ":" + string(os.Getenv("PORT")),
		Handler: r,
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal().Str("where", "listen and serve").Str("error", "failed to start server").Msg("Listen: " + err.Error())
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
