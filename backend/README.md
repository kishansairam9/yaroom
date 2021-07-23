## Dev notes

### Docker compose
- Create required directories for binding
  - `mkdir -p ~/containerVolumes/mongodb ~/containerVolumes/logs/mongodb ~/containerVolumes/elassandra ~/containerVolumes/logs/elassandra ~/containerVolumes/rabbitmq ~/containerVolumes/minio`
- `docker-compose up` to start conatiners

### Gin Server
- For running server with hot reload use `gin` https://github.com/codegangsta/gin
  - Note don't get `gin` from this folder. It will add to modules unnecessarily
  - Use `cd ~ && go get github.com/codegangsta/gin` to install gin
- To run server on port x use --port flag
  - Current frontend uses websocket on port 8884
  - `gin -i --port 8884` from backend directory
