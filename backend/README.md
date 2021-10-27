## Backend

### Directory Structure

```
.
├── assets ===> Assets delivered on backend
│   └── no-profile.png
├── create_elasticindexes.sh ===> Creates Elastic indices needed for search
├── db.go ===> Database queries for metadata
├── docker-compose.yml ===> Docker Setup
├── fcm_notifications.go ===> FCM Notifications methods & request handlers
├── go.mod
├── go.sum
├── jwt.go ===> Auth0 Authentication
├── main.go ===> Entry point for server
├── media.go ===> Media methods & request handlers
├── messages.go ===> Database queries for message data
├── README.md
├── requests.go ===> API end points for frontend requests & testing
├── streams.go ===> NATS Jetstream based updates & routines
├── tables.cql ===> CQL file for Database setup
└── websocket.go ===> Websocket connection handler & go routines
```

### Docker compose
- Create required directories for binding
  - `mkdir -p ~/containerVolumes/elassandra ~/containerVolumes/logs/elassandra ~/containerVolumes/minio`
- Inrease vm.max_map_count for elastic search to work - to 1048575
  - Follow this https://stackoverflow.com/a/50371108 and change amt to 1048575
- `docker-compose up` to start conatiners

### Setup Database
- Create Cassandra tables
  - `docker exec -i yaroom-elassandra cqlsh < tables.cql`
- Create elastic search indexes
  - Execute `create_elasticindexes.sh`

### Gin Server
- For running server with hot reload use `gin` https://github.com/codegangsta/gin
  - Note don't get `gin` from this folder. It will add to modules unnecessarily
  - Use `cd ~ && go get github.com/codegangsta/gin` to install gin
- To run server on port x use --port flag
  - Current frontend uses websocket on port 8884
  - `gin -i --port 8884` from backend directory

### Improvements / to work on late
- [ ] Ensure optimal Cassandra Queries
  - [ ] Remove allow filtering operations from CQL and use ElasticSearch in Elassandra
  - [ ] Analyse bottleneck queries & frequent queries and look for alternatives
