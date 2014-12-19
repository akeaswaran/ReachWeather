//RWActivatorListener.m
#import "RWActivatorListener.h"
#import "RWWeatherController.h"

@implementation RWActivatorListener

+(instancetype)sharedListener {
	static dispatch_once_t pred;
	static RWActivatorListener *shared = nil;
	 
	dispatch_once(&pred, ^{
		shared = [[RWActivatorListener alloc] init];
	});
	return shared;
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	[[RWWeatherController sharedInstance] activateWidgetArea];
	[event setHandled:YES];
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
	return @"ReachWeather";
}
- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
	return @"Open Reachability to display current weather.";
}

- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
	return @[@"application"];
}

- (id)activator:(LAActivator *)activator requiresInfoDictionaryValueOfKey:(NSString *)key forListenerWithName:(NSString *)listenerName {
	return [NSNumber numberWithBool:YES]; // HAX so it can send raw events. <3 rpetrich
}

@end