#import <UIKit/UIKit.h>
#import "LGGlassStyle.h"

NS_ASSUME_NONNULL_BEGIN

@interface LGGlassView : UIView

@property (nonatomic, strong, readonly) UIStackView *contentStack;
@property (nonatomic, strong) LGGlassStyle *style;

- (instancetype)initWithStyle:(LGGlassStyle *)style;
- (void)setPressed:(BOOL)pressed animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
