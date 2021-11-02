# Yet Another [Chat] Room (yaroom)

![yaroom-logo](yaroom_logo/yaroom_full_logo_200x200.png)

> Attempt at creating a "chat room" service

Demo video - [Onedrive link](https://iiitaphyd-my.sharepoint.com/:v:/g/personal/kishan_sairam_students_iiit_ac_in/ES0D14k36LxFs2PsDiq8nzYB5oxgm2PP-gpyLS5-8K08xw?e=DtExGl), enable 1080p in player quality for text readability

## Features

### Friends & Chat
- Users can add others as friends and chat with each other
- Chat supports text & multi-media files
- Search functionality is available with in a chat exchange

### Groups & Rooms
- Users can create groups with other users & chat together
- Rooms are inspired from discord servers, contain multiple channels to exchange messages
- Multi-media messages & text search are available in all exchanges

## Tech Stack

### Frontend
- Frontend is implemented in flutter, with all used packages supporting Android, iOS and Web
- Application currently targets only Android, but can be extended to support Web and iOS

### Backend
- Backend is written in Go Lang
- Cassandra is choosen as Database
  - It is choosen over alternative NoSQL DBs - MongoDB and Couchbase
  - MongoDB doesn't have support for inbuilt caching and intrinsic distributed support which others have
  - For this project, schema is assumed to be static, hence document ability of MongoDB & Couchbase is not utilised
  - Given Cassandra's higher write throughput it was utilised in this work
- Elastic Search is used for text search functionality (via [Elassandra](https://github.com/strapdata/elassandra) integration)
- Minio Object Store is utilised to store media files
- Streams in backend are supported by NATS Jetstream, and are used to send stream updates and active status via Websocket

### External Services
- User login and registration is integrated with Auth0
- Google firebase's FCM is used to send notifications to users
