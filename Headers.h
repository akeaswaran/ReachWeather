//Headers.h

@interface SBWindow
@property(readonly) CGRect bounds;
- (CGRect)frame;
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