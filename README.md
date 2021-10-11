# Yet Another [Chat] Room (yaroom)

![yaroom-logo](yaroom_logo/yaroom_full_logo_200x200.png)

> Attempt at creating a "chat room" service

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
- Message data store is backed by Cassandra
  - It is choosen over alternative NoSQL DBs - MongoDB and Couchbase
  - Cassandra has higher write throughput and performance when compared to Couchbase
  - Since, for this project schema is considered to be static, Couchbase's document ability is not utilised, hence Cassandra reigns for our usecase
  - Along with above advantages, cassandra has inbuit caching, intrinsic distributed support over MongoDB
- Minio Object Store is used for Media Storage and Elastic Search for Full Text Search Capability
- Active Status change subscriptions are supported by NATS Jetstream Stream

### External Services
- User login and registration is integrated with Auth0
- Google firebase's FCM is used to send notifications to users

## Improvements

### Frontend
- [ ] Fix Auth0 logout workaround ([Active issue](https://github.com/MaikuB/flutter_appauth/issues/48)on flutter AppAuth package) - current workaround proposed in comments redirects to browser for logout action
- [ ] Support web
  - [ ] Configure secure storage alternative for Auth0 storage
  - [ ] Write SQL.js update statements for msgs received via FCM 
    - At the time of writing, Google's still working on getting dart to work with FCM on web. If it is supported, SQL.js update statements are not required
  - [ ] Find a workaround for flutter emoji fallback being very large on Web (Active issue) causing irresponsive website or else remove emoji button on keypad

### Backend
- [ ] Ensure optimal Cassandra Queries
  - [ ] Remove allow filtering operations from CQL and use ElasticSearch in Elassandra
  - [ ] Analyse bottleneck queries & frequent queries and look for alternatives
