//RWWeatherController.m
#import "RWWeatherController.h"
#import "RWForecast.h"
#import "HexColor.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

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

-(void)activateWidgetArea {
	if (![[objc_getClass("SBReachabilityManager") sharedInstance] reachabilityModeActive]) {
		[[objc_getClass("SBReachabilityManager") sharedInstance] _handleReachabilityActivated];
	} else {
		[[objc_getClass("SBReachabilityManager") sharedInstance] _handleReachabilityDeactivated];
	}
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

	NSNumber *forecastNum = settings[kRWForecastViewKey];
	BOOL fcEnabled = forecastNum ? [forecastNum boolValue] : 0;

	NSString *settingsCity;
	if (!settings[kRWCityKey]) {
		settingsCity = @"New York";
	} else {
		settingsCity = settings[kRWCityKey];
	}


	if (enabledNum && tweakEnabled && backgroundWindow) {
		UIActivityIndicatorView *loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		loadingSpinner.frame = CGRectMake((backgroundWindow.bounds.size.width / 2.0) - (loadingSpinner.frame.size.width / 2.0), (backgroundWindow.bounds.size.height / 2.0) - (loadingSpinner.frame.size.height / 2.0), loadingSpinner.frame.size.width,loadingSpinner.frame.size.height);
		[loadingSpinner startAnimating];
		[backgroundWindow addSubview:loadingSpinner];
		[self _fetchDetailedWeatherForCityNamed:[settingsCity stringByReplacingOccurrencesOfString:@" " withString:@"+"] completion:^(NSDictionary *result, NSError *error) {
			if (!error) {
			   	temperatureCondition = result[@"currentTemp"];

				currentWeatherCondition = result[@"currentWeather"];

				highTempCondition = result[@"currentHigh"];
				lowTempCondition = result[@"currentLow"];

				pressureCondition = result[@"currentPressure"];
				humidityCondition = result[@"currentHumidity"];

			} else {
				RWLog(@"ERROR: %@",error.localizedDescription);
				if (celsiusEnabled) {
					temperatureCondition = @"--\u00B0C";
					highTempCondition = @"High: --\u00B0C";
					lowTempCondition = @"Low: --\u00B0C";
			    } else {
					temperatureCondition = @"--\u00B0F";
					highTempCondition = @"High: --\u00B0F";
					lowTempCondition = @"Low: --\u00B0F";
			    }
			    currentWeatherCondition = @"Error: unable to retreive current weather conditions.";
				pressureCondition = @"Pressure: -- mb";
				humidityCondition = @"Humidity: --%";
			}


			if (fcEnabled) {
				[self _fetchForecastsForCity:settingsCity completion:^(NSArray *results, NSError *error) {
					[loadingSpinner stopAnimating];
					[loadingSpinner removeFromSuperview];
					if (!error && results) {
						forecasts = results;
						[backgroundWindow addSubview:[self _createdFullFeaturedWidgetWithCurrentWeather:currentWeatherCondition currentTemperature:temperatureCondition highTemp:highTempCondition lowTemp:lowTempCondition pressure:pressureCondition humidity:humidityCondition forecasts:forecasts]];
					} else {
						[backgroundWindow addSubview:[self _createdFullFeaturedWidgetWithCurrentWeather:currentWeatherCondition currentTemperature:temperatureCondition highTemp:highTempCondition lowTemp:lowTempCondition pressure:pressureCondition humidity:humidityCondition forecasts:nil]];
					}
				}];
			} else {
				[loadingSpinner stopAnimating];
				[loadingSpinner removeFromSuperview];
				[backgroundWindow addSubview:[self _createdFullFeaturedWidgetWithCurrentWeather:currentWeatherCondition currentTemperature:temperatureCondition highTemp:highTempCondition lowTemp:lowTempCondition pressure:pressureCondition humidity:humidityCondition forecasts:nil]];
			}

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

	if ([self _createdFullFeaturedWidgetWithCurrentWeather:currentWeatherCondition currentTemperature:temperatureCondition highTemp:highTempCondition lowTemp:lowTempCondition pressure:pressureCondition humidity:humidityCondition forecasts:nil]) {

		[self _createdFullFeaturedWidgetWithCurrentWeather:currentWeatherCondition currentTemperature:temperatureCondition highTemp:highTempCondition lowTemp:lowTempCondition pressure:pressureCondition humidity:humidityCondition forecasts:nil];
	}

	if ([self _createdFullFeaturedWidgetWithCurrentWeather:currentWeatherCondition currentTemperature:temperatureCondition highTemp:highTempCondition lowTemp:lowTempCondition pressure:pressureCondition humidity:humidityCondition forecasts:forecasts]) {

		[self _createdFullFeaturedWidgetWithCurrentWeather:currentWeatherCondition currentTemperature:temperatureCondition highTemp:highTempCondition lowTemp:lowTempCondition pressure:pressureCondition humidity:humidityCondition forecasts:forecasts];
	}

	backgroundWindow = nil;

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

	forecasts = nil;
}

//UI creation
-(UIView*)_createdFullFeaturedWidgetWithCurrentWeather:(NSString*)weather currentTemperature:(NSString*)temperature highTemp:(NSString*)highTemp lowTemp:(NSString*)lowTemp pressure:(NSString*)pressure humidity:(NSString*)humidity forecasts:(NSArray*)items {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSNumber *enabledNum = settings[kRWEnabledKey];
	BOOL tweakEnabled = enabledNum ? [enabledNum boolValue] : 0;

	NSNumber *clockNum = settings[kRWClockViewKey];
	BOOL clockEnabled = clockNum ? [clockNum boolValue] : 0;

	NSNumber *detailNum = settings[kRWDetailedViewKey];
	BOOL detailEnabled = detailNum ? [detailNum boolValue] : 0;

	NSNumber *forecastNum = settings[kRWForecastViewKey];
	BOOL fcEnabled = forecastNum ? [forecastNum boolValue] : 0;

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

		if (fcEnabled && items) {
			[views addObject:[self _createdForecastsView:items]];
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
	[timeLabel setTextColor:[self setTitleColor]];
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
	[highLabel setTextColor:[self setTitleColor]];
	[highLabel setText:highTemp];

	[lowLabel setTextAlignment:NSTextAlignmentCenter];
	[lowLabel setFont:[UIFont systemFontOfSize:20.0]];
	[lowLabel setTextColor:[self setTitleColor]];
	[lowLabel setText:lowTemp];

	[pressureLabel setTextAlignment:NSTextAlignmentCenter];
	[pressureLabel setFont:[UIFont systemFontOfSize:20.0]];
	[pressureLabel setTextColor:[self setTitleColor]];
	[pressureLabel setText:pressure];

	[humidityLabel setTextAlignment:NSTextAlignmentCenter];
	[humidityLabel setFont:[UIFont systemFontOfSize:20.0]];
	[humidityLabel setTextColor:[self setTitleColor]];
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
		[temperatureLabel setTextColor:[self setTitleColor]];
		[temperatureLabel setText:temperature];
		[temperatureLabel sizeToFit];

		cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(kRWCushionBorder + temperatureLabel.frame.size.width + 10.0,temperatureLabel.frame.origin.y,[backgroundWindow frame].size.width - temperatureLabel.frame.origin.x - temperatureLabel.frame.size.width - kRWCushionBorder,32.0)];
		[cityLabel setTextAlignment:NSTextAlignmentLeft];
		[cityLabel setFont:[UIFont systemFontOfSize:28.0]];
		[cityLabel setTextColor:[self setTitleColor]];
		[cityLabel setMinimumScaleFactor:0.50];
		[cityLabel setAdjustsFontSizeToFitWidth:YES];

		NSString *settingsCity;
		if (!settings[kRWCityKey]) {
			settingsCity = @"New York";
		} else {
			settingsCity = settings[kRWCityKey];
		}

		weatherDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(cityLabel.frame.origin.x,cityLabel.frame.origin.y + cityLabel.frame.size.height + 4.0,cityLabel.frame.size.width - temperatureLabel.frame.origin.x - temperatureLabel.frame.size.width,20.0)];
		[weatherDescriptionLabel setTextAlignment:NSTextAlignmentLeft];
		[weatherDescriptionLabel setNumberOfLines:0];
		[weatherDescriptionLabel setFont:[UIFont systemFontOfSize:15.0]];
		[weatherDescriptionLabel setTextColor:[self setDetailColor]];

		[cityLabel setText:settingsCity];

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

-(UIView*)_createdForecastsView:(NSArray*)items {
	UIView *containerView = [[UIView alloc] initWithFrame:[self forecastsContainerFrame]];
	CGFloat heightOffset = 35.0; 
	if (IS_IPHONE_5) {
		heightOffset = 10.0;
	}

	UILabel *forecastLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0,heightOffset,containerView.frame.size.width,28.0)];

	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSString *count;
	if (settings[kRWForecastTypeKey]) {
		count = settings[kRWForecastTypeKey];
	} else {
		count = @"3";
	}
	[forecastLabel setText:[NSString stringWithFormat:@"%@-Day Forecast",count]];
	[forecastLabel setFont:[UIFont systemFontOfSize:24.0]];
	[forecastLabel setTextColor:[self setDetailColor]];
	[forecastLabel setTextAlignment:NSTextAlignmentCenter];
	[containerView addSubview:forecastLabel];

	for (int i = 0; i < items.count; i++)
	{
		RWForecast *forecast = items[i];
		UIView *forecastView = [forecast forecastViewForDayCount:items.count];
		CGRect frame = forecastView.frame;
		frame.origin.x = forecastView.frame.size.width * i;
		frame.origin.y = forecastLabel.frame.origin.y + forecastLabel.frame.size.height + 8.0;
		forecastView.frame = frame;
		[containerView addSubview:forecastView];
	}

	return containerView;
}

-(CGRect)forecastsContainerFrame {
	return backgroundWindow.bounds;
}

//Helper methods
-(void)_fetchDetailedWeatherForCityNamed:(NSString*)city count:(NSString*)count completion:(RWWeatherCompletionBlock)completionBlock {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSString *settingsLang;
	if (!settings[kRWLanguageKey]) {
		settingsLang = @"en";
	} else {
		settingsLang = settings[kRWLanguageKey];
	}

	NSString *settingsCity;
	if (!settings[kRWCityKey]) {
		settingsCity = @"New York";
	} else {
		settingsCity = settings[kRWCityKey];
	}

	NSNumber *celsiusNum = settings[kRWCelsiusEnabledKey];
	BOOL celsiusEnabled = celsiusNum ? [celsiusNum boolValue] : 0;

	NSMutableDictionary *dataDictionary = [[NSMutableDictionary alloc] init];

	[self _fetchCurrentWeatherForCityNamed:[settingsCity stringByReplacingOccurrencesOfString:@" " withString:@"+"] completion:^(NSDictionary *result, NSError *error) {
		if (!error && result != nil) {
			RWLog(@"DATADICTIONARY INITIALIZED, ABOUT TO ADD RESULT FROM CURRENTWEATHER");
			[dataDictionary addEntriesFromDictionary:result];
			RWLog(@"DATADICTIONARY FROM CURRENTWEATHER: %@",dataDictionary);

			NSString * BASE_URL_STRING = @"http://api.openweathermap.org/data/2.5/forecast/daily";
 
		    NSString *weatherURLText = [NSString stringWithFormat:@"%@?q=%@&lang=%@&cnt=%@&mode=json",
		                                BASE_URL_STRING, [city stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],settingsLang,count];
		    NSURL *weatherURL = [NSURL URLWithString:weatherURLText];
		    NSURLRequest *weatherRequest = [NSURLRequest requestWithURL:weatherURL];

		    [NSURLConnection sendAsynchronousRequest:weatherRequest 
		                                       queue:[NSOperationQueue mainQueue]
		                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		        if (!error && response && data) {
		        	RWLog(@"RECIEVED DETAILED WEATHER PARSABLE RESPONSE");
			    	// Now create a NSDictionary from the JSON data
				    NSError *jsonError;
				    id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
				    if (!jsonError && [JSON isKindOfClass:[NSDictionary class]]) {
				    	dispatch_async(dispatch_get_main_queue(), ^(void){
				    		NSDictionary *jsonDict = (NSDictionary*)JSON;
				    		NSNumber *code = jsonDict[@"cod"];
				    		RWLog(@"JSON DETAILED WEATHER DICT: %@, CODE: %@",jsonDict,code);
				    		if (code.intValue != 404) {
				    			if ([count isEqualToString:@"1"]) {
				    				NSArray *items = jsonDict[@"list"];
						    		NSDictionary *dayData = items[0];

						    		NSString *curHigh;
						    		NSString *curLow;

						    		NSInteger highTemp = [self kelvinToLocalTemp:[dayData[@"temp"][@"day"] doubleValue]];
									NSInteger lowTemp = [self kelvinToLocalTemp:[dayData[@"temp"][@"night"] doubleValue]];

									if (celsiusEnabled) {
										curHigh = [NSString stringWithFormat:@"High: %ld\u00B0C",(long)highTemp];
										curLow = [NSString stringWithFormat:@"Low: %ld\u00B0C",(long)lowTemp];
								    } else {
										curHigh = [NSString stringWithFormat:@"High: %ld\u00B0F",(long)highTemp];
										curLow = [NSString stringWithFormat:@"Low: %ld\u00B0F",(long)lowTemp];
								    }

						    		[dataDictionary setObject:curHigh forKey:@"currentHigh"];
						    		[dataDictionary setObject:curLow forKey:@"currentLow"];

						    		RWLog(@"DATA DICTIONARY GOING TO CALLBACK: %@",dataDictionary);

						    		completionBlock(dataDictionary,nil);
				    			} else {
				    				completionBlock(jsonDict,nil);
				    			}
					    		
				    		} else {
				    			NSDictionary *userInfo = @{
								  NSLocalizedDescriptionKey: NSLocalizedString(@"Current weather for city not found.", nil),
								                          };
								NSError *error = [NSError errorWithDomain:@"me.akeaswaran.reachweather.error"
		                                     code:404
		                                 userInfo:userInfo];
				    			completionBlock(nil,error);
				    		}
				    	});
				    	
			    	} else {
			    		dispatch_async(dispatch_get_main_queue(), ^(void){
				    		completionBlock(nil,jsonError);
		   				 });
			    	}
			    } else {
			    	dispatch_async(dispatch_get_main_queue(), ^(void){
				    	completionBlock(nil,error);
		   			});
			    }
		    }]; 
		} else {
			dispatch_async(dispatch_get_main_queue(), ^(void){
		    	completionBlock(nil,error);
   			});
		}
	}];
}

-(void)_fetchDetailedWeatherForCityNamed:(NSString*)city completion:(RWWeatherCompletionBlock)completionBlock {
	[self _fetchDetailedWeatherForCityNamed:city count:@"1" completion:^(NSDictionary *result, NSError *error) {
		completionBlock(result,error);
	}];
}

-(void)_fetchForecastsForCity:(NSString*)city completion:(RWForecastCompletionBlock)completionBlock {
	
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSString *count;
	if (settings[kRWForecastTypeKey]) {
		count = settings[kRWForecastTypeKey];
	} else {
		count = @"3";
	}

	[self _fetchDetailedWeatherForCityNamed:city count:count completion:^(NSDictionary *result, NSError *error) {
		if (!error && result) {
			NSArray *items = result[@"list"];
			NSMutableArray *results = [NSMutableArray array];

			for (NSDictionary *item in items) {
				RWForecast *forecast = [[RWForecast alloc] initWithDictionary:item];
				[results addObject:forecast];
			}
			completionBlock(results,nil);
		} else {
			if (error) {
				completionBlock(nil, error);
			} else {
				NSDictionary *userInfo = @{
						  NSLocalizedDescriptionKey: NSLocalizedString(@"Unabled to fetch forecasts", nil),
						                          };
				NSError *rwError = [NSError errorWithDomain:@"me.akeaswaran.reachweather.error"
                             code:404
                         userInfo:userInfo];
    			completionBlock(nil,rwError);
			}
		}
	}];
}

-(void)_fetchCurrentWeatherForCityNamed:(NSString*)city completion:(RWWeatherCompletionBlock)completionBlock {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSString *settingsLang;
	if (!settings[kRWLanguageKey]) {
		settingsLang = @"en";
	} else {
		settingsLang = settings[kRWLanguageKey];
	}

	NSNumber *celsiusNum = settings[kRWCelsiusEnabledKey];
	BOOL celsiusEnabled = celsiusNum ? [celsiusNum boolValue] : 0;

	NSString * BASE_URL_STRING = @"http://api.openweathermap.org/data/2.5/weather";
 
    NSString *weatherURLText = [NSString stringWithFormat:@"%@?q=%@&lang=%@",
                                BASE_URL_STRING, [city stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],settingsLang];
    NSURL *weatherURL = [NSURL URLWithString:weatherURLText];
    NSURLRequest *weatherRequest = [NSURLRequest requestWithURL:weatherURL];

    [NSURLConnection sendAsynchronousRequest:weatherRequest 
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (!error && response && data) {
	    	// Now create a NSDictionary from the JSON data
	    	RWLog(@"RECIEVED CURRENT WEATHER PARSABLE RESPONSE");
		    NSError *jsonError;
		    id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
		    if (!jsonError && [JSON isKindOfClass:[NSDictionary class]]) {
		    	dispatch_async(dispatch_get_main_queue(), ^(void){
		    		NSDictionary *jsonDict = (NSDictionary*)JSON;
		    		NSNumber *code = jsonDict[@"cod"];
		    		RWLog(@"JSON CURRENT WEATHER DICT: %@, CODE: %@",jsonDict,code);
		    		if (code.intValue != 404) {
		    			RWLog(@"VALID CODE: %@",code);
			    		NSInteger tempCurrent = [self kelvinToLocalTemp:[jsonDict[@"main"][@"temp"] doubleValue]];
			    		NSString *temp;
						if (celsiusEnabled) {
							temp = [NSString stringWithFormat:@"%ld\u00B0C",(long)tempCurrent];
					    } else {
							temp = [NSString stringWithFormat:@"%ld\u00B0F",(long)tempCurrent];
					    }

						NSArray *conditions = jsonDict[@"weather"];
						NSString *curCondition = conditions[0][@"description"];

						NSNumber *pressure = [NSNumber numberWithDouble:[jsonDict[@"main"][@"pressure"] doubleValue]];
						NSNumber *humidity = [NSNumber numberWithDouble:[jsonDict[@"main"][@"humidity"] doubleValue]];

						NSString *curPressure = [NSString stringWithFormat:@"Pressure: %ld mb",(long)[pressure integerValue]];
						NSString *curHumidity = [NSString stringWithFormat:@"Humidity: %ld%%",(long)[humidity integerValue]];

						NSDictionary *resultDict = @{@"currentTemp": temp, @"currentWeather" : curCondition, @"currentPressure" : curPressure, @"currentHumidity" : curHumidity};
						RWLog(@"RESULT DICT GOING TO CALLBACK: %@",resultDict);

			    		completionBlock(resultDict,nil);
		    		} else {
		    			RWLog(@"INVALID CODE: %@",code);
		    			NSDictionary *userInfo = @{
						  NSLocalizedDescriptionKey: NSLocalizedString(@"Current weather for city not found.", nil),
						                          };
						NSError *error = [NSError errorWithDomain:@"me.akeaswaran.reachweather.error"
                                     code:404
                                 userInfo:userInfo];
		    			completionBlock(nil,error);
		    		}
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

+ (BOOL)isActivatorInstalled {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/usr/lib/libactivator.dylib"];
}

-(UIColor *)setTitleColor {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSString *settingsHex;
	if (!settings[kRWTitleColorKey]) {
		settingsHex = @"#FFFFFF";
	} else {
		settingsHex = settings[kRWTitleColorKey];
	}

	NSNumber *titleColorNum = settings[kRWTitleColorSwitchKey];
	BOOL tcEnabled = titleColorNum ? [titleColorNum boolValue] : 0;
	UIColor *setColor;
	if (tcEnabled) {
		setColor = [HXColor colorWithHexString:settingsHex];
	} else {
		setColor = [UIColor whiteColor];
	}
	return setColor;
}

-(UIColor *)setDetailColor {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSString *settingsHex;
	if (!settings[kRWDetailColorKey]) {
		settingsHex = @"#FFFFFF";
	} else {
		settingsHex = settings[kRWDetailColorKey];
	}

	NSNumber *titleColorNum = settings[kRWDetailColorSwitchKey];
	BOOL tcEnabled = titleColorNum ? [titleColorNum boolValue] : 0;
	UIColor *setColor;
	if (tcEnabled) {
		setColor = [HXColor colorWithHexString:settingsHex];
	} else {
		setColor = [UIColor lightGrayColor];
	}
	return setColor;
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