#import <UIKit/UIKit.h>
#import "LGGlassButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface LGGlassFloatingBar : UIView

@property (nonatomic, strong, readonly) UIStackView *quickActionsStack;
@property (nonatomic, strong, readonly) UIStackView *composerStack;
@property (nonatomic, strong, readonly) UITextField *textField;

- (instancetype)initWithQuickActions:(NSArray<LGGlassButton *> *)quickActions;
- (void)attachToView:(UIView *)view keyboardAware:(BOOL)keyboardAware;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
