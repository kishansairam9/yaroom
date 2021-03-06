package main

import (
	"bytes"
	"context"
	"io"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/minio/minio-go/v7"
	"github.com/rs/zerolog/log"
)

func mediaServerHandler(g *gin.Context) {
	var req mediaRequest
	if err := g.BindUri(&req); err != nil {
		g.AbortWithStatusJSON(400, gin.H{"error": "invalid request"})
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
		room_id_split := strings.Split(split_exchange_id[0], "@")
		for _, room := range userMeta.Roomslist {
			if room_id_split[0] == room {
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

func iconServeHandler(g *gin.Context) {
	var req mediaRequest
	if err := g.ShouldBindUri(&req); err != nil {
		dat, _ := os.ReadFile("assets/no-profile.png")
		g.Header("Content-Type", "image/png")
		io.Copy(g.Writer, bytes.NewReader(dat))
		return
	}
	_, err := minioClient.StatObject(context.Background(), miniobucket, req.ObjectId, minio.StatObjectOptions{})
	if err != nil {
		// File doesn't exist, return default profile
		dat, _ := os.ReadFile("assets/no-profile.png")
		g.Header("Content-Type", "image/png")
		io.Copy(g.Writer, bytes.NewReader(dat))
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
	g.Header("Content-Type", "image/jpeg")
	io.Copy(g.Writer, obj)
}

func iconUploadHandler(g *gin.Context) {
	var req iconUploadRequest
	if err := g.BindJSON(&req); err != nil {
		g.AbortWithStatusJSON(400, gin.H{"error": "invalid request type"})
		return
	}

	if req.IconId == "" || len(req.JpegBytes) == 0 {
		g.AbortWithStatusJSON(400, gin.H{"error": "invalid request"})
		return
	}
	rawUserId, exists := g.Get("userId")
	if !exists {
		g.AbortWithStatusJSON(400, gin.H{"error": "not authenticated"})
		return
	}
	userId := rawUserId.(string)

	// Check upload access
	switch 1 {
	default:
		if userId == req.IconId {
			break
		}
		userMeta, err := getUserMetadata(userId)
		if err != nil {
			log.Error().Str("where", "media metadata check").Str("type", "error occured in retrieving data").Msg(err.Error())
			g.AbortWithStatusJSON(500, gin.H{"error": "internal server error"})
			return
		}
		hasAccess := false
		for _, group := range userMeta.Groupslist {
			if req.IconId == group {
				hasAccess = true
				break
			}
		}
		if hasAccess {
			break
		}
		for _, room := range userMeta.Roomslist {
			if req.IconId == room {
				hasAccess = true
				break
			}
		}
		if hasAccess {
			break
		}
		g.AbortWithStatusJSON(400, gin.H{"error": "user doesn't have access to upload"})
		return
	}

	mediaBytes := []byte(req.JpegBytes)
	mediaId := req.IconId

	if _, err := minioClient.PutObject(context.Background(), miniobucket, mediaId, bytes.NewReader(mediaBytes), -1, minio.PutObjectOptions{ContentType: "image/jpeg"}); err != nil {
		log.Error().Str("where", "icon upload").Str("type", "uploading to minio failed at put object").Msg(err.Error())
		g.AbortWithStatusJSON(500, gin.H{"error": "internal server error"})
		return
	}
}
