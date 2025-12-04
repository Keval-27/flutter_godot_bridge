#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface GodotViewFactory : NSObject<FlutterPlatformViewFactory>

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger;

@end

@interface GodotPlatformView : NSObject<FlutterPlatformView>

- (instancetype)initWithFrame:(CGRect)frame
        viewId:(int64_t)viewId
        arguments:(id _Nullable)args
        messenger:(NSObject<FlutterBinaryMessenger>*)messenger;

@end

        NS_ASSUME_NONNULL_END
