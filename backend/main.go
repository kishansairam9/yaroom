package main

import (
	"net/http"

	"github.com/form3tech-oss/jwt-go"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

func checkJWT() gin.HandlerFunc {
	return func(g *gin.Context) {
		if err := jwtMiddleware.CheckJWT(g.Writer, g.Request); err != nil {
			g.AbortWithStatus(401)
		}
	}
}

func main() {
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
			g.AbortWithStatus(400)
			return
		}
		g.JSON(200, gin.H{"text": "Hello from private " + userId})
	})

	r.GET("/", func(c *gin.Context) {
		wsHandler(c.Writer, c.Request)
	})

	r.Run()
}
