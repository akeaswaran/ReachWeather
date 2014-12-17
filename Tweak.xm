#import "RWWeatherController.h"
#define kRWSettingsPath @"/var/mobile/Library/Preferences/me.akeaswaran.reachweather.plist"
#define kRWEnabledKey @"tweakEnabled"

#ifdef DEBUG
    #define RWLog(fmt, ...) NSLog((@"[ReachWeather] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define RWLog(fmt, ...)
#endif

static BOOL enabled;

static void ReloadSettings() {
	NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];

	NSNumber *enabledNum = preferences[kRWEnabledKey];
	enabled = enabledNum ? [enabledNum boolValue] : 0;

	RWLog(@"RELOADSETTINGS: %@",preferences);
}

static void ReloadSettingsOnStartup() {
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];

	NSNumber *enabledNum = preferences[kRWEnabledKey];
	enabled = enabledNum ? [enabledNum boolValue] : 0;

	RWLog(@"RELOADSETTINGSONSTARTUP: %@",preferences);
}

%ctor {
	
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)ReloadSettings, CFSTR("me.akeaswaran.reachweather/ReloadSettings"), NULL, CFNotificationSuspensionBehaviorCoalesce);

	ReloadSettingsOnStartup();
    
}

%hook SBWorkspace

-(void)handleReachabilityModeActivated {
	%orig;
	if (enabled && [%c(SBReachabilityManager) reachabilitySupported]) {
		RWLog(@"SETTING REACHABILITY WINDOW");
		SBWindow *backgroundView = MSHookIvar<SBWindow*>(self,"_reachabilityEffectWindow");
		[[RWWeatherController sharedInstance] setBackgroundWindow:backgroundView];
		RWLog(@"REACHABILITY WINDOW SET");

		RWLog(@"CREATING REACHWEATHER VIEW AND ADDING TO REACHABILITY WINDOW");
		[[RWWeatherController sharedInstance] setupWidget];
		RWLog(@"FINISHED CREATING REACHWEATHER VIEW AND ADDED TO REACHABILITY WINDOW");
	}
	
}

-(void)handleReachabilityModeDeactivated {
	%orig;
	if (enabled && [%c(SBReachabilityManager) reachabilitySupported]) {
		RWLog(@"DECONSTRUCTING REACHWEATHER VIEW AND REMOVING FROM REACHABILITY WINDOW");
		[[RWWeatherController sharedInstance] deconstructWidget];
		RWLog(@"DECONSTRUCTED REACHWEATHER VIEW AND REMOVED FROM REACHABILITY WINDOW");
	}
}

%end
