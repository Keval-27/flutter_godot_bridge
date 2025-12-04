#import "FlutterGodotBridgePlugin.h"
#import "GodotViewFactory.h"

@interface FlutterGodotBridgePlugin()
@property (nonatomic, strong) NSObject<FlutterBinaryMessenger>* messenger;
@property (nonatomic, strong) NSMutableDictionary* activeViews;
@end

@implementation FlutterGodotBridgePlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
            methodChannelWithName:@"flutter_godot_bridge"
                  binaryMessenger:[registrar messenger]];

    FlutterGodotBridgePlugin* instance = [[FlutterGodotBridgePlugin alloc] init];
    instance.channel = channel;
    instance.messenger = [registrar messenger];
    instance.activeViews = [[NSMutableDictionary alloc] init];

    [registrar addMethodCallDelegate:instance channel:channel];

    // Register platform view factory
    GodotViewFactory* factory = [[GodotViewFactory alloc]
            initWithMessenger:[registrar messenger]];
    [registrar registerViewFactory:factory withId:@"godot_view"];

    NSLog(@"FlutterGodotBridgePlugin registered successfully");
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    @try {
        if ([@"initializeGodot" isEqualToString:call.method]) {
            [self handleInitializeGodot:call.arguments result:result];
        } else if ([@"sendMessage" isEqualToString:call.method]) {
            [self handleSendMessage:call.arguments result:result];
        } else if ([@"sendMessageSync" isEqualToString:call.method]) {
            [self handleSendMessageSync:call.arguments result:result];
        } else if ([@"getPerformanceMetrics" isEqualToString:call.method]) {
            [self handleGetPerformanceMetrics:result];
        } else if ([@"disposeGodot" isEqualToString:call.method]) {
            [self handleDisposeGodot:result];
        } else {
            result(FlutterMethodNotImplemented);
        }
    } @catch (NSException *exception) {
        result([FlutterError errorWithCode:@"PLUGIN_ERROR"
                                   message:exception.reason
                                   details:exception.userInfo]);
    }
}

- (void)handleInitializeGodot:(NSDictionary*)arguments result:(FlutterResult)result {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Initialize Godot with provided configuration
        BOOL success = YES;

        // TODO: Add actual Godot initialization logic here
        NSLog(@"Initializing Godot with config: %@", arguments);

        // Simulate initialization delay
        [NSThread sleepForTimeInterval:0.1];

        dispatch_async(dispatch_get_main_queue(), ^{
            result(@(success));
        });
    });
}

- (void)handleSendMessage:(NSDictionary*)arguments result:(FlutterResult)result {
    NSString* channel = arguments[@"channel"];
    NSDictionary* data = arguments[@"data"];
    NSNumber* timestamp = arguments[@"timestamp"];

    if (!channel || !data) {
        result([FlutterError errorWithCode:@"INVALID_ARGS"
                                   message:@"Channel and data are required"
                                   details:nil]);
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // TODO: Send message to Godot
        BOOL success = [self sendMessageToGodot:data channel:channel timestamp:timestamp];

        dispatch_async(dispatch_get_main_queue(), ^{
            result(@(success));
        });
    });
}

- (void)handleSendMessageSync:(NSDictionary*)arguments result:(FlutterResult)result {
    NSString* channel = arguments[@"channel"];
    NSDictionary* data = arguments[@"data"];
    NSNumber* timestamp = arguments[@"timestamp"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // TODO: Send sync message and wait for response
        NSDictionary* response = [self sendSyncMessageToGodot:data channel:channel timestamp:timestamp];

        dispatch_async(dispatch_get_main_queue(), ^{
            result(response);
        });
    });
}

- (void)handleGetPerformanceMetrics:(FlutterResult)result {
    NSDictionary* metrics = @{
            @"messagesSent": @(0),
            @"messagesReceived": @(0),
            @"averageLatencyMs": @(0.0),
            @"minLatencyMs": @(0.0),
            @"maxLatencyMs": @(0.0),
            @"platform": @"iOS"
    };

    result(metrics);
}

- (void)handleDisposeGodot:(FlutterResult)result {
    // Clean up resources
    [self.activeViews removeAllObjects];
    result(@(YES));
}

- (BOOL)sendMessageToGodot:(NSDictionary*)data channel:(NSString*)channel timestamp:(NSNumber*)timestamp {
    // TODO: Implement actual Godot messaging
    NSLog(@"Sending message to Godot - Channel: %@, Data: %@", channel, data);
    return YES;
}

- (NSDictionary*)sendSyncMessageToGodot:(NSDictionary*)data channel:(NSString*)channel timestamp:(NSNumber*)timestamp {
    // TODO: Implement sync messaging with Godot
    NSLog(@"Sending sync message to Godot - Channel: %@", channel);

    return @{
            @"success": @(YES),
            @"response": @"Mock response from iOS",
            @"timestamp": @([[NSDate date] timeIntervalSince1970] * 1000),
            @"originalChannel": channel
    };
}

@end
