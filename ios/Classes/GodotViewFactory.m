#import "GodotViewFactory.h"
#import <UIKit/UIKit.h>

@implementation GodotPlatformView {
    UIView* _godotView;
    NSDictionary* _creationParams;
    NSObject<FlutterBinaryMessenger>* _messenger;
    int64_t _viewId;
}

- (instancetype)initWithFrame:(CGRect)frame
                       viewId:(int64_t)viewId
                    arguments:(id _Nullable)args
                    messenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    self = [super init];
    if (self) {
        _viewId = viewId;
        _creationParams = args;
        _messenger = messenger;
        [self createGodotView:frame];
    }
    return self;
}

- (void)createGodotView:(CGRect)frame {
    // Create the main container view
    _godotView = [[UIView alloc] initWithFrame:frame];
    _godotView.backgroundColor = [UIColor blackColor];

    // Add a label to show this is the Godot view area
    UILabel* label = [[UILabel alloc] init];
    label.text = @"Godot Game View\n(iOS)";
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:16];

    // Center the label in the view
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [_godotView addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
            [label.centerXAnchor constraintEqualToAnchor:_godotView.centerXAnchor],
            [label.centerYAnchor constraintEqualToAnchor:_godotView.centerYAnchor],
            [label.widthAnchor constraintLessThanOrEqualToAnchor:_godotView.widthAnchor constant:-20],
            [label.heightAnchor constraintLessThanOrEqualToAnchor:_godotView.heightAnchor constant:-20]
    ]];

    // TODO: Initialize actual Godot view here
    // This would involve loading Godot framework and setting up the game view

    NSLog(@"Created Godot platform view with frame: %@ and params: %@",
          NSStringFromCGRect(frame), _creationParams);
}

- (UIView*)view {
    return _godotView;
}

@end

@implementation GodotViewFactory {
    NSObject<FlutterBinaryMessenger>* _messenger;
}

- (instancetype)initWithMessenger:(NSObject<FlutterBinaryMessenger>*)messenger {
    self = [super init];
    if (self) {
        _messenger = messenger;
    }
    return self;
}

- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
    return [[GodotPlatformView alloc] initWithFrame:frame
                                             viewId:viewId
                                          arguments:args
                                          messenger:_messenger];
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

@end
