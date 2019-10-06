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

  @override
  void initState() {
    super.initState();
    registerVoipNotification();
  }

  // Configures a voip push notification
  Future<void> registerVoipNotification() async {
    // listen to voip device token changes
    FlutterVoipPushNotification().onTokenRefresh.listen((String token) {
      setState(() {
        _pushToken = token;
      });
    });
    FlutterVoipPushNotification().configure(
        onMessage: (Map<String, dynamic> payload) {
      // handle foreground notification
      print("received on foreground payload: $payload");
      return null;
    }, onResume: (Map<String, dynamic> payload) {
      print("received on background payload: $payload");
      // handle background notification
      return null;
    });
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
