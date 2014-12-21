//Headers.h

#define kRWSettingsPath @"/var/mobile/Library/Preferences/me.akeaswaran.reachweather.plist"
#define kRWCityKey @"city"
#define kRWEnabledKey @"tweakEnabled"
#define kRWCelsiusEnabledKey @"celsiusEnabled"
#define kRWDetailedViewKey @"detailedView"
#define kRWLanguageKey @"language"
#define kRWManualControlKey @"manualControl"
#define kRWClockViewKey @"clockView"
#define kRWForecastViewKey @"forecastEnabled"
#define kRWForecastTypeKey @"forecastType"
#define kRWTitleColorSwitchKey @"customTitleColorEnabled"
#define kRWTitleColorKey @"customTitleColor"
#define kRWDetailColorSwitchKey @"customDetailColorEnabled"
#define kRWDetailColorKey @"customDetailColor"

#define kRWCushionBorder 15.0

#ifdef DEBUG
    #define RWLog(fmt, ...) NSLog((@"[ReachWeather] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define RWLog(fmt, ...)
#endif

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
- (void)_handleReachabilityDeactivated;
- (void)_handleReachabilityActivated;
- (void)_setKeepAliveTimerForDuration:(CGFloat)arg1;
- (void)disableExpirationTimerForInteraction;
@property(readonly, nonatomic) BOOL reachabilityModeActive;
@end
