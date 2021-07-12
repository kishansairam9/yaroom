from typing import Counter
from gevent import monkey; monkey.patch_all()
from ws4py.websocket import WebSocket
from ws4py.server.geventserver import WSGIServer
from ws4py.server.wsgiutils import WebSocketWSGIApplication
from ws4py.messaging import TextMessage
import json


class MockWS(WebSocket):
    counter = 64234

    def received_message(self, message: TextMessage):
        msg = json.loads(message.data)
        msg['msgId'] = self.counter
        self.counter += 1
        print(msg)
        self.send(json.dumps(msg), message.is_binary)

server = WSGIServer(('localhost', 8884), WebSocketWSGIApplication(handler_cls=MockWS))
server.serve_forever()
