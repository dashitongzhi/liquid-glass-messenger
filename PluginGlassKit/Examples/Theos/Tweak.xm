#import <UIKit/UIKit.h>
#import <LGGlassFloatingBar.h>

static const NSInteger LGKDropInFloatingBarTag = 26063001;

static LGGlassFloatingBar *LGKBuildFloatingBar(void) {
    LGGlassButton *reply = [LGGlassButton chipButtonWithTitle:@"快捷回复" symbolName:nil];
    LGGlassButton *glass = [LGGlassButton chipButtonWithTitle:@"液态 Glass" symbolName:nil];
    LGGlassButton *camera = [LGGlassButton chipButtonWithTitle:@"拍摄" symbolName:@"camera.fill"];
    LGGlassButton *file = [LGGlassButton chipButtonWithTitle:@"文件" symbolName:@"folder.fill"];
    LGGlassButton *add = [LGGlassButton chipButtonWithTitle:@"添加" symbolName:@"plus"];
    return [[LGGlassFloatingBar alloc] initWithQuickActions:@[reply, glass, camera, file, add]];
}

static void LGKMountFloatingBarInHostView(UIView *hostView) {
    if (!hostView || [hostView viewWithTag:LGKDropInFloatingBarTag]) {
        return;
    }

    LGGlassFloatingBar *bar = LGKBuildFloatingBar();
    bar.tag = LGKDropInFloatingBarTag;
    [bar attachToView:hostView keyboardAware:YES];
}

static UIView *LGKDemoVisibleRootView(void) {
    UIWindow *keyWindow = UIApplication.sharedApplication.keyWindow;
    if (!keyWindow) {
        for (UIWindow *window in UIApplication.sharedApplication.windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
    }
    return keyWindow.rootViewController.view ?: keyWindow;
}

static void LGKDemoMountOnVisibleRoot(void) {
    LGKMountFloatingBarInHostView(LGKDemoVisibleRootView());
}

// DROP-IN REPLACEMENT POINT:
// Replace this demo AppDelegate hook with the host controller and mount timing
// owned by your tweak, then call LGKMountFloatingBarInHostView(self.view).
// For example:
//
// %hook YourHostViewController
// - (void)viewDidAppear:(BOOL)animated {
//     %orig;
//     LGKMountFloatingBarInHostView(self.view);
// }
// %end
//
// The AppDelegate fallback below keeps this folder buildable as a standalone
// Theos smoke target, but real WCDuang/wctodo-style tweaks should mount in a
// specific chat, panel, or plugin-owned view instead of every WeChat screen.
%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        LGKDemoMountOnVisibleRoot();
    });
    return result;
}

%end
