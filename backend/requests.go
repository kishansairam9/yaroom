package main

type testingUser struct {
	UserId string `uri:"userId" binding:"required"`
}

type testingActiveStatus struct {
	UserId string `json:"userId"`
	Active bool   `json:"active"`
}

type mediaRequest struct {
	ObjectId string `uri:"objectid" binding:"required"`
}

// TODO: Remove receiving name and image, backend should have it alread
type fcmTokenUpdate struct {
	Name  string `json:"name"`
	Image string `json:"image,omitempty"`
	Token string `json:"fcm_token"`
}
