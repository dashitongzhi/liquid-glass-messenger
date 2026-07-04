#import <UIKit/UIKit.h>
#import <LGWeChatPluginController.h>

static BOOL LGIsWeChatProcess(void) {
    NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
    return [bundleID isEqualToString:@"com.tencent.xin"];
}

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (LGIsWeChatProcess()) {
        [[LGWeChatPluginController sharedController] installIfEligibleInViewController:self];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    if (LGIsWeChatProcess()) {
        [[LGWeChatPluginController sharedController] detachFromViewController:self];
    }
    %orig;
}

%end
