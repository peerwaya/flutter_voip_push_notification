import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

typedef Future<dynamic> MessageHandler(Map<String, dynamic> message);

class FlutterVoipPushNotification {
  factory FlutterVoipPushNotification() => _instance;

  @visibleForTesting
  FlutterVoipPushNotification.private(MethodChannel channel)
      : _channel = channel;

  static final FlutterVoipPushNotification _instance = FlutterVoipPushNotification.private(
      const MethodChannel('com.peerwaya/flutter_voip_push_notification'));

  final MethodChannel _channel;

  MessageHandler _onMessage;
  MessageHandler _onResume;

  final StreamController<String> _tokenStreamController =
  StreamController<String>.broadcast();

  /// Fires when a new device token is generated.
  Stream<String> get onTokenRefresh {
    return _tokenStreamController.stream;
  }

  /// Sets up [MessageHandler] for incoming messages.
  void configure({
    MessageHandler onMessage,
    MessageHandler onResume,
  }) {
    _onMessage = onMessage;
    _onResume = onResume;
    _channel.setMethodCallHandler(_handleMethod);
    _channel.invokeMethod<void>('configure');
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case "onToken":
        final String token = call.arguments;
        _tokenStreamController.add(token);
        return null;
      case "onMessage":
        return _onMessage(call.arguments.cast<String, dynamic>());
      case "onResume":
        return _onResume(call.arguments.cast<String, dynamic>());
      default:
        throw UnsupportedError("Unrecognized JSON message");
    }
  }

}
