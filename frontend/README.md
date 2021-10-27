# Frontend

### Directory Structure
> TODO ADD

### Commands
- Run flutter app using CMD line `flutter run` or from Debug mode in VSCode
- Use `adb reverse tcp:8884 tcp:8884` to forward localhost 8884 (backend port) to android phone
- Watch for adb disconnects, they happen sometimes randomly `watch -n 1 adb reverse --list` ensure 8884 is forward

### Improvements / to work on later
- [ ] Fix Auth0 logout workaround ([Active issue](https://github.com/MaikuB/flutter_appauth/issues/48) on flutter AppAuth package) - current workaround proposed in comments redirects to browser for logout action
- [ ] Implement ordering of chats based on their recency
- [ ] Support web
  - [ ] Configure secure storage alternative for Auth0 storage
  - [ ] Write SQL.js update statements for msgs received via FCM 
    - At the time of writing, Google's still working on getting dart to work with FCM on web. If it is supported, SQL.js update statements are not required
  - [ ] Find a workaround for flutter emoji fallback being very large on Web (Active issue) causing irresponsive website or else remove emoji button on keypad

#### Web note
- Unzip web/sqljs.tar.gz in web/ folder for dependencies
- Running web from extension of VSCode fails to load WASM dependency, only run with CLI `flutter run -d chrome`
- NOTE unfinished implementation