//RWWeatherController.m
#import "RWWeatherController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#define kRWSettingsPath @"/var/mobile/Library/Preferences/me.akeaswaran.reachweather.plist"
#define kRWCityKey @"city"
#define kRWEnabledKey @"tweakEnabled"
#define kRWCelsiusEnabledKey @"celsiusEnabled"
#define kRWDetailedViewKey @"detailedView"
#define kRWLanguageKey @"language"
#define kRWManualControlKey @"manualControl"
#define kRWClockViewKey @"clockView"

#define kRWCushionBorder 15.0

#ifdef DEBUG
    #define RWLog(fmt, ...) NSLog((@"[ReachWeather] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
    #define RWLog(fmt, ...)
#endif

@implementation RWWeatherController

//Shared Instance
+(instancetype)sharedInstance {
	static dispatch_once_t pred;
	static RWWeatherController *shared = nil;
	 
	dispatch_once(&pred, ^{
		shared = [[RWWeatherController alloc] init];
	});
	return shared;
}

-(NSDateFormatter*)sharedDateFormatter {
	static dispatch_once_t pred;
	static NSDateFormatter *shared = nil;
	 
	dispatch_once(&pred, ^{
		shared = [[NSDateFormatter alloc] init];
		[shared setDateFormat:@"hh:mm a"];
	});
	return shared;
}

//Widget setup
-(void)setBackgroundWindow:(SBWindow*)window {
	backgroundWindow = window;
	RWLog(@"BACKGROUND WINDOW FRAME: %@ \n\n BACKGROUND WINDOW BOUNDS: %@",NSStringFromCGRect([backgroundWindow frame]),NSStringFromCGRect(backgroundWindow.bounds));
}

-(void)setupWidget {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSNumber *enabledNum = settings[kRWEnabledKey];
	BOOL tweakEnabled = enabledNum ? [enabledNum boolValue] : 0;

	NSNumber *celsiusNum = settings[kRWCelsiusEnabledKey];
	BOOL celsiusEnabled = celsiusNum ? [celsiusNum boolValue] : 0;

	NSNumber *manualControlNum = settings[kRWManualControlKey];
	BOOL mcEnabled = manualControlNum ? [manualControlNum boolValue] : 0;

	NSString *settingsCity;
	if (!settings[kRWCityKey]) {
		settingsCity = @"London";
	} else {
		settingsCity = settings[kRWCityKey];
	}


	if (enabledNum && tweakEnabled && backgroundWindow) {
		[self _fetchCurrentWeatherForCityNamed:[settingsCity stringByReplacingOccurrencesOfString:@" " withString:@"+"] completion:^(NSDictionary *result, NSError *error) {
			if (!error) {
				NSInteger tempCurrent = [self kelvinToLocalTemp:[result[@"main"][@"temp"] doubleValue]];
				if (celsiusEnabled) {
					temperatureCondition = [NSString stringWithFormat:@"%ld\u00B0C",(long)tempCurrent];
			    } else {
					temperatureCondition = [NSString stringWithFormat:@"%ld\u00B0F",(long)tempCurrent];
			    }

			    NSArray *conditions = result[@"weather"];
				currentWeatherCondition = conditions[0][@"description"];

				NSInteger highTemp = [self kelvinToLocalTemp:[result[@"main"][@"temp_max"] doubleValue]];
				NSInteger lowTemp = [self kelvinToLocalTemp:[result[@"main"][@"temp_min"] doubleValue]];

				if (celsiusEnabled) {
					highTempCondition = [NSString stringWithFormat:@"High: %ld\u00B0C",(long)highTemp];
					lowTempCondition = [NSString stringWithFormat:@"Low: %ld\u00B0C",(long)lowTemp];
			    } else {
					highTempCondition = [NSString stringWithFormat:@"High: %ld\u00B0F",(long)highTemp];
					lowTempCondition = [NSString stringWithFormat:@"Low: %ld\u00B0F",(long)lowTemp];
			    }

			   	NSNumber *pressure = [NSNumber numberWithDouble:[result[@"main"][@"pressure"] doubleValue]];
			   	pressureCondition = [NSString stringWithFormat:@"Pressure: %ld mb",(long)[pressure integerValue]];

			   	NSNumber *humidity = [NSNumber numberWithDouble:[result[@"main"][@"humidity"] doubleValue]];
			   	humidityCondition = [NSString stringWithFormat:@"Humidity: %ld%%",(long)[humidity integerValue]];

			} else {
				RWLog(@"ERROR: %@",error.localizedDescription);
				if (celsiusEnabled) {
					temperatureCondition = @"--\u00B0C";
					highTempCondition = @"--\u00B0C";
					lowTempCondition = @"--\u00B0C";
			    } else {
					temperatureCondition = @"--\u00B0F";
					highTempCondition = @"--\u00B0F";
					lowTempCondition = @"--\u00B0F";
			    }
			    currentWeatherCondition = @"Error: unable to retreive current weather conditions.";
				pressureCondition = @"-- mb";
				humidityCondition = @"--%";
			}
			/*
			if (!detailEnabled || !detailNum) {
				[backgroundWindow addSubview:[self _createdWidgetWithCurrentWeather:currentWeatherCondition currentTemperature:temperatureCondition]];
			} else {
				[backgroundWindow addSubview:[self _createdWidgetWithCurrentWeather:currentWeatherCondition currentTemperature:temperatureCondition highTemp:highTempCondition lowTemp:lowTempCondition pressure:pressureCondition humidity:humidityCondition]];
			}*/

			[backgroundWindow addSubview:[self _createdFullFeaturedWidgetWithCurrentWeather:currentWeatherCondition currentTemperature:temperatureCondition highTemp:highTempCondition lowTemp:lowTempCondition pressure:pressureCondition humidity:humidityCondition]];

			if(mcEnabled) {
				RWLog(@"MANUAL CONTROL ACTIVATED");
				[[objc_getClass("SBReachabilityManager") sharedInstance] disableExpirationTimerForInteraction];
			}
		}];
	}
}

-(void)deconstructWidget {
	if ([self _createdWeatherViewWithCurrentWeather:currentWeatherCondition currentTemperature:temperatureCondition]) {
		[[self _createdWeatherViewWithCurrentWeather:currentWeatherCondition currentTemperature:temperatureCondition] removeFromSuperview];
	}

	if ([self _createdFullFeaturedWidgetWithCurrentWeather:currentWeatherCondition currentTemperature:temperatureCondition highTemp:highTempCondition lowTemp:lowTempCondition pressure:pressureCondition humidity:humidityCondition]) {

		[self _createdFullFeaturedWidgetWithCurrentWeather:currentWeatherCondition currentTemperature:temperatureCondition highTemp:highTempCondition lowTemp:lowTempCondition pressure:pressureCondition humidity:humidityCondition];
	}

	temperatureCondition = nil;
	currentWeatherCondition = nil;
	highTempCondition = nil;
	lowTempCondition = nil;
	pressureCondition = nil;
	humidityCondition = nil;

	cityLabel = nil;
	temperatureLabel = nil;
	weatherDescriptionLabel = nil;

	pageControl = nil;
	highLabel = nil;
	lowLabel = nil;
	pressureLabel = nil;
	humidityLabel = nil;

	timeLabel = nil;

	if(dateTimer) {
		[dateTimer invalidate];
		dateTimer = nil;
	}
}

//UI creation
-(UIView*)_createdFullFeaturedWidgetWithCurrentWeather:(NSString*)weather currentTemperature:(NSString*)temperature highTemp:(NSString*)highTemp lowTemp:(NSString*)lowTemp pressure:(NSString*)pressure humidity:(NSString*)humidity {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSNumber *enabledNum = settings[kRWEnabledKey];
	BOOL tweakEnabled = enabledNum ? [enabledNum boolValue] : 0;

	NSNumber *clockNum = settings[kRWClockViewKey];
	BOOL clockEnabled = clockNum ? [clockNum boolValue] : 0;

	NSNumber *detailNum = settings[kRWDetailedViewKey];
	BOOL detailEnabled = detailNum ? [detailNum boolValue] : 0;

	NSMutableArray *views = [NSMutableArray array];
	if (tweakEnabled) {
		if (clockEnabled)
		{
			[views addObject:[self _createdClockView]];
		}

		[views addObject:[self _createdWeatherViewWithCurrentWeather:weather currentTemperature:temperature]];

		if (detailEnabled) {
			[views addObject:[self _createdDetailedViewWithHighTemp:highTemp lowTemp:lowTemp pressure:pressure humidity:humidity]];
		}
	} else {
		return nil;
	}

	if (views.count == 1) {
		return views[0];
	} else {
		UIView *wrapperView = [[UIView alloc] initWithFrame:backgroundWindow.bounds];
		UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:wrapperView.frame];

		for (int i = 0; i < views.count; i++) {
			UIView *curView = views[i];
			CGRect frame = curView.frame;
	    	frame.origin.x = curView.frame.size.width * i;
	   		curView.frame = frame;

	   		[scrollView addSubview:curView];
		}

	    scrollView.contentSize = CGSizeMake(wrapperView.frame.size.width * views.count,scrollView.frame.size.height);
	    [scrollView setScrollEnabled:YES];
	    [scrollView setPagingEnabled:YES];
	    [scrollView setUserInteractionEnabled:YES];
	    [scrollView setDelaysContentTouches:YES];
	    [scrollView setDirectionalLockEnabled:YES];
	    [scrollView setCanCancelContentTouches:YES];
	    [scrollView setShowsHorizontalScrollIndicator:NO];
		[scrollView setDelegate:self];

		[wrapperView addSubview:scrollView];

		pageControl = [[UIPageControl alloc] init];
		[pageControl setNumberOfPages:views.count];
		CGRect pageFrame = pageControl.frame;
		pageFrame.origin.x = (wrapperView.frame.size.width / 2.0) - (pageFrame.size.width / 2.0);
		pageFrame.origin.y = wrapperView.frame.size.height - pageFrame.size.height - kRWCushionBorder;
		pageControl.frame = pageFrame;
		[wrapperView addSubview:pageControl];
		return wrapperView;
	}

}

-(UIView*)_createdClockView {
	UIView *wrapperView = [[UIView alloc] initWithFrame:backgroundWindow.bounds];
	timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(kRWCushionBorder,kRWCushionBorder,wrapperView.frame.size.width - kRWCushionBorder - kRWCushionBorder,wrapperView.frame.size.height - kRWCushionBorder - kRWCushionBorder)];
	[timeLabel setFont:[UIFont systemFontOfSize:60.0]];
	[timeLabel setTextColor:[UIColor whiteColor]];
	[timeLabel setTextAlignment:NSTextAlignmentCenter];
	[timeLabel setText:[self currentDateAsLocalizedString]];
	dateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
	[wrapperView addSubview:timeLabel];

	return wrapperView;
}

-(UIView*)_createdDetailedViewWithHighTemp:(NSString*)highTemp lowTemp:(NSString*)lowTemp pressure:(NSString*)pressure humidity:(NSString*)humidity {
	UIView *detailedView = [[UIView alloc] initWithFrame:backgroundWindow.bounds];

	highLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,cityLabel.frame.origin.y - 25.0,detailedView.frame.size.width,25.0)];
	lowLabel = [[UILabel alloc] initWithFrame:CGRectMake(highLabel.frame.origin.x,highLabel.frame.origin.y + highLabel.frame.size.height + 4.0,highLabel.frame.size.width,25.0)];
	pressureLabel = [[UILabel alloc] initWithFrame:CGRectMake(highLabel.frame.origin.x,lowLabel.frame.origin.y + lowLabel.frame.size.height + 4.0,highLabel.frame.size.width,25.0)];
	humidityLabel = [[UILabel alloc] initWithFrame:CGRectMake(highLabel.frame.origin.x,pressureLabel.frame.origin.y + pressureLabel.frame.size.height + 4.0,highLabel.frame.size.width,25.0)];

	[highLabel setTextAlignment:NSTextAlignmentCenter];
	[highLabel setFont:[UIFont systemFontOfSize:20.0]];
	[highLabel setTextColor:[UIColor whiteColor]];
	[highLabel setText:highTemp];

	[lowLabel setTextAlignment:NSTextAlignmentCenter];
	[lowLabel setFont:[UIFont systemFontOfSize:20.0]];
	[lowLabel setTextColor:[UIColor whiteColor]];
	[lowLabel setText:lowTemp];

	[pressureLabel setTextAlignment:NSTextAlignmentCenter];
	[pressureLabel setFont:[UIFont systemFontOfSize:20.0]];
	[pressureLabel setTextColor:[UIColor whiteColor]];
	[pressureLabel setText:pressure];

	[humidityLabel setTextAlignment:NSTextAlignmentCenter];
	[humidityLabel setFont:[UIFont systemFontOfSize:20.0]];
	[humidityLabel setTextColor:[UIColor whiteColor]];
	[humidityLabel setText:humidity];

	[detailedView addSubview:highLabel];
	[detailedView addSubview:lowLabel];
	[detailedView addSubview:pressureLabel];
	[detailedView addSubview:humidityLabel];

	return detailedView;
}

-(UIView*)_createdWeatherViewWithCurrentWeather:(NSString*)weather currentTemperature:(NSString*)temperature {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];

	NSNumber *enabledNum = settings[kRWEnabledKey];
	BOOL tweakEnabled = enabledNum ? [enabledNum boolValue] : 0;

	if (enabledNum && tweakEnabled) {
		UIView *weatherView = [[UIView alloc] initWithFrame:backgroundWindow.bounds];

		temperatureLabel = [[UILabel alloc] initWithFrame:CGRectMake(kRWCushionBorder,([backgroundWindow frame].size.height / 2.0)-27.5,100.0,55.0)];
		[temperatureLabel setTextAlignment:NSTextAlignmentLeft];
		[temperatureLabel setFont:[UIFont systemFontOfSize:44.0]];
		[temperatureLabel setTextColor:[UIColor whiteColor]];

		cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(kRWCushionBorder + temperatureLabel.frame.size.width + 10.0,temperatureLabel.frame.origin.y,[backgroundWindow frame].size.width - temperatureLabel.frame.origin.x - temperatureLabel.frame.size.width,30.0)];
		[cityLabel setTextAlignment:NSTextAlignmentLeft];
		[cityLabel setFont:[UIFont systemFontOfSize:28.0]];
		[cityLabel setTextColor:[UIColor whiteColor]];

		weatherDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(cityLabel.frame.origin.x,cityLabel.frame.origin.y + cityLabel.frame.size.height + 4.0,cityLabel.frame.size.width - temperatureLabel.frame.origin.x - temperatureLabel.frame.size.width,20.0)];
		[weatherDescriptionLabel setTextAlignment:NSTextAlignmentLeft];
		[weatherDescriptionLabel setNumberOfLines:0];
		[weatherDescriptionLabel setFont:[UIFont systemFontOfSize:15.0]];
		[weatherDescriptionLabel setTextColor:[UIColor lightGrayColor]];

		NSString *settingsCity;
		if (!settings[kRWCityKey]) {
			settingsCity = @"New York";
		} else {
			settingsCity = settings[kRWCityKey];
		}

		[cityLabel setText:settingsCity];
		[cityLabel sizeToFit];

		[temperatureLabel setText:temperature];
		[temperatureLabel sizeToFit];
		[weatherDescriptionLabel setText:weather];
		[weatherDescriptionLabel sizeToFit];

		[weatherView addSubview:temperatureLabel];
		[weatherView addSubview:cityLabel];
		[weatherView addSubview:weatherDescriptionLabel];
		
		return weatherView;
	} else {
		return nil;
	}
}

//Helper methods
-(void)_fetchCurrentWeatherForCityNamed:(NSString*)city completion:(RWWeatherCompletionBlock)completionBlock {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSString *settingsLang;
	if (!settings[kRWLanguageKey]) {
		settingsLang = @"en";
	} else {
		settingsLang = settings[kRWLanguageKey];
	}

	NSString *const BASE_URL_STRING = @"http://api.openweathermap.org/data/2.5/weather";
 
    NSString *weatherURLText = [NSString stringWithFormat:@"%@?q=%@&lang=%@",
                                BASE_URL_STRING, [city stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],settingsLang];
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
	BOOL celsiusEnabled = celsiusNum ? [celsiusNum boolValue] : 0;

	NSNumber *temp;
    if (!celsiusEnabled) {
    	temp = [NSNumber numberWithDouble: ((degreesKelvin*(9.0/5.0)) - 459.67)];
    } else {
    	temp = [NSNumber numberWithDouble: (degreesKelvin - 273.15)];
    }

    return [temp integerValue];
}

-(NSString*)currentDateAsLocalizedString {
	NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
	NSDateComponents *timeComponents = [calendar components:( NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:[NSDate date]];

	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setHour:[timeComponents hour]];
	[comps setMinute:[timeComponents minute]];
	NSDate* date = [calendar dateFromComponents:comps];
	return [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
}

-(void)updateTime:(id)sender {
	NSString *currentTime = [self currentDateAsLocalizedString];
  	timeLabel.text = currentTime;
}

//UIScrollViewDelegate
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	CGFloat pageWidth = scrollView.frame.size.width;
    NSInteger page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    [pageControl setCurrentPage:page];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSNumber *manualControlNum = settings[kRWManualControlKey];
	BOOL mcEnabled = manualControlNum ? [manualControlNum boolValue] : 0;
	if (!mcEnabled) {
		RWLog(@"AUTO CONTROL ACTIVE");
		[[objc_getClass("SBReachabilityManager") sharedInstance] _setKeepAliveTimerForDuration:2.0];
	} else {
		RWLog(@"MANUAL CONTROL ACTIVE");
		[[objc_getClass("SBReachabilityManager") sharedInstance] disableExpirationTimerForInteraction];
	}
 }

@end