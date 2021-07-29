import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

// Modification of
// https://stackoverflow.com/a/62095514

// Uses websocket for communication with server
// Acts as a global source of data in app for view updation and state management
class MessageExchangeStream {
  StreamController<String> streamController =
      new StreamController.broadcast(sync: true);

  late String wsUrl;
  late String token;
  late WebSocketChannel channel;
  bool initalized = false;

  Stream get stream => streamController.stream;
  void addStreamMessage(Map<String, dynamic> data) =>
      streamController.add(jsonEncode(data));
  void sendWSMessage(data) => channel.sink.add(data);

  bool onCallInit = false;

  start(wsUrl, token) {
    this.wsUrl = wsUrl;
    this.token = token;
    initWebSocketConnection();
  }

  initWebSocketConnection() async {
    if (onCallInit) return;
    onCallInit = true;
    print("trying to connect...");
    WebSocketChannel? ret = await connectWs();
    if (ret == null) {
      onCallInit = false;
      Future.delayed(Duration(milliseconds: 10000), initWebSocketConnection);
      return;
    }
    this.channel = ret;
    print("socket connection initializied");
    this.channel.sink.done.then((dynamic _) => _onDisconnected());
    initalized = true;
    broadcastNotifications();
    onCallInit = false;
  }

  broadcastNotifications() {
    this.channel.stream.listen((streamData) {
      streamController.add(streamData);
    }, onDone: () async {
      print("Connection aborted");
      await Future.delayed(Duration(milliseconds: 5000));
      this.close();
      initWebSocketConnection();
    }, onError: (e) async {
      print('Server error: $e');
      this.close();
      await Future.delayed(Duration(milliseconds: 5000));
      initWebSocketConnection();
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

  void _onDisconnected() {
    initWebSocketConnection();
  }

  void dispose() {
    close();
  }

  void close() {
    initalized = false;
    channel.sink.close();
  }
}
