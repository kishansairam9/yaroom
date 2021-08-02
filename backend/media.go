package main

import (
	"context"
	"io"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/minio/minio-go/v7"
	"github.com/rs/zerolog/log"
)

func mediaServerHandler(g *gin.Context) {
	var req mediaRequest
	if err := g.BindUri(&req); err != nil {
		return
	}

	rawUserId, exists := g.Get("userId")
	if !exists {
		g.AbortWithStatusJSON(400, gin.H{"error": "not authenticated"})
		return
	}
	userId := rawUserId.(string)

	stat, err := minioClient.StatObject(context.Background(), miniobucket, req.ObjectId, minio.StatObjectOptions{})
	if err != nil {
		// TODO: if minio server failure don't return err to client,
		// TODO: then report internal server error and set status 500
		g.AbortWithStatusJSON(400, gin.H{"error": err.Error()})
		return
	}

	// Get exchange id (stored in metadata of object) and check access
	split_exchange_id := strings.Split(stat.Metadata["X-Amz-Meta-Key"][0], ":")
	switch len(split_exchange_id) {
	case 1:
		userMeta, err := getUserMetadata(userId)
		if err != nil {
			log.Error().Str("where", "media metadata check").Str("type", "error occured in retrieving data").Msg(err.Error())
			g.AbortWithStatusJSON(500, gin.H{"error": "internal server error"})
			return
		}
		hasAccess := false
		for _, group := range userMeta.Groupslist {
			if split_exchange_id[0] == group {
				hasAccess = true
				break
			}
		}
		if hasAccess {
			break
		}
		for _, room := range userMeta.Roomslist {
			if split_exchange_id[0] == room {
				hasAccess = true
				break
			}
		}
		if hasAccess {
			break
		}
		g.AbortWithStatusJSON(400, gin.H{"error": "user doesn't have access"})
		return
	case 2:
		if !(split_exchange_id[0] == userId || split_exchange_id[1] == userId) {
			g.AbortWithStatusJSON(400, gin.H{"error": "user doesn't have access"})
			return
		}
	default:
		log.Error().Str("where", "media metadata check").Str("type", "metadata format invalid").Msg("invalid split size, not 1 or 2")
		g.AbortWithStatusJSON(400, gin.H{"error": "internal server error"})
		return
	}

	// Get object from minio
	obj, err := minioClient.GetObject(context.Background(), miniobucket, req.ObjectId, minio.GetObjectOptions{})
	if err != nil {
		// TODO: if minio server failure don't return err to client,
		// TODO: then report internal server error and set status 500
		g.AbortWithStatusJSON(400, gin.H{"error": err.Error()})
		return
	}
	g.Header("Content-Type", "application/json")
	io.Copy(g.Writer, obj)
}
