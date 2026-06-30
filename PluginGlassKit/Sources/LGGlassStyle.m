#import "LGGlassStyle.h"

@implementation LGGlassStyle

+ (instancetype)clearCapsuleStyle {
    LGGlassStyle *style = [LGGlassStyle new];
    style.cornerRadius = 22.0;
    style.borderWidth = 0.8;
    style.shadowRadius = 12.0;
    style.shadowOpacity = 0.20;
    style.highlightOpacity = 0.18;
    style.material = LGGlassMaterialClear;
    style.tintColor = [UIColor colorWithWhite:1.0 alpha:0.10];
    style.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.24];
    style.contentColor = [UIColor colorWithWhite:1.0 alpha:0.90];
    return style;
}

+ (instancetype)regularPanelStyle {
    LGGlassStyle *style = [LGGlassStyle clearCapsuleStyle];
    style.cornerRadius = 18.0;
    style.shadowRadius = 18.0;
    style.shadowOpacity = 0.26;
    style.highlightOpacity = 0.24;
    style.material = LGGlassMaterialRegular;
    style.tintColor = [UIColor colorWithWhite:0.05 alpha:0.34];
    style.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.28];
    return style;
}

+ (instancetype)prominentButtonStyle {
    LGGlassStyle *style = [LGGlassStyle clearCapsuleStyle];
    style.cornerRadius = 24.0;
    style.shadowRadius = 14.0;
    style.shadowOpacity = 0.24;
    style.material = LGGlassMaterialProminent;
    style.tintColor = [UIColor colorWithRed:0.03 green:0.12 blue:0.18 alpha:0.52];
    style.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.30];
    return style;
}

- (UIBlurEffectStyle)blurEffectStyle {
    switch (self.material) {
        case LGGlassMaterialProminent:
            return UIBlurEffectStyleSystemUltraThinMaterialDark;
        case LGGlassMaterialRegular:
            return UIBlurEffectStyleSystemThinMaterialDark;
        case LGGlassMaterialClear:
        default:
            return UIBlurEffectStyleSystemChromeMaterialDark;
    }
}

@end
