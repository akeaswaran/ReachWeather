//RWWeatherController.m
#import "RWWeatherController.h"
#import "External/AFNetworking/AFNetworking.h"
#import "External/AFNetworking/AFHTTPRequestOperationManager.h"
#import <objc/runtime.h>

#define kRWSettingsPath @"/var/mobile/Library/Preferences/me.akeaswaran.reachweather.plist"
#define kRWCityKey @"city"
#define kRWEnabledKey @"tweakEnabled"

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
}

-(void)setupWidget {
	if ([self _formattedWidget] && backgroundWindow) {
		[backgroundWindow addSubview:[self _formattedWidget]];
	}
}

-(void)deconstructWidget {
	if ([self _formattedWidget]) {
		[[self _formattedWidget] removeFromSuperview];
		_weatherImageView = nil;
		_dateTimeLabel = nil;
		_temperatureLabel = nil;
		_cityLabel = nil;
		_weatherDescriptionLabel = nil;
	}
}

-(UIView*)_formattedWidget { 
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSNumber *enabledNum = settings[kRWEnabledKey];
	BOOL tweakEnabled = enabledNum ? [enabledNum boolValue] : 1;

	if (tweakEnabled) {
		UIView *weatherView = [[UIView alloc] initWithFrame:backgroundWindow.bounds];
		//_weatherImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,0,0)];
		//_dateTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,0,0)];
		//_temperatureLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,0,0)];
		_cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(15,15,[backgroundWindow frame].size.width - 15,[backgroundWindow frame].size.height - 15)];
		//_weatherDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,0,0)];

		NSString *settingsCity;
		if (!settings[kRWCityKey]) {
			settingsCity = @"London";
		} else {
			settingsCity = settings[kRWCityKey];
		}

		[_cityLabel setText:[NSString stringWithFormat:@"%@", settingsCity]];
		[_cityLabel sizeToFit];

		/*[self fetchCurrentWeatherForCity:[settingsCity stringByReplacingOccurrencesOfString:@" " withString:@"+"] completion:^(NSDictionary *result, NSError *error) {
			if (!error) {
				
				//NSInteger cloudCover = [result[@"clouds"][@"all"] integerValue];
				//weatherImageView

			    // dt
			    NSDate *reportTime = [NSDate dateWithTimeIntervalSince1970:[result[@"dt"] doubleValue]];
			    [_dateTimeLabel setText:[[self _dateFormatter] stringFromDate:reportTime]];
			 
			    // main
			    CGFloat tempCurrent = [self kelvinToLocalTemp:[result[@"main"][@"temp"] doubleValue]];
			    [_temperatureLabel setText:[NSString stringWithFormat:@"%f F",tempCurrent]];
			 
			    // name
			    NSString *city = result[@"name"];
			 	NSString *country = result[@"sys"][@"country"];
			 	[_cityLabel setText:[NSString stringWithFormat:@"%@, %@", city, country]];
			 	[_cityLabel sizeToFit];
			 
			    // weather
			    //NSArray *conditions = result[@"weather"];
				//[_weatherDescriptionLabel setText:conditions[0][@"description"]];
				
			}
		}];*/

		//[weatherView addSubview:_weatherImageView];
		//[weatherView addSubview:_dateTimeLabel];
		//[weatherView addSubview:_temperatureLabel];
		[weatherView addSubview:_cityLabel];
		//[weatherView addSubview:_weatherDescriptionLabel];

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
	        NSDictionary *weatherServiceResponse = (NSDictionary *)responseObject;
	        completionBlock(weatherServiceResponse,nil);
	    }
	    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
	        completionBlock(@{},error);
	    }
     ];
 
    [operation start];
}

- (double)kelvinToLocalTemp:(double)degreesKelvin
{
    return ((degreesKelvin*(9.0/5.0)) - 459.67);
}

@end