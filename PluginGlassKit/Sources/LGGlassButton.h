#import <UIKit/UIKit.h>
#import "LGGlassView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LGGlassButton : UIControl

@property (nonatomic, strong, readonly) LGGlassView *glassView;
@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;

+ (instancetype)circleButtonWithSymbolName:(NSString *)symbolName;
+ (instancetype)chipButtonWithTitle:(NSString *)title symbolName:(nullable NSString *)symbolName;

@end

NS_ASSUME_NONNULL_END
