import 'dart:convert';
import 'dart:async';

import 'package:yaroom/utils/messageExchange.dart';

class ActiveStatusNotifier {
  bool running = true;
  late MessageExchangeStream ws;
  ActiveStatusNotifier({required this.ws});

  void send(Timer _) {
    if (ws.initalized) {
      print("SENT ACTIVE TRUE");
      ws.sendWSMessage(jsonEncode({"type": "Active"}));
    } else {
      print("not sending activity status as ws not yet initalized");
    }
  }
}
