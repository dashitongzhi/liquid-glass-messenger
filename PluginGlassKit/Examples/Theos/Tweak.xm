#import <UIKit/UIKit.h>
#import "../../Sources/LGGlassFloatingBar.h"

static LGGlassFloatingBar *LGDemoFloatingBar(void) {
    LGGlassButton *reply = [LGGlassButton chipButtonWithTitle:@"快捷回复" symbolName:nil];
    LGGlassButton *glass = [LGGlassButton chipButtonWithTitle:@"液态 Glass" symbolName:nil];
    LGGlassButton *camera = [LGGlassButton chipButtonWithTitle:@"拍摄" symbolName:@"camera.fill"];
    LGGlassButton *file = [LGGlassButton chipButtonWithTitle:@"文件" symbolName:@"folder.fill"];
    LGGlassButton *add = [LGGlassButton chipButtonWithTitle:@"添加" symbolName:@"plus"];
    return [[LGGlassFloatingBar alloc] initWithQuickActions:@[reply, glass, camera, file, add]];
}

static UIView *LGDemoVisibleRootView(void) {
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

static void LGDemoInstallFloatingBar(void) {
    UIView *host = LGDemoVisibleRootView();
    if (!host || [host viewWithTag:26063001]) return;

    LGGlassFloatingBar *bar = LGDemoFloatingBar();
    bar.tag = 26063001;
    [bar attachToView:host keyboardAware:YES];
}

// Demo-only entry point: installs the glass bar after WeChat finishes launching.
// For a real plugin, call LGDemoInstallFloatingBar from the specific controller
// or feature surface you own instead of globally adding it to every screen.
%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        LGDemoInstallFloatingBar();
    });
    return result;
}

%end
