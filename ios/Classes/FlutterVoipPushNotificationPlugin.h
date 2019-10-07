#import <Flutter/Flutter.h>
#import <PushKit/PushKit.h>

@interface FlutterVoipPushNotificationPlugin : NSObject<FlutterPlugin>
+ (void)didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type;
+ (void)didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type;
@end
