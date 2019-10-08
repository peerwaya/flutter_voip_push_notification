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


#### AppDelegate.swift


```swift

...

import PushKit                     /* <------ add this line */
import flutter_voip_push_notification      /* <------ add this line */
...

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {

    ...

    /* Add PushKit delegate method */

    // Handle updated push credentials
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void){
        // Register VoIP push token (a property of PKPushCredentials) with server
        FlutterVoipPushNotificationPlugin.didReceiveIncomingPush(with: payload, forType: type.rawValue)
    }

    // Handle incoming pushes
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        // Process the received push
        FlutterVoipPushNotificationPlugin.didUpdate(pushCredentials, forType: type.rawValue);
    }

    ...
}
```

#### AppDelegate.m Modification


```objective-c

...

#import <PushKit/PushKit.h>                    /* <------ add this line */
#import "FlutterVoipPushNotificationPlugin.h"      /* <------ add this line */

...

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

...

/* Add PushKit delegate method */

// Handle updated push credentials
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type {
  // Register VoIP push token (a property of PKPushCredentials) with server
  [FlutterVoipPushNotificationPlugin didUpdatePushCredentials:credentials forType:(NSString *)type];
}

// Handle incoming pushes
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
  // Process the received push
  [FlutterVoipPushNotificationPlugin didReceiveIncomingPushWithPayload:payload forType:(NSString *)type];
}

...

@end

```

## Usage
Add `flutter_voip_push_notification` as a [dependency in your pubspec.yaml file](https://flutter.io/using-packages/).

### Example


```dart

import 'package:flutter/material.dart';
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

```

[1]: https://developer.apple.com/library/ios/documentation/NetworkingInternet/Reference/PushKit_Framework/index.html
[2]: https://developer.apple.com/library/ios/documentation/Performance/Conceptual/EnergyGuide-iOS/OptimizeVoIP.html
[3]: https://github.com/FirebaseExtended/flutterfire/tree/master/packages/firebase_messaging
[4]: https://github.com/react-native-webrtc/react-native-voip-push-notification
[5]: https://developers.google.com/cloud-messaging/concept-options#setting-the-priority-of-a-message
