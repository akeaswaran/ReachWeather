//RWWeatherController.m
#import "RWWeatherController.h"
#import "External/AFNetworking/AFNetworking.h"
#import "External/AFNetworking/AFHTTPRequestOperationManager.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#define kRWSettingsPath @"/var/mobile/Library/Preferences/me.akeaswaran.reachweather.plist"
#define kRWCityKey @"city"
#define kRWEnabledKey @"tweakEnabled"
#define kRWCelsiusEnabledKey @"celsiusEnabled"

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

-(NSDateFormatter*)_dateFormatter {
	static dispatch_once_t pred;
	static NSDateFormatter *shared = nil;
	 
	dispatch_once(&pred, ^{
		shared = [[NSDateFormatter alloc] init];
		[shared setDateFormat:@"MMMM dd, yyyy hh:mm a"];
	});
	return shared;
}

-(void)setBackgroundWindow:(SBWindow*)window {
	backgroundWindow = window;
	RWLog(@"BACKGROUND WINDOW FRAME: %f, %f, %f, %f \n\n BACKGROUND WINDOW BOUNDS: %f, %f, %f, %f",backgroundWindow.bounds.origin.x,backgroundWindow.bounds.origin.y,backgroundWindow.bounds.size.width,backgroundWindow.bounds.size.height,[backgroundWindow frame].origin.x,[backgroundWindow frame].origin.y,[backgroundWindow frame].size.width,[backgroundWindow frame].size.height);
}

-(void)setupWidget {
	if ([self _formattedWidget] && backgroundWindow) {
		[backgroundWindow addSubview:[self _formattedWidget]];
	}
}

-(void)deconstructWidget {
	if ([self _formattedWidget]) {
		[[self _formattedWidget] removeFromSuperview];

		_temperatureLabel = nil;
		_cityLabel = nil;
		_weatherDescriptionLabel = nil;
		backgroundWindow = nil;
	}
}

-(UIView*)_formattedWidget { 
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];

	NSNumber *enabledNum = settings[kRWEnabledKey];
	BOOL tweakEnabled = enabledNum ? [enabledNum boolValue] : 1;

	NSNumber *celsiusNum = settings[kRWCelsiusEnabledKey];
	BOOL celsiusEnabled = celsiusNum ? [celsiusNum boolValue] : 1;

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
			settingsCity = @"London";
		} else {
			settingsCity = settings[kRWCityKey];
		}

		[_cityLabel setText:settingsCity];
		[_cityLabel sizeToFit];

		if (!celsiusEnabled) {
			[_temperatureLabel setText:@"69\u00B0F"];
		} else {
			[_temperatureLabel setText:@"21\u00B0C"];
		}
		[_temperatureLabel sizeToFit];
		[_weatherDescriptionLabel setText:@"Sunny"];
		[_weatherDescriptionLabel sizeToFit];

		/*
		[self fetchCurrentWeatherForCity:[settingsCity stringByReplacingOccurrencesOfString:@" " withString:@"+"] completion:^(NSDictionary *result, NSError *error) {
			if (!error) {
			    // main
			    NSInteger tempCurrent = [self kelvinToLocalTemp:[result[@"main"][@"temp"] doubleValue]];
			    [_temperatureLabel setText:[NSString stringWithFormat:@"%i\u00B0F",tempCurrent]];
			    [_temperatureLabel sizeToFit];
			 
			    // weather
			    NSArray *conditions = result[@"weather"];
				[_weatherDescriptionLabel setText:conditions[0][@"description"]];
				[_weatherDescriptionLabel sizeToFit];
				
			} else {
				if (!celsiusEnabled) {
					[_temperatureLabel setText:@"69\u00B0F"];
				} else {
					[_temperatureLabel setText:@"21\u00B0C"];
				}
				[_temperatureLabel sizeToFit];
				[_weatherDescriptionLabel setText:@"There was a problem processing your request."];
				[_weatherDescriptionLabel sizeToFit];
			}
		}];
		*/

		/*
		[_temperatureLabel.layer setBorderColor:[UIColor greenColor].CGColor];
		[_cityLabel.layer setBorderColor:[UIColor redColor].CGColor];
		[_weatherDescriptionLabel.layer setBorderColor:[UIColor whiteColor].CGColor];

		[_temperatureLabel.layer setBorderWidth:1.0];
		[_cityLabel.layer setBorderWidth:1.0];
		[_weatherDescriptionLabel.layer setBorderWidth:1.0];
		*/

		[weatherView addSubview:_temperatureLabel];
		[weatherView addSubview:_cityLabel];
		[weatherView addSubview:_weatherDescriptionLabel];

		return weatherView;
	} else {
		return nil;
	}
}

-(void)fetchCurrentWeatherForCity:(NSString*)city completion:(RWWeatherCompletionBlock)completionBlock {
	NSString *const BASE_URL_STRING = @"http://api.openweathermap.org/data/2.5/weather";
 
    NSString *weatherURLText = [NSString stringWithFormat:@"%@?q=%@&lang=en",
                                BASE_URL_STRING, city];
    NSURL *weatherURL = [NSURL URLWithString:weatherURLText];
    NSURLRequest *weatherRequest = [NSURLRequest requestWithURL:weatherURL];
 
    AFHTTPRequestOperation *operation =
    [[objc_getClass("AFHTTPRequestOperationManager") manager] HTTPRequestOperationWithRequest:weatherRequest success:^(AFHTTPRequestOperation *operation, id responseObject) {
    		RWLog(@"REQUEST SUCCESSFUL; ENTERING REAL DATA");
	        NSDictionary *weatherServiceResponse = (NSDictionary *)responseObject;
	        RWLog(@"RESPONSE OBJECT: %@",weatherServiceResponse);
	        completionBlock(weatherServiceResponse,nil);
	    }
	    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
	    	RWLog(@"REQUEST FAILED; ENTERING FAKE DATA");
	        completionBlock(@{},error);
	    }
     ];
 
    [operation start];
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