//RWWeatherController.m
#import "RWWeatherController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#define kRWSettingsPath @"/var/mobile/Library/Preferences/me.akeaswaran.reachweather.plist"
#define kRWCityKey @"city"
#define kRWEnabledKey @"tweakEnabled"
#define kRWCelsiusEnabledKey @"celsiusEnabled"
#define kRWLanguageKey @"language"

#define kRWCushionBorder 15.0

#ifdef DEBUG
    #define RWLog(fmt, ...) NSLog((@"[ReachWeather] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define RWLog(fmt, ...)
#endif

@implementation RWWeatherController

+(instancetype)sharedInstance {
	static dispatch_once_t pred;
	static RWWeatherController *shared = nil;
	 
	dispatch_once(&pred, ^{
		shared = [[RWWeatherController alloc] init];
	});
	return shared;
}

-(void)setBackgroundWindow:(SBWindow*)window {
	backgroundWindow = window;
	RWLog(@"BACKGROUND WINDOW FRAME: %f, %f, %f, %f \n\n BACKGROUND WINDOW BOUNDS: %f, %f, %f, %f",backgroundWindow.bounds.origin.x,backgroundWindow.bounds.origin.y,backgroundWindow.bounds.size.width,backgroundWindow.bounds.size.height,[backgroundWindow frame].origin.x,[backgroundWindow frame].origin.y,[backgroundWindow frame].size.width,[backgroundWindow frame].size.height);
}

-(void)setupWidget {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSNumber *enabledNum = settings[kRWEnabledKey];
	BOOL tweakEnabled = enabledNum ? [enabledNum boolValue] : 1;

	NSNumber *celsiusNum = settings[kRWCelsiusEnabledKey];
	BOOL celsiusEnabled = celsiusNum ? [celsiusNum boolValue] : 1;

	NSString *settingsCity;
	if (!settings[kRWCityKey]) {
		settingsCity = @"London";
	} else {
		settingsCity = settings[kRWCityKey];
	}

	if (tweakEnabled && backgroundWindow) {
		[self _fetchCurrentWeatherForCity:[settingsCity stringByReplacingOccurrencesOfString:@" " withString:@"+"] completion:^(NSDictionary *result, NSError *error) {
			if (!error) {
				NSInteger tempCurrent = [self kelvinToLocalTemp:[result[@"main"][@"temp"] doubleValue]];
				if (celsiusEnabled) {
					temperatureCondition = [NSString stringWithFormat:@"%ld\u00B0C",(long)tempCurrent];
			    } else {
					temperatureCondition = [NSString stringWithFormat:@"%ld\u00B0F",(long)tempCurrent];
			    }

			    NSArray *conditions = result[@"weather"];
				currentWeatherCondition = conditions[0][@"description"];
			} else {
				RWLog(@"ERROR: %@",error.localizedDescription);
				if (celsiusEnabled) {
					temperatureCondition = @"--\u00B0C";
			    } else {
					temperatureCondition = @"--\u00B0F";
			    }
			    currentWeatherCondition = @"Error: unable to retreive current weather conditions.";
			}
			[backgroundWindow addSubview:[self _createdWidgetWithCurrentWeather:currentWeatherCondition temperature:temperatureCondition]];
		}];
	}
}

-(void)deconstructWidget {
	if ([self _createdWidgetWithCurrentWeather:currentWeatherCondition temperature:temperatureCondition]) {
		[[self _createdWidgetWithCurrentWeather:currentWeatherCondition temperature:temperatureCondition] removeFromSuperview];

		_temperatureLabel = nil;
		_cityLabel = nil;
		_weatherDescriptionLabel = nil;
		backgroundWindow = nil;
	}
}

-(UIView*)_createdWidgetWithCurrentWeather:(NSString*)weather temperature:(NSString*)temperature {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];

	NSNumber *enabledNum = settings[kRWEnabledKey];
	BOOL tweakEnabled = enabledNum ? [enabledNum boolValue] : 1;

	if (tweakEnabled) {

		UIView *weatherView = [[UIView alloc] initWithFrame:backgroundWindow.bounds];

		_temperatureLabel = [[UILabel alloc] initWithFrame:CGRectMake(kRWCushionBorder,([backgroundWindow frame].size.height / 2.0)-27.5,100.0,55.0)];
		[_temperatureLabel setTextAlignment:NSTextAlignmentLeft];
		[_temperatureLabel setFont:[UIFont systemFontOfSize:44.0]];
		[_temperatureLabel setTextColor:[UIColor whiteColor]];

		_cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(kRWCushionBorder + _temperatureLabel.frame.size.width + 10.0,_temperatureLabel.frame.origin.y,[backgroundWindow frame].size.width - _temperatureLabel.frame.origin.x - _temperatureLabel.frame.size.width,30.0)];
		[_cityLabel setTextAlignment:NSTextAlignmentLeft];
		[_cityLabel setFont:[UIFont systemFontOfSize:28.0]];
		[_cityLabel setTextColor:[UIColor whiteColor]];

		_weatherDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(_cityLabel.frame.origin.x,_cityLabel.frame.origin.y + _cityLabel.frame.size.height + 4.0,_cityLabel.frame.size.width - _temperatureLabel.frame.origin.x - _temperatureLabel.frame.size.width,20.0)];
		[_weatherDescriptionLabel setTextAlignment:NSTextAlignmentLeft];
		[_weatherDescriptionLabel setNumberOfLines:0];
		[_weatherDescriptionLabel setFont:[UIFont systemFontOfSize:15.0]];
		[_weatherDescriptionLabel setTextColor:[UIColor lightGrayColor]];

		NSString *settingsCity;
		if (!settings[kRWCityKey]) {
			settingsCity = @"New York";
		} else {
			settingsCity = settings[kRWCityKey];
		}

		[_cityLabel setText:settingsCity];
		[_cityLabel sizeToFit];

		[_temperatureLabel setText:temperature];
		[_temperatureLabel sizeToFit];
		[_weatherDescriptionLabel setText:weather];
		[_weatherDescriptionLabel sizeToFit];

		[weatherView addSubview:_temperatureLabel];
		[weatherView addSubview:_cityLabel];
		[weatherView addSubview:_weatherDescriptionLabel];
		return weatherView;
	} else {
		return nil;
	}
}

-(void)_fetchCurrentWeatherForCity:(NSString*)city completion:(RWWeatherCompletionBlock)completionBlock {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSString *settingsLang;
	if (!settings[kRWLanguageKey]) {
		settingsLang = @"en";
	} else {
		settingsLang = settings[kRWLanguageKey];
	}

	NSString *const BASE_URL_STRING = @"http://api.openweathermap.org/data/2.5/weather";
 
    NSString *weatherURLText = [NSString stringWithFormat:@"%@?q=%@&lang=%@",
                                BASE_URL_STRING, city,settingsLang];
    NSURL *weatherURL = [NSURL URLWithString:weatherURLText];
    NSURLRequest *weatherRequest = [NSURLRequest requestWithURL:weatherURL];

    [NSURLConnection sendAsynchronousRequest:weatherRequest 
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (!error && response && data) {
	    	// Now create a NSDictionary from the JSON data
		    NSError *jsonError;
		    id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
		    if (!jsonError && [JSON isKindOfClass:[NSDictionary class]]) {
		    	dispatch_async(dispatch_get_main_queue(), ^(void){
		    		completionBlock((NSDictionary*)JSON,nil);
   				 });
		    	
	    	} else {
	    		dispatch_async(dispatch_get_main_queue(), ^(void){
		    		completionBlock(@{},jsonError);
   				 });
	    	}
	    } else {
	    	dispatch_async(dispatch_get_main_queue(), ^(void){
		    	completionBlock(@{},error);
   			});
	    }
    }];

    
}

- (NSInteger)kelvinToLocalTemp:(CGFloat)degreesKelvin
{
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSNumber *celsiusNum = settings[kRWCelsiusEnabledKey];
	BOOL celsiusEnabled = celsiusNum ? [celsiusNum boolValue] : 1;

	NSNumber *temp;
    if (!celsiusEnabled) {
    	temp = [NSNumber numberWithDouble: ((degreesKelvin*(9.0/5.0)) - 459.67)];
    } else {
    	temp = [NSNumber numberWithDouble: (degreesKelvin - 273.15)];
    }

    return [temp integerValue];
}

@end