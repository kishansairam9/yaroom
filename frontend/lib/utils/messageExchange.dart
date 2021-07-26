import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

// Modification of
// https://stackoverflow.com/a/62095514
// Uses websocket for communication with server
// Acts as a global source of data in app for view updation and state management
class MessageExchangeStream {
  StreamController<String> streamController =
      new StreamController.broadcast(sync: true);

  late String wsUrl;

  late WebSocketChannel channel;

  Stream get stream => streamController.stream;
  void addStreamMessage(Map<String, dynamic> data) =>
      streamController.add(jsonEncode(data));
  void sendWSMessage(data) => channel.sink.add(data);

  MessageExchangeStream(this.wsUrl) {
    initWebSocketConnection();
  }

  initWebSocketConnection() async {
    print("conecting...");
    this.channel = await connectWs();
    print("socket connection initializied");
    this.channel.sink.done.then((dynamic _) => _onDisconnected());
    broadcastNotifications();
  }

  broadcastNotifications() {
    this.channel.stream.listen((streamData) {
      streamController.add(streamData);
    }, onDone: () async {
      await Future.delayed(Duration(milliseconds: 10000));
      print("conecting aborted");
      initWebSocketConnection();
    }, onError: (e) async {
      await Future.delayed(Duration(milliseconds: 10000));
      print('Server error: $e');
      initWebSocketConnection();
    });
  }

  connectWs() async {
    try {
      // BUG in DART https://github.com/flutter/flutter/issues/41573 https://github.com/flutter/flutter/issues/41573#issuecomment-580370766
      // TODO FIND A WORKAROUND
      // If webserver goes down app crashes
      return WebSocketChannel.connect(Uri.parse(wsUrl));
    } catch (e) {
      print("Error! can not connect WS connectWs " + e.toString());
      await Future.delayed(Duration(milliseconds: 10000));
      return connectWs();
    }
  }

  void _onDisconnected() {
    initWebSocketConnection();
  }

  void dispose() {
    close();
  }

  void close() {
    channel.sink.close();
  }
}
