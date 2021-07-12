import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

// Modification of
// https://stackoverflow.com/a/62095514
class WebSocketWrapper {
  StreamController<String> streamController =
      new StreamController.broadcast(sync: true);

  late String wsUrl;

  late WebSocketChannel channel;

  Stream get stream => streamController.stream;
  void add(data) => channel.sink.add(data);

  WebSocketWrapper(this.wsUrl) {
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
    }, onDone: () {
      print("conecting aborted");
      initWebSocketConnection();
    }, onError: (e) {
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
