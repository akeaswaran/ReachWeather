#import "RWWeatherController.h"
#import "RWActivatorListener.h"
#import <libactivator/libactivator.h>

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

	if ([RWWeatherController isActivatorInstalled]) {
		RWLog(@"ACTIVATOR EXISTS - ENABLING SUPPORT");

		dlopen("/usr/lib/libactivator.dylib", RTLD_LAZY);
		Class la = %c(LAActivator);
		if (la) { //libactivator is installed
			RWLog(@"ACTIVATOR INSTALLED - SUPPORT ENABLED");
			// register our listener. do this after the above so it still hasn't "seen" us if this is first launch
			[[%c(LAActivator) sharedInstance] registerListener:[RWActivatorListener sharedListener] forName:@"me.akeaswaran.reachweather"];
		} else {  //libactivator is not installed
			RWLog(@"ACTIVATOR NOT INSTALLED - SUPPORT DISABLED");
		}
	} else {
		RWLog(@"ACTIVATOR DOES NOT EXIST - DISABLING SUPPORT");
	}
    
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
