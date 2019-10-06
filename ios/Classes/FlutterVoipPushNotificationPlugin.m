#import "FlutterVoipPushNotificationPlugin.h"
#import <flutter_voip_push_notification/flutter_voip_push_notification-Swift.h>

@implementation FlutterVoipPushNotificationPlugin {
    FlutterMethodChannel* _channel;
    BOOL _resumingFromBackground;
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterVoipPushNotificationPlugin* instance = [[FlutterVoipPushNotificationPlugin alloc] initWithRegistrar:registrar
                                                                       messenger:[registrar messenger]];
    [registrar addApplicationDelegate:instance];
}

- (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
                      messenger:(NSObject<FlutterBinaryMessenger>*)messenger{
    
    self = [super init];
    
    if (self) {
        _channel = [FlutterMethodChannel
                    methodChannelWithName:@"com.peerwaya/flutter_voip_push_notification"
                    binaryMessenger:[registrar messenger]];
        [registrar addMethodCallDelegate:self channel:_channel];
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *method = call.method;
    if ([@"configure" isEqualToString:method]) {
        [self registerUserNotification:call.arguments result:result];
        result(nil);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)registerUserNotification:(NSDictionary *)permissions result:(FlutterResult)result
{
    UIUserNotificationType notificationTypes = 0;
    if ([permissions[@"sound"] boolValue]) {
        notificationTypes |= UIUserNotificationTypeSound;
    }
    if ([permissions[@"alert"] boolValue]) {
        notificationTypes |= UIUserNotificationTypeAlert;
    }
    if ([permissions[@"badge"] boolValue]) {
        notificationTypes |= UIUserNotificationTypeBadge;
    }
    UIUserNotificationSettings *settings =
    [UIUserNotificationSettings settingsForTypes:notificationTypes categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    [self voipRegistration];
    result(nil);
}

- (void)voipRegistration
{
    NSLog(@"[FlutterVoipPushNotificationPlugin] voipRegistration");
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    // Create a push registry object
    PKPushRegistry * voipRegistry = [[PKPushRegistry alloc] initWithQueue: mainQueue];
    // Set the registry's delegate to self
    voipRegistry.delegate = self;
    // Set the push type to VoIP
    voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}
                               
#pragma mark - PKPushRegistryDelegate methods
                               
// Handle updated push credentials
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials: (PKPushCredentials *)credentials forType:(NSString *)type {
   // Register VoIP push token (a property of PKPushCredentials) with server
    NSLog(@"[FlutterVoipPushNotificationPlugin] didUpdatePushCredentials credentials.token = %@, type = %@", credentials.token, type);
    NSMutableString *hexString = [NSMutableString string];
    NSUInteger voipTokenLength = credentials.token.length;
    const unsigned char *bytes = credentials.token.bytes;
    for (NSUInteger i = 0; i < voipTokenLength; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    [_channel invokeMethod:@"onToken" arguments:[hexString copy]];
}
                               
// Handle incoming pushes
- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type {
   // Process the received push
    NSLog(@"[FlutterVoipPushNotificationPlugin] didReceiveIncomingPushWithPayload payload.dictionaryPayload = %@, type = %@", payload.dictionaryPayload, type);
    if (_resumingFromBackground) {
        [_channel invokeMethod:@"onResume" arguments:payload.dictionaryPayload];
    } else {
        [_channel invokeMethod:@"onMessage" arguments:payload.dictionaryPayload];
    }
}

@end
