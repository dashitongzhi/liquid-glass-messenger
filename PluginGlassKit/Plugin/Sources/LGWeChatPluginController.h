#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LGWeChatPluginController : NSObject

+ (instancetype)sharedController;
- (void)installIfEligibleInViewController:(UIViewController *)viewController;
- (void)detachFromViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
