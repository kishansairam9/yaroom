package main

type testingUser struct {
	UserId string `uri:"userId" binding:"required"`
}

type mediaRequest struct {
	ObjectId string `uri:"objectid" binding:"required"`
}
