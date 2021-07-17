package main

import (
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func checkJWT() gin.HandlerFunc {
	return func(c *gin.Context) {
		if err := jwtMiddleware.CheckJWT(c.Writer, c.Request); err != nil {
			c.AbortWithStatus(401)
		}
	}
}

func main() {
	r := gin.Default()
	r.Use(cors.Default())

	r.GET("/ping", func(g *gin.Context) {
		g.JSON(200, gin.H{"text": "Hello from public"})
	})

	r.GET("/secured/ping", checkJWT(), func(g *gin.Context) {
		g.JSON(200, gin.H{"text": "Hello from private"})
	})

	r.GET("/ws", func(c *gin.Context) {
		wsHandler(c.Writer, c.Request)
	})

	r.Run()
}
