#import "LGGlassButton.h"

@implementation LGGlassButton

+ (instancetype)circleButtonWithSymbolName:(NSString *)symbolName {
    LGGlassButton *button = [[LGGlassButton alloc] initWithStyle:[LGGlassStyle prominentButtonStyle]];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20.0 weight:UIImageSymbolWeightSemibold];
    button.imageView.image = [UIImage systemImageNamed:symbolName withConfiguration:config];
    button.titleLabel.hidden = YES;
    [NSLayoutConstraint activateConstraints:@[
        [button.widthAnchor constraintEqualToConstant:48.0],
        [button.heightAnchor constraintEqualToConstant:48.0]
    ]];
    return button;
}

+ (instancetype)chipButtonWithTitle:(NSString *)title symbolName:(NSString *)symbolName {
    LGGlassButton *button = [[LGGlassButton alloc] initWithStyle:[LGGlassStyle clearCapsuleStyle]];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.titleLabel.text = title;
    if (symbolName.length > 0) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:14.0 weight:UIImageSymbolWeightSemibold];
        button.imageView.image = [UIImage systemImageNamed:symbolName withConfiguration:config];
        button.imageView.hidden = NO;
    } else {
        button.imageView.hidden = YES;
    }
    return button;
}

- (instancetype)initWithStyle:(LGGlassStyle *)style {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _glassView = [[LGGlassView alloc] initWithStyle:style];
        _glassView.translatesAutoresizingMaskIntoConstraints = NO;
        _glassView.userInteractionEnabled = NO;
        [self addSubview:_glassView];

        _imageView = [UIImageView new];
        _imageView.tintColor = style.contentColor;
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_glassView.contentStack addArrangedSubview:_imageView];

        _titleLabel = [UILabel new];
        _titleLabel.textColor = style.contentColor;
        _titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
        _titleLabel.numberOfLines = 1;
        [_glassView.contentStack addArrangedSubview:_titleLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_glassView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_glassView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_glassView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_glassView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
            [_imageView.widthAnchor constraintLessThanOrEqualToConstant:20.0],
            [_imageView.heightAnchor constraintLessThanOrEqualToConstant:20.0],
            [self.heightAnchor constraintGreaterThanOrEqualToConstant:32.0]
        ]];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self.glassView setPressed:highlighted animated:YES];
}

@end
