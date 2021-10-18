
## TODO Later

### Frontend
- [ ] Fix Auth0 logout workaround ([Active issue](https://github.com/MaikuB/flutter_appauth/issues/48)on flutter AppAuth package) - current workaround proposed in comments redirects to browser for logout action
- [ ] Support web
  - [ ] Configure secure storage alternative for Auth0 storage
  - [ ] Write SQL.js update statements for msgs received via FCM 
    - At the time of writing, Google's still working on getting dart to work with FCM on web. If it is supported, SQL.js update statements are not required
  - [ ] Find a workaround for flutter emoji fallback being very large on Web (Active issue) causing irresponsive website or else remove emoji button on keypad
- [ ] Implement ordering of chat's based on their recency

### Backend
- [ ] Ensure optimal Cassandra Queries
  - [ ] Remove allow filtering operations from CQL and use ElasticSearch in Elassandra
  - [ ] Analyse bottleneck queries & frequent queries and look for alternatives
- [ ] Implement unread message handling in backend. Currently frontend on inital login considers all msgs as unread, after opening chat it resets and it handles new messages in frontend itself managing state on disk
