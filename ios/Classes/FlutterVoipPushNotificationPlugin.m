#import "FlutterVoipPushNotificationPlugin.h"

NSString *const FlutterVoipRemoteNotificationsRegistered = @"voipRemoteNotificationsRegistered";
NSString *const FlutterVoipPushTokenInvalidated = @"voipPushTokenInvalidated";
NSString *const FlutterVoipLocalNotificationReceived = @"voipLocalNotificationReceived";
NSString *const FlutterVoipRemoteNotificationReceived = @"voipRemoteNotificationReceived";

BOOL RunningInAppExtension(void)
{
    return [[[[NSBundle mainBundle] bundlePath] pathExtension] isEqualToString:@"appex"];
}

@implementation FlutterVoipPushNotificationPlugin {
    FlutterMethodChannel* _channel;
    BOOL _resumingFromBackground;
    PKPushRegistry * _voipRegistry;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterVoipPushNotificationPlugin* instance = [[FlutterVoipPushNotificationPlugin alloc] initWithRegistrar:registrar messenger:[registrar messenger]];
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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRemoteNotificationsRegistered:)
                                                     name:FlutterVoipRemoteNotificationsRegistered
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleLocalNotificationReceived:)
                                                     name:FlutterVoipLocalNotificationReceived
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleRemoteNotificationReceived:)
                                                     name:FlutterVoipRemoteNotificationReceived
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handlePushTokenInvalidated:)
                                                     name:FlutterVoipPushTokenInvalidated
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *method = call.method;
    if ([@"requestNotificationPermissions" isEqualToString:method]) {
        if (RunningInAppExtension()) {
            result(nil);
            return;
        }
        [self registerUserNotification:call.arguments result:result];
    }if ([@"checkPermissions" isEqualToString:method]) {
        if (RunningInAppExtension()) {
            result(@{@"alert": @NO, @"badge": @NO, @"sound": @NO});
            return;
        }
        result([self checkPermissions]);
    }if ([@"presentLocalNotification" isEqualToString:method]) {
        [self presentLocalNotification:call.arguments];
        result(nil);
    }if ([@"getToken" isEqualToString:method]) {
        result([self getToken]);
    }else {
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
    result(nil);
}

- (NSDictionary *)checkPermissions
{
    NSUInteger types = [[UIApplication sharedApplication] currentUserNotificationSettings].types;
    return @{
             @"alert": @((types & UIUserNotificationTypeAlert) > 0),
             @"badge": @((types & UIUserNotificationTypeBadge) > 0),
             @"sound": @((types & UIUserNotificationTypeSound) > 0),
             };
}

- (void)voipRegistration
{
#ifdef DEBUG
    NSLog(@"[FlutterVoipPushNotificationPlugin] voipRegistration");
#endif
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    // Create a push registry object
    _voipRegistry = [[PKPushRegistry alloc] initWithQueue: mainQueue];
    // Set the registry's delegate to self
    _voipRegistry.delegate = (FlutterVoipPushNotificationPlugin *)[UIApplication sharedApplication].delegate;
    // Set the push type to VoIP
    _voipRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)presentLocalNotification:(UILocalNotification *)notification
{
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

#pragma mark - AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [self voipRegistration];
  return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  _resumingFromBackground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  _resumingFromBackground = NO;
}


- (NSString*)getToken
{
    NSMutableString *hexString = [NSMutableString string];
    NSData* token = [_voipRegistry pushTokenForType:PKPushTypeVoIP];
    NSUInteger voipTokenLength = token.length;
    const unsigned char *bytes = token.bytes;
    for (NSUInteger i = 0; i < voipTokenLength; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    return hexString;
}

#pragma mark - PKPushRegistryDelegate methods

+ (void)didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type
{
#ifdef DEBUG
    NSLog(@"[FlutterVoipPushNotificationPlugin] didUpdatePushCredentials credentials.token = %@, type = %@", credentials.token, type);
#endif
    NSMutableString *hexString = [NSMutableString string];
    NSUInteger voipTokenLength = credentials.token.length;
    const unsigned char *bytes = credentials.token.bytes;
    for (NSUInteger i = 0; i < voipTokenLength; i++) {
        [hexString appendFormat:@"%02x", bytes[i]];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:FlutterVoipRemoteNotificationsRegistered
                                                        object:self
                                                      userInfo:@{@"deviceToken" : [hexString copy]}];
   
}

+ (void)didInvalidatePushTokenForType:(NSString *)type
{
#ifdef DEBUG
    NSLog(@"[FlutterVoipPushNotificationPlugin] didInvalidatePushTokenFor type = %@", type);
#endif
    [[NSNotificationCenter defaultCenter] postNotificationName:FlutterVoipPushTokenInvalidated
                                                        object:self];
}

+ (void)didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type
{
#ifdef DEBUG
    NSLog(@"[FlutterVoipPushNotificationPlugin] didReceiveIncomingPushWithPayload payload.dictionaryPayload = %@, type = %@", payload.dictionaryPayload, type);
#endif
    [[NSNotificationCenter defaultCenter] postNotificationName:FlutterVoipRemoteNotificationReceived
                                                        object:self
                                                      userInfo:payload.dictionaryPayload];
}

- (void)handleRemoteNotificationsRegistered:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"[FlutterVoipPushNotificationPlugin] handleRemoteNotificationsRegistered notification.userInfo = %@", notification.userInfo);
#endif
    [_channel invokeMethod:@"onToken" arguments:notification.userInfo];
}

- (void)handleLocalNotificationReceived:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"[FlutterVoipPushNotificationPlugin] handleLocalNotificationReceived notification.userInfo = %@",notification.userInfo);
#endif
    if (_resumingFromBackground) {
        [_channel invokeMethod:@"onResume" arguments:@{@"local": @YES, @"notification": notification.userInfo}];
    } else {
        [_channel invokeMethod:@"onMessage" arguments:@{@"local": @YES, @"notification": notification.userInfo}];
    }
}

- (void)handleRemoteNotificationReceived:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"[FlutterVoipPushNotificationPlugin] handleRemoteNotificationReceived notification.userInfo = %@", notification.userInfo);
#endif
    if (_resumingFromBackground) {
        [_channel invokeMethod:@"onResume" arguments:@{@"local": @NO, @"notification": notification.userInfo}];
    } else {
        [_channel invokeMethod:@"onMessage" arguments:@{@"local": @NO, @"notification": notification.userInfo}];
    }
}

- (void)handlePushTokenInvalidated:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"[FlutterVoipPushNotificationPlugin] handlePushTokenInvalidated notification.userInfo = %@", notification.userInfo);
#endif
    [_channel invokeMethod:@"onTokenInvalidated" arguments:@{@"deviceToken": [self getToken]}];
}

@end
