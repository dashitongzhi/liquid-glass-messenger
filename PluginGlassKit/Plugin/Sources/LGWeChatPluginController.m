#import "LGWeChatPluginController.h"
#import "../../Sources/LGGlassFloatingBar.h"

static NSInteger const LGWeChatPluginBarTag = 26063002;
static NSString *const LGWeChatQuickReplyText = @"我稍后回复你。";

@interface LGWeChatPluginController () <UITextFieldDelegate>
@end

@implementation LGWeChatPluginController

+ (instancetype)sharedController {
    static LGWeChatPluginController *controller;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [LGWeChatPluginController new];
    });
    return controller;
}

- (void)installIfEligibleInViewController:(UIViewController *)viewController {
    if (![self shouldAttachToViewController:viewController]) return;

    UIView *hostView = viewController.view;
    if (!hostView || [hostView viewWithTag:LGWeChatPluginBarTag]) return;

    LGGlassButton *reply = [LGGlassButton chipButtonWithTitle:@"快捷回复" symbolName:nil];
    reply.accessibilityLabel = @"Quick Reply";
    [reply addTarget:self action:@selector(handleQuickReply:) forControlEvents:UIControlEventTouchUpInside];

    LGGlassButton *glass = [LGGlassButton chipButtonWithTitle:@"液态 Glass" symbolName:nil];
    glass.accessibilityLabel = @"Liquid Glass Status";
    [glass addTarget:self action:@selector(handleGlassStatus:) forControlEvents:UIControlEventTouchUpInside];

    LGGlassButton *camera = [LGGlassButton chipButtonWithTitle:@"拍摄" symbolName:@"camera.fill"];
    camera.accessibilityLabel = @"Camera Action";
    [camera addTarget:self action:@selector(handleCamera:) forControlEvents:UIControlEventTouchUpInside];

    LGGlassButton *file = [LGGlassButton chipButtonWithTitle:@"文件" symbolName:@"folder.fill"];
    file.accessibilityLabel = @"File Action";
    [file addTarget:self action:@selector(handleFile:) forControlEvents:UIControlEventTouchUpInside];

    LGGlassFloatingBar *bar = [[LGGlassFloatingBar alloc] initWithQuickActions:@[reply, glass, camera, file]];
    bar.tag = LGWeChatPluginBarTag;
    bar.textField.delegate = self;
    [bar attachToView:hostView keyboardAware:YES];
}

- (void)detachFromViewController:(UIViewController *)viewController {
    UIView *bar = [viewController.view viewWithTag:LGWeChatPluginBarTag];
    if ([bar respondsToSelector:@selector(dismiss)]) {
        [(LGGlassFloatingBar *)bar dismiss];
    } else {
        [bar removeFromSuperview];
    }
}

- (BOOL)shouldAttachToViewController:(UIViewController *)viewController {
    if (!viewController.view.window && !viewController.isViewLoaded) return NO;
    if ([viewController isKindOfClass:UIAlertController.class]) return NO;

    NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
    if (![bundleID isEqualToString:@"com.tencent.xin"]) return NO;

    NSString *className = NSStringFromClass(viewController.class).lowercaseString;
    NSArray<NSString *> *chatHints = @[@"chat", @"message", @"msg", @"conversation", @"session"];
    for (NSString *hint in chatHints) {
        if ([className containsString:hint]) return YES;
    }

    BOOL hasTimeline = [self view:viewController.view containsSubviewOfClass:UIScrollView.class];
    BOOL hasEditableInput = [self viewContainsEditableInput:viewController.view excludingView:nil];
    return hasTimeline && hasEditableInput;
}

- (void)handleQuickReply:(LGGlassButton *)sender {
    UIView *bar = [self enclosingBarForControl:sender];
    LGGlassFloatingBar *floatingBar = [bar isKindOfClass:LGGlassFloatingBar.class] ? (LGGlassFloatingBar *)bar : nil;

    if ([self insertText:LGWeChatQuickReplyText intoFirstResponderInView:bar.superview excludingView:bar]) {
        [self presentStatusWithTitle:@"已填入快捷回复" message:@"文字已放入当前输入框。" fromControl:sender];
        return;
    }

    floatingBar.textField.text = LGWeChatQuickReplyText;
    UIPasteboard.generalPasteboard.string = LGWeChatQuickReplyText;
    [self presentStatusWithTitle:@"已准备快捷回复" message:@"文字已放入插件输入框并复制到剪贴板。" fromControl:sender];
}

- (void)handleGlassStatus:(LGGlassButton *)sender {
    [self presentStatusWithTitle:@"Liquid Glass 插件" message:@"当前插件只负责安全的界面层和输入辅助；业务逻辑可在 LGWeChatPluginController 里继续接入。" fromControl:sender];
}

- (void)handleCamera:(LGGlassButton *)sender {
    [self presentStatusWithTitle:@"拍摄入口" message:@"这里预留给你自己的拍摄或素材面板，不调用微信私有接口。" fromControl:sender];
}

- (void)handleFile:(LGGlassButton *)sender {
    [self presentStatusWithTitle:@"文件入口" message:@"这里预留给你自己的文件选择或附件面板，不调用微信私有接口。" fromControl:sender];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *text = textField.text ?: @"";
    if (text.length == 0) return YES;

    UIView *bar = [self enclosingBarForControl:textField];
    if (![self insertText:text intoFirstResponderInView:bar.superview excludingView:bar]) {
        UIPasteboard.generalPasteboard.string = text;
        [self presentStatusWithTitle:@"已复制" message:@"没有找到微信输入框，文字已复制到剪贴板。" fromControl:textField];
    }
    textField.text = @"";
    return NO;
}

- (UIView *)enclosingBarForControl:(UIView *)control {
    UIView *view = control;
    while (view && view.tag != LGWeChatPluginBarTag) {
        view = view.superview;
    }
    return view;
}

- (BOOL)insertText:(NSString *)text intoFirstResponderInView:(UIView *)view excludingView:(UIView *)excludedView {
    if (!view || view == excludedView) return NO;

    if (view.isFirstResponder && [view conformsToProtocol:@protocol(UITextInput)] && [view respondsToSelector:@selector(insertText:)]) {
        [(id<UITextInput>)view insertText:text];
        return YES;
    }

    for (UIView *subview in view.subviews) {
        if ([self insertText:text intoFirstResponderInView:subview excludingView:excludedView]) return YES;
    }
    return NO;
}

- (BOOL)viewContainsEditableInput:(UIView *)view excludingView:(UIView *)excludedView {
    if (!view || view == excludedView) return NO;
    if ([view isKindOfClass:UITextField.class] || [view isKindOfClass:UITextView.class]) return YES;

    for (UIView *subview in view.subviews) {
        if ([self viewContainsEditableInput:subview excludingView:excludedView]) return YES;
    }
    return NO;
}

- (BOOL)view:(UIView *)view containsSubviewOfClass:(Class)targetClass {
    if (!view) return NO;
    if ([view isKindOfClass:targetClass]) return YES;

    for (UIView *subview in view.subviews) {
        if ([self view:subview containsSubviewOfClass:targetClass]) return YES;
    }
    return NO;
}

- (void)presentStatusWithTitle:(NSString *)title message:(NSString *)message fromControl:(UIView *)control {
    UIViewController *presenter = [self topViewControllerFromRoot:control.window.rootViewController];
    if (!presenter || presenter.presentedViewController) return;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

- (UIViewController *)topViewControllerFromRoot:(UIViewController *)root {
    UIViewController *candidate = root;
    while (candidate.presentedViewController) {
        candidate = candidate.presentedViewController;
    }
    if ([candidate isKindOfClass:UINavigationController.class]) {
        return [self topViewControllerFromRoot:((UINavigationController *)candidate).visibleViewController];
    }
    if ([candidate isKindOfClass:UITabBarController.class]) {
        return [self topViewControllerFromRoot:((UITabBarController *)candidate).selectedViewController];
    }
    return candidate;
}

@end
