#import "LGGlassFloatingBar.h"

@interface LGGlassFloatingBar ()
@property (nonatomic, strong, readwrite) UIStackView *quickActionsStack;
@property (nonatomic, strong, readwrite) UIStackView *composerStack;
@property (nonatomic, strong, readwrite) UITextField *textField;
@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property (nonatomic, weak) UIView *hostView;
@end

@implementation LGGlassFloatingBar

- (instancetype)initWithQuickActions:(NSArray<LGGlassButton *> *)quickActions {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = UIColor.clearColor;

        _quickActionsStack = [[UIStackView alloc] initWithFrame:CGRectZero];
        _quickActionsStack.translatesAutoresizingMaskIntoConstraints = NO;
        _quickActionsStack.axis = UILayoutConstraintAxisHorizontal;
        _quickActionsStack.alignment = UIStackViewAlignmentCenter;
        _quickActionsStack.distribution = UIStackViewDistributionEqualSpacing;
        _quickActionsStack.spacing = 10.0;

        for (LGGlassButton *button in quickActions) {
            [_quickActionsStack addArrangedSubview:button];
        }

        LGGlassButton *plus = [LGGlassButton circleButtonWithSymbolName:@"plus"];
        LGGlassButton *voice = [LGGlassButton circleButtonWithSymbolName:@"speaker.wave.2.fill"];

        LGGlassView *inputShell = [[LGGlassView alloc] initWithStyle:[LGGlassStyle clearCapsuleStyle]];
        inputShell.translatesAutoresizingMaskIntoConstraints = NO;

        _textField = [UITextField new];
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
        _textField.placeholder = @"输入消息";
        _textField.textColor = [UIColor colorWithWhite:1.0 alpha:0.90];
        _textField.tintColor = UIColor.whiteColor;
        _textField.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightSemibold];
        _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"输入消息" attributes:@{ NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.46] }];
        [inputShell.contentStack addArrangedSubview:_textField];

        UIImageView *smile = [UIImageView new];
        UIImageSymbolConfiguration *smileConfig = [UIImageSymbolConfiguration configurationWithPointSize:23.0 weight:UIImageSymbolWeightMedium];
        smile.image = [UIImage systemImageNamed:@"face.smiling" withConfiguration:smileConfig];
        smile.tintColor = [UIColor colorWithWhite:1.0 alpha:0.88];
        [inputShell.contentStack addArrangedSubview:smile];

        _composerStack = [[UIStackView alloc] initWithFrame:CGRectZero];
        _composerStack.translatesAutoresizingMaskIntoConstraints = NO;
        _composerStack.axis = UILayoutConstraintAxisHorizontal;
        _composerStack.alignment = UIStackViewAlignmentCenter;
        _composerStack.spacing = 9.0;
        [_composerStack addArrangedSubview:plus];
        [_composerStack addArrangedSubview:inputShell];
        [_composerStack addArrangedSubview:voice];

        UIStackView *root = [[UIStackView alloc] initWithArrangedSubviews:@[_quickActionsStack, _composerStack]];
        root.translatesAutoresizingMaskIntoConstraints = NO;
        root.axis = UILayoutConstraintAxisVertical;
        root.spacing = 7.0;
        root.alignment = UIStackViewAlignmentFill;
        [self addSubview:root];

        [NSLayoutConstraint activateConstraints:@[
            [root.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:17.0],
            [root.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-17.0],
            [root.topAnchor constraintEqualToAnchor:self.topAnchor constant:8.0],
            [root.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-12.0],
            [inputShell.heightAnchor constraintEqualToConstant:48.0]
        ]];
    }
    return self;
}

- (void)attachToView:(UIView *)view keyboardAware:(BOOL)keyboardAware {
    if (!view) return;
    self.hostView = view;
    [view addSubview:self];
    UILayoutGuide *guide = view.safeAreaLayoutGuide;
    self.bottomConstraint = [self.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-4.0];
    [NSLayoutConstraint activateConstraints:@[
        [self.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [self.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        self.bottomConstraint
    ]];

    if (keyboardAware) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleKeyboardFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleKeyboardFrame:) name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)dismiss {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self removeFromSuperview];
}

- (void)handleKeyboardFrame:(NSNotification *)notification {
    UIView *hostView = self.hostView;
    if (!hostView || !self.bottomConstraint) return;

    NSDictionary *userInfo = notification.userInfo;
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect endInHost = [hostView convertRect:endFrame fromView:nil];
    CGFloat overlap = MAX(0.0, CGRectGetMaxY(hostView.bounds) - CGRectGetMinY(endInHost) - hostView.safeAreaInsets.bottom);

    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions options = ([userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);
    self.bottomConstraint.constant = -4.0 - overlap;
    [UIView animateWithDuration:duration delay:0.0 options:options animations:^{
        [hostView layoutIfNeeded];
    } completion:nil];
}

@end
