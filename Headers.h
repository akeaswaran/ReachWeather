//Headers.h

//SpringBoard
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
@end

@interface SBReachabilityManager
+ (id)sharedInstance;
+ (BOOL)reachabilitySupported;
- (void)_setKeepAliveTimerForDuration:(CGFloat)arg1;
- (void)disableExpirationTimerForInteraction;
@end
