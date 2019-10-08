import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_voip_push_notification/flutter_voip_push_notification.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _pushToken = '';
  FlutterVoipPushNotification _voipPush = FlutterVoipPushNotification();
  @override
  void initState() {
    super.initState();
    configure();
  }

  // Configures a voip push notification
  Future<void> configure() async {
    // request permission (required)
    await _voipPush.requestNotificationPermissions();

    // listen to voip device token changes
    _voipPush.onTokenRefresh.listen(onToken);

    // do configure voip push
    _voipPush.configure(onMessage: onMessage, onResume: onResume);
  }

  /// Called when the device token changes
  void onToken(String token) {
    // send token to your apn provider server
    setState(() {
      _pushToken = token;
    });
  }

  /// Called to receive notification when app is in foreground
  ///
  /// [isLocal] is true if its a local notification or false otherwise (remote notification)
  /// [payload] the notification payload to be processed. use this to present a local notification
  Future<dynamic> onMessage(bool isLocal, Map<String, dynamic> payload) {
    // handle foreground notification
    print("received on foreground payload: $payload, isLocal=$isLocal");
    return null;
  }

  /// Called to receive notification when app is resuming from background
  ///
  /// [isLocal] is true if its a local notification or false otherwise (remote notification)
  /// [payload] the notification payload to be processed. use this to present a local notification
  Future<dynamic> onResume(bool isLocal, Map<String, dynamic> payload) {
    // handle background notification
    print("received on background payload: $payload, isLocal=$isLocal");
    showLocalNotification(payload);
    return null;
  }

  showLocalNotification(Map<String, dynamic> notification) {
    String alert = notification["aps"]["alert"];
    _voipPush.presentLocalNotification(LocalNotification(
      alertBody: "Hello $alert",
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Received Voip Push token: $_pushToken\n'),
        ),
      ),
    );
  }
}
