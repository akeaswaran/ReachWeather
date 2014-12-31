//Headers.h

#define kRWSettingsPath @"/var/mobile/Library/Preferences/me.akeaswaran.reachweather.plist"
#define kRWBundlePath @"/Library/MobileSubstrate/DynamicLibraries/RWResourcesBundle.bundle"
#define kRWWeatherFrameworkPath @"/System/Library/PrivateFrameworks/Weather.framework"
#define kRWCityKey @"city"
#define kRWEnabledKey @"tweakEnabled"
#define kRWCelsiusEnabledKey @"celsiusEnabled"
#define kRWDetailedViewKey @"detailedView"
#define kRWWeatherImagesKey @"weatherImages"
#define kRWLanguageKey @"language"
#define kRWManualControlKey @"manualControl"
#define kRWCenterMainViewKey @"centerMainView"
#define kRWClockViewKey @"clockView"
#define kRWForecastViewKey @"forecastEnabled"
#define kRWForecastTypeKey @"forecastType"
#define kRWTitleColorSwitchKey @"customTitleColorEnabled"
#define kRWTitleColorKey @"customTitleColor"
#define kRWDetailColorSwitchKey @"customDetailColorEnabled"
#define kRWDetailColorKey @"customDetailColor"

#define IS_OS_8_OR_LATER    ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 (IS_IPHONE && ([[UIScreen mainScreen] bounds].size.height == 568.0) && ((IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale == [UIScreen mainScreen].scale) || !IS_OS_8_OR_LATER))
#define IS_STANDARD_IPHONE_6 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 667.0  && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale == [UIScreen mainScreen].scale)
#define IS_ZOOMED_IPHONE_6 (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 568.0 && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale > [UIScreen mainScreen].scale)
#define IS_STANDARD_IPHONE_6_PLUS (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 736.0)
#define IS_ZOOMED_IPHONE_6_PLUS (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 667.0 && IS_OS_8_OR_LATER && [UIScreen mainScreen].nativeScale < [UIScreen mainScreen].scale)

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
