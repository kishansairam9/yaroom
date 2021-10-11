import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:yaroom/utils/types.dart';

// Modification of
// https://stackoverflow.com/a/62095514

// Uses websocket for communication with server
// Acts as a global source of data in app for view updation and state management
class MessageExchangeStream {
  StreamController<String> streamController =
      new StreamController.broadcast(sync: true);

  StreamController<ConnectivityFlags> connected =
      new StreamController.broadcast(sync: true);

  late String wsUrl;
  late String token;
  late WebSocketChannel channel;
  bool initalized = false;
  bool loggedOut = true;

  Stream get stream => streamController.stream;
  void addStreamMessage(Map<String, dynamic> data) =>
      streamController.add(jsonEncode(data));
  void sendWSMessage(data) => channel.sink.add(data);

  bool onCallInit = false;

  start(wsUrl, token) {
    loggedOut = false;
    this.wsUrl = wsUrl;
    this.token = token;
    initWebSocketConnection();
  }

  void updateInitialized(bool state) {
    initalized = state;
    connected.sink
        .add(state ? ConnectivityFlags.wsActive : ConnectivityFlags.wsRetrying);
  }

  initWebSocketConnection() async {
    if (loggedOut || onCallInit) return;
    onCallInit = true;
    print("trying to connect...");
    WebSocketChannel? ret = await connectWs();
    if (ret == null) {
      onCallInit = false;
      await Future.delayed(Duration(milliseconds: 3000));
      initWebSocketConnection();
      return;
    }
    this.channel = ret;
    print("socket connection initializied");
    this.channel.sink.done.then((dynamic _) => _onDisconnected());
    updateInitialized(true);
    broadcastNotifications();
    onCallInit = false;
  }

  broadcastNotifications() {
    this.channel.stream.listen((streamData) {
      streamController.add(streamData);
    }, onDone: () async {
      print("Connection aborted");
      await _onDisconnected();
    }, onError: (e) async {
      print('Server error: $e');
      await _onDisconnected();
    });
  }

  connectWs() async {
    try {
      // BUG in DART https://github.com/flutter/flutter/issues/41573 https://github.com/flutter/flutter/issues/41573#issuecomment-580370766
      return IOWebSocketChannel.connect(Uri.parse(wsUrl),
          headers: <String, String>{
            'Authorization': "Bearer $token",
          });
    } catch (e) {
      print("Error! can not connect WS connectWs " + e.toString());
      return null;
    }
  }

  Future<void> _onDisconnected() async {
    this.close();
    await Future.delayed(Duration(milliseconds: 5000));
    initWebSocketConnection();
  }

  void dispose() {
    this.close();
    this.connected.close();
  }

  void close() {
    loggedOut = true;
    initalized = false;
    connected.sink.add(ConnectivityFlags.closed);
    channel.sink.close();
  }
}
