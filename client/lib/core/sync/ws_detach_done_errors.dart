import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

/// [WebSocketChannel.sink.done] completes with errors that are otherwise easy to miss
/// (Windows errno 121, hub overload during bulk catalog mirror). Handling here avoids
/// "Unhandled Exception: WebSocketChannelException" leaking to Zone.
void detachWebSocketSinkDone(WebSocketChannel channel) {
  unawaited(
    channel.sink.done.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    ),
  );
}
