import 'dart:convert';

import 'package:yaroom/utils/messageExchange.dart';

class ActiveStatusNotifier {
  bool running = true;
  late MessageExchangeStream ws;
  ActiveStatusNotifier({required this.ws}) {
    loop();
  }

  void loop() async {
    while (true) {
      await Future.delayed(Duration(seconds: 3));
      if (running) {
        if (ws.initalized) {
          print("SENT ACTIVE TRUE");
          ws.sendWSMessage(jsonEncode({"type": "Active"}));
        } else {
          print("not sending activity status as ws not yet initalized");
        }
      }
    }
  }

  void stop() {
    if (running) {
      running = false;
    }
  }

  void start() {
    if (!running) {
      running = true;
    }
  }
}
