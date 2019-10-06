# Flutter VoIP Push Notification
[![pub package](https://img.shields.io/pub/v/flutter_voip_push_notification.svg)](https://pub.dartlang.org/packages/flutter_voip_push_notification)
Flutter VoIP Push Notification - Currently iOS >= 8.0 only

## Motivation

Since iOS 8.0 there is an execellent feature called **VoIP Push Notification** ([PushKit][1]), while [firebase_messaging][3] does not support voip push notification which is only available on iOS >= 8.0 which is the reason for this plugin.

To understand the benefits of **Voip Push Notification**, please see [VoIP Best Practices][2].

**Note 1**: This plugin works for only iOS. You can use [firebase_messaging][3] for Android by [sending high priority push notification][5]

**Note 2** This This plugin was inspired by [react-native-voip-push-notification][4] and [firebase_messaging][3]

### iOS

The iOS version should be >= 8.0 since we are using [PushKit][1].

#### Enable VoIP Push Notification and Get VoIP Certificate

Please refer to [VoIP Best Practices][2].

**Note**: Do NOT follow the `Configure VoIP Push Notification` part from the above link, use the instruction below instead.

## Usage
Add `flutter_voip_push_notification` as a [dependency in your pubspec.yaml file](https://flutter.io/using-packages/).

### Example
```Dart

...

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
...

}

```

[1]: https://developer.apple.com/library/ios/documentation/NetworkingInternet/Reference/PushKit_Framework/index.html
[2]: https://developer.apple.com/library/ios/documentation/Performance/Conceptual/EnergyGuide-iOS/OptimizeVoIP.html
[3]: https://github.com/FirebaseExtended/flutterfire/tree/master/packages/firebase_messaging
[4]: https://github.com/react-native-webrtc/react-native-voip-push-notification
[5]: https://developers.google.com/cloud-messaging/concept-options#setting-the-priority-of-a-message
