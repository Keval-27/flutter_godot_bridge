#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlutterGodotBridgePlugin : NSObject<FlutterPlugin>

@property (nonatomic, strong) FlutterMethodChannel* channel;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;

@end

NS_ASSUME_NONNULL_END
