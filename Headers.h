//Headers.h

@protocol SBWindowLayoutStrategy <NSObject>
- (int)jailBehavior;
- (struct CGRect)frameForWindow:(UIWindow *)arg1;
@end

@interface SBWindow
@property(readonly, retain, nonatomic) id <SBWindowLayoutStrategy> layoutStrategy;
+ (struct UIEdgeInsets)_jailInsetsForScreen:(id)arg1;
- (void)addSubview:(UIView*)subview;
@end

@interface SBWorkspace
{
	SBWindow* _reachabilityEffectWindow;
}
- (void)handleReachabilityModeDeactivated;
- (void)handleReachabilityModeActivated;
- (id)init;
@end

@interface SBReachabilityManager
+ (id)sharedInstance;
+ (BOOL)reachabilitySupported;
- (void)_handleReachabilityDeactivated;
- (void)_handleReachabilityActivated;
@end