#import "LGGlassView.h"

@interface LGGlassView ()
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *tintView;
@property (nonatomic, strong) UIView *highlightView;
@property (nonatomic, strong) CAShapeLayer *borderLayer;
@property (nonatomic, strong, readwrite) UIStackView *contentStack;
@end

@implementation LGGlassView

- (instancetype)initWithStyle:(LGGlassStyle *)style {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _style = style ?: [LGGlassStyle clearCapsuleStyle];
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _style = [LGGlassStyle clearCapsuleStyle];
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.clipsToBounds = NO;
    self.backgroundColor = UIColor.clearColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 8.0);

    _blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:self.style.blurEffectStyle]];
    _blurView.translatesAutoresizingMaskIntoConstraints = NO;
    _blurView.userInteractionEnabled = NO;
    [self addSubview:_blurView];

    _tintView = [UIView new];
    _tintView.translatesAutoresizingMaskIntoConstraints = NO;
    _tintView.userInteractionEnabled = NO;
    [_blurView.contentView addSubview:_tintView];

    _highlightView = [UIView new];
    _highlightView.translatesAutoresizingMaskIntoConstraints = NO;
    _highlightView.userInteractionEnabled = NO;
    _highlightView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:self.style.highlightOpacity];
    [_blurView.contentView addSubview:_highlightView];

    _contentStack = [[UIStackView alloc] initWithFrame:CGRectZero];
    _contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    _contentStack.axis = UILayoutConstraintAxisHorizontal;
    _contentStack.alignment = UIStackViewAlignmentCenter;
    _contentStack.spacing = 8.0;
    [self addSubview:_contentStack];

    _borderLayer = [CAShapeLayer layer];
    _borderLayer.fillColor = UIColor.clearColor.CGColor;
    [self.layer addSublayer:_borderLayer];

    [NSLayoutConstraint activateConstraints:@[
        [_blurView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_blurView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_blurView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_blurView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        [_tintView.leadingAnchor constraintEqualToAnchor:_blurView.contentView.leadingAnchor],
        [_tintView.trailingAnchor constraintEqualToAnchor:_blurView.contentView.trailingAnchor],
        [_tintView.topAnchor constraintEqualToAnchor:_blurView.contentView.topAnchor],
        [_tintView.bottomAnchor constraintEqualToAnchor:_blurView.contentView.bottomAnchor],

        [_highlightView.leadingAnchor constraintEqualToAnchor:_blurView.contentView.leadingAnchor],
        [_highlightView.trailingAnchor constraintEqualToAnchor:_blurView.contentView.trailingAnchor],
        [_highlightView.topAnchor constraintEqualToAnchor:_blurView.contentView.topAnchor],
        [_highlightView.heightAnchor constraintEqualToAnchor:_blurView.contentView.heightAnchor multiplier:0.44],

        [_contentStack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:12.0],
        [_contentStack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-12.0],
        [_contentStack.topAnchor constraintEqualToAnchor:self.topAnchor constant:8.0],
        [_contentStack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8.0]
    ]];

    [self applyStyle];
}

- (void)setStyle:(LGGlassStyle *)style {
    _style = style ?: [LGGlassStyle clearCapsuleStyle];
    [self applyStyle];
}

- (void)applyStyle {
    self.layer.shadowColor = UIColor.blackColor.CGColor;
    self.layer.shadowRadius = self.style.shadowRadius;
    self.layer.shadowOpacity = self.style.shadowOpacity;
    self.blurView.effect = [UIBlurEffect effectWithStyle:self.style.blurEffectStyle];
    self.tintView.backgroundColor = self.style.tintColor;
    self.highlightView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:self.style.highlightOpacity];
    self.borderLayer.strokeColor = self.style.strokeColor.CGColor;
    self.borderLayer.lineWidth = self.style.borderWidth;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat radius = MIN(self.style.cornerRadius, MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) / 2.0);
    self.blurView.layer.cornerRadius = radius;
    self.blurView.layer.cornerCurve = kCACornerCurveContinuous;
    self.blurView.clipsToBounds = YES;
    self.tintView.layer.cornerRadius = radius;
    self.tintView.layer.cornerCurve = kCACornerCurveContinuous;
    self.highlightView.layer.cornerRadius = radius;
    self.highlightView.layer.cornerCurve = kCACornerCurveContinuous;
    self.borderLayer.frame = self.bounds;
    self.borderLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:radius].CGPath;
}

- (void)setPressed:(BOOL)pressed animated:(BOOL)animated {
    CGAffineTransform target = pressed ? CGAffineTransformMakeScale(0.975, 0.975) : CGAffineTransformIdentity;
    NSTimeInterval duration = animated ? 0.16 : 0.0;
    [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = target;
        self.layer.shadowOpacity = pressed ? self.style.shadowOpacity * 0.55 : self.style.shadowOpacity;
    } completion:nil];
}

@end
