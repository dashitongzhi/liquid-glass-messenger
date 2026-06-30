#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, LGGlassMaterial) {
    LGGlassMaterialClear = 0,
    LGGlassMaterialRegular,
    LGGlassMaterialProminent
};

NS_ASSUME_NONNULL_BEGIN

@interface LGGlassStyle : NSObject

@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign) CGFloat shadowRadius;
@property (nonatomic, assign) CGFloat shadowOpacity;
@property (nonatomic, assign) CGFloat highlightOpacity;
@property (nonatomic, assign) LGGlassMaterial material;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, strong) UIColor *contentColor;

+ (instancetype)clearCapsuleStyle;
+ (instancetype)regularPanelStyle;
+ (instancetype)prominentButtonStyle;

- (UIBlurEffectStyle)blurEffectStyle;

@end

NS_ASSUME_NONNULL_END
