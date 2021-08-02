## Dev notes

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
