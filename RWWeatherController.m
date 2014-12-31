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

-(NSString*)localizedStringWithKey:(NSString*)key {
  NSBundle *tweakBundle = [NSBundle bundleWithPath:kRWBundlePath];
  return [tweakBundle localizedStringForKey:key value:@"" table:nil];
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
				curIconCode = result[@"conditionCode"];

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
				curIconCode = nil;
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
	widgetBackgroundView = nil;
	curIconCode = nil;

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

	widgets = [NSMutableArray array];
	if (tweakEnabled) {
		if (clockEnabled)
		{
			[widgets addObject:[self _createdClockView]];
		}

		[widgets addObject:[self _createdWeatherViewWithCurrentWeather:weather currentTemperature:temperature]];

		if (detailEnabled) {
			[widgets addObject:[self _createdDetailedViewWithHighTemp:highTemp lowTemp:lowTemp pressure:pressure humidity:humidity]];
		}

		if (fcEnabled && items) {
			[widgets addObject:[self _createdForecastsView:items]];
		}

		return [self _widgetContainerWithViews:widgets];
	} else {
		return nil;
	}

	

}

-(UIView*)_widgetContainerWithViews:(NSArray*)views {
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
	NSNumber *weatherImgNum = settings[kRWWeatherImagesKey];
	BOOL wiEnabled = weatherImgNum ? [weatherImgNum boolValue] : 0;

	if (wiEnabled && curIconCode != nil) {
		widgetBackgroundView = [self _weatherBitmapImageViewWithConditionCode:curIconCode fittingRect:backgroundWindow.bounds];
	}

	if (views.count == 1) {
		if (curIconCode != nil) {
			[widgetBackgroundView addSubview:views[0]];
			return widgetBackgroundView;
		} else {
			return views[0];
		}
	} else {
		widgetContainerView = [[UIView alloc] initWithFrame:backgroundWindow.bounds];
		if (wiEnabled && curIconCode != nil) {
			[widgetContainerView addSubview:widgetBackgroundView];
		}
		UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:widgetContainerView.frame];

		for (int i = 0; i < views.count; i++) {
			UIView *curView = views[i];
			CGRect frame = curView.frame;
	    	frame.origin.x = curView.frame.size.width * i;
	   		curView.frame = frame;
	   		[scrollView addSubview:curView];
		}

	    scrollView.contentSize = CGSizeMake(widgetContainerView.frame.size.width * views.count,scrollView.frame.size.height);
	    [scrollView setScrollEnabled:YES];
	    [scrollView setPagingEnabled:YES];
	    [scrollView setUserInteractionEnabled:YES];
	    [scrollView setDelaysContentTouches:YES];
	    [scrollView setDirectionalLockEnabled:YES];
	    [scrollView setCanCancelContentTouches:YES];
	    [scrollView setShowsHorizontalScrollIndicator:NO];
		[scrollView setDelegate:self];
		[widgetContainerView addSubview:scrollView];

		pageControl = [[UIPageControl alloc] init];
		[pageControl setNumberOfPages:views.count];
		CGRect pageFrame = pageControl.frame;
		pageFrame.origin.x = (widgetContainerView.frame.size.width / 2.0) - (pageFrame.size.width / 2.0);
		pageFrame.origin.y = widgetContainerView.frame.size.height - pageFrame.size.height - kRWCushionBorder;
		pageControl.frame = pageFrame;
		[widgetContainerView addSubview:pageControl];
		return widgetContainerView;
	}
}

-(UIView*)_createdClockView {
	UIView *wrapperView = [[UIView alloc] initWithFrame:backgroundWindow.bounds];
	timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(kRWCushionBorder,kRWCushionBorder,wrapperView.frame.size.width - kRWCushionBorder - kRWCushionBorder,wrapperView.frame.size.height - kRWCushionBorder - kRWCushionBorder)];
	[timeLabel setFont:[UIFont systemFontOfSize:60.0]];
	[timeLabel setTextColor:[self settingsTitleColor]];
	[timeLabel setTextAlignment:NSTextAlignmentCenter];
	[timeLabel setText:[self currentDateAsLocalizedString]];
	dateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTime:) userInfo:nil repeats:YES];
	[wrapperView addSubview:timeLabel];

	return wrapperView;
}

-(UIView*)_createdDetailedViewWithHighTemp:(NSString*)highTemp lowTemp:(NSString*)lowTemp pressure:(NSString*)pressure humidity:(NSString*)humidity {
	UIView *detailedView = [[UIView alloc] initWithFrame:backgroundWindow.bounds];

	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];

	NSNumber *centerNum = settings[kRWCenterMainViewKey];
	BOOL centered = centerNum ? [centerNum boolValue] : 0;

	if (!centered) {
		highLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,cityLabel.frame.origin.y - 25.0,detailedView.frame.size.width,25.0)];
	} else {
		highLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,temperatureLabel.frame.origin.y,detailedView.frame.size.width,25.0)];
	}
	lowLabel = [[UILabel alloc] initWithFrame:CGRectMake(highLabel.frame.origin.x,highLabel.frame.origin.y + highLabel.frame.size.height + 4.0,highLabel.frame.size.width,25.0)];
	pressureLabel = [[UILabel alloc] initWithFrame:CGRectMake(highLabel.frame.origin.x,lowLabel.frame.origin.y + lowLabel.frame.size.height + 4.0,highLabel.frame.size.width,25.0)];
	humidityLabel = [[UILabel alloc] initWithFrame:CGRectMake(highLabel.frame.origin.x,pressureLabel.frame.origin.y + pressureLabel.frame.size.height + 4.0,highLabel.frame.size.width,25.0)];


	[highLabel setTextAlignment:NSTextAlignmentCenter];
	[highLabel setFont:[UIFont systemFontOfSize:20.0]];
	[highLabel setTextColor:[self settingsTitleColor]];
	[highLabel setText:highTemp];

	[lowLabel setTextAlignment:NSTextAlignmentCenter];
	[lowLabel setFont:[UIFont systemFontOfSize:20.0]];
	[lowLabel setTextColor:[self settingsTitleColor]];
	[lowLabel setText:lowTemp];

	[pressureLabel setTextAlignment:NSTextAlignmentCenter];
	[pressureLabel setFont:[UIFont systemFontOfSize:20.0]];
	[pressureLabel setTextColor:[self settingsTitleColor]];
	[pressureLabel setText:pressure];

	[humidityLabel setTextAlignment:NSTextAlignmentCenter];
	[humidityLabel setFont:[UIFont systemFontOfSize:20.0]];
	[humidityLabel setTextColor:[self settingsTitleColor]];
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

	NSNumber *centerNum = settings[kRWCenterMainViewKey];
	BOOL centered = centerNum ? [centerNum boolValue] : 0;


	NSString *settingsCity;
	if (!settings[kRWCityKey]) {
		settingsCity = @"New York";
	} else {
		settingsCity = settings[kRWCityKey];
	}

	if (enabledNum && tweakEnabled) {
		UIView *weatherView = [[UIView alloc] initWithFrame:backgroundWindow.bounds];

		if (!centered) {
			temperatureLabel = [[UILabel alloc] initWithFrame:CGRectMake(kRWCushionBorder,([backgroundWindow frame].size.height / 2.0)-27.5,100.0,55.0)];
			[temperatureLabel setTextAlignment:NSTextAlignmentLeft];
			[temperatureLabel setFont:[UIFont systemFontOfSize:44.0]];
			[temperatureLabel setTextColor:[self settingsTitleColor]];
			[temperatureLabel setText:temperature];
			[temperatureLabel sizeToFit];

			cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(kRWCushionBorder + temperatureLabel.frame.size.width + 10.0,temperatureLabel.frame.origin.y,[backgroundWindow frame].size.width - temperatureLabel.frame.origin.x - temperatureLabel.frame.size.width - kRWCushionBorder,32.0)];
			[cityLabel setTextAlignment:NSTextAlignmentLeft];
			[cityLabel setFont:[UIFont systemFontOfSize:28.0]];
			[cityLabel setTextColor:[self settingsTitleColor]];
			[cityLabel setMinimumScaleFactor:0.50];
			[cityLabel setAdjustsFontSizeToFitWidth:YES];
			[cityLabel setText:settingsCity];

			weatherDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(cityLabel.frame.origin.x,cityLabel.frame.origin.y + cityLabel.frame.size.height + 4.0,cityLabel.frame.size.width - temperatureLabel.frame.origin.x - temperatureLabel.frame.size.width,20.0)];
			[weatherDescriptionLabel setTextAlignment:NSTextAlignmentLeft];
			[weatherDescriptionLabel setNumberOfLines:0];
			[weatherDescriptionLabel setFont:[UIFont systemFontOfSize:15.0]];
			[weatherDescriptionLabel setTextColor:[self settingsDetailColor]];
			[weatherDescriptionLabel setText:weather];
			[weatherDescriptionLabel sizeToFit];
		} else {
			temperatureLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,([backgroundWindow frame].size.height / 2.0)-55.0-16.0,backgroundWindow.bounds.size.width,55.0)];
			[temperatureLabel setTextAlignment:NSTextAlignmentCenter];
			[temperatureLabel setFont:[UIFont systemFontOfSize:44.0]];
			[temperatureLabel setTextColor:[self settingsTitleColor]];
			[temperatureLabel setText:temperature];

			cityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,temperatureLabel.frame.origin.y + temperatureLabel.frame.size.height + 4.0,temperatureLabel.frame.size.width,32.0)];
			[cityLabel setTextAlignment:NSTextAlignmentCenter];
			[cityLabel setFont:[UIFont systemFontOfSize:28.0]];
			[cityLabel setTextColor:[self settingsTitleColor]];
			[cityLabel setMinimumScaleFactor:0.50];
			[cityLabel setAdjustsFontSizeToFitWidth:YES];
			[cityLabel setText:settingsCity];

			weatherDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(cityLabel.frame.origin.x,cityLabel.frame.origin.y + cityLabel.frame.size.height + 4.0,temperatureLabel.frame.size.width,20.0)];
			[weatherDescriptionLabel setTextAlignment:NSTextAlignmentCenter];
			[weatherDescriptionLabel setNumberOfLines:0];
			[weatherDescriptionLabel setFont:[UIFont systemFontOfSize:15.0]];
			[weatherDescriptionLabel setTextColor:[self settingsDetailColor]];
			[weatherDescriptionLabel setText:weather];
		}

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
	CGFloat heightOffset = 25.0; 
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

	NSString *forecastTitle;
	if ([count isEqualToString:@"3"]) {
		forecastTitle = [self localizedStringWithKey:@"THREE_DAY_FORECAST"];
	} else {
		forecastTitle = [self localizedStringWithKey:@"FIVE_DAY_FORECAST"];
	}

	[forecastLabel setText:forecastTitle];
	[forecastLabel setFont:[UIFont systemFontOfSize:24.0]];
	[forecastLabel setTextColor:[self settingsTitleColor]];
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

						    		NSInteger highTemp = [self kelvinToLocalTemp:[dayData[@"temp"][@"max"] doubleValue]];
									NSInteger lowTemp = [self kelvinToLocalTemp:[dayData[@"temp"][@"min"] doubleValue]];

									if (celsiusEnabled) {
										curHigh = [NSString stringWithFormat:@"%@: %ld\u00B0C",[self localizedStringWithKey:@"HIGH"],(long)highTemp];
										curLow = [NSString stringWithFormat:@"%@: %ld\u00B0C",[self localizedStringWithKey:@"LOW"],(long)lowTemp];
								    } else {
										curHigh = [NSString stringWithFormat:@"%@: %ld\u00B0F",[self localizedStringWithKey:@"HIGH"],(long)highTemp];
										curLow = [NSString stringWithFormat:@"%@: %ld\u00B0F",[self localizedStringWithKey:@"LOW"],(long)lowTemp];
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
						  NSLocalizedDescriptionKey: NSLocalizedString(@"Unable to fetch forecasts", nil),
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
						NSString *iconCode = conditions[0][@"icon"];

						NSNumber *pressure = [NSNumber numberWithDouble:[jsonDict[@"main"][@"pressure"] doubleValue]];
						NSNumber *humidity = [NSNumber numberWithDouble:[jsonDict[@"main"][@"humidity"] doubleValue]];

						NSString *curPressure = [NSString stringWithFormat:@"%@: %ld mb",[self localizedStringWithKey:@"PRESSURE"],(long)[pressure integerValue]];
						NSString *curHumidity = [NSString stringWithFormat:@"%@: %ld%%",[self localizedStringWithKey:@"HUMIDITY"],(long)[humidity integerValue]];

						NSDictionary *resultDict = @{@"currentTemp": temp, @"currentWeather" : curCondition, @"currentPressure" : curPressure, @"currentHumidity" : curHumidity, @"conditionCode" : iconCode};
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

-(UIColor *)settingsTitleColor {
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

-(UIColor *)settingsDetailColor {
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

//modified version of solution to translating CPBitmaps into UIImages from StackOverflow: http://stackoverflow.com/questions/22580485/how-to-convert-hex-data-to-uiimage/
//UIImage cropping snippet from http://iosdevelopertips.com/graphics/how-to-crop-an-image.html

-(UIImageView*)_weatherBitmapImageViewWithConditionCode:(NSString*)conditionCode fittingRect:(CGRect)rect {
	NSString *imageName;
	NSString *backgroundImageName;
	if ([conditionCode isEqualToString:@"01d"]) { //sunny
		imageName = @"Sun-Left";
		backgroundImageName = @"Background-Glow-Day";
	} else if ([conditionCode isEqualToString:@"01n"]) {
		imageName = nil;
		backgroundImageName = @"Background-Glow-Night";
	} else if ([conditionCode isEqualToString:@"02d"]) { //partly cloudy
		imageName = @"Cirrus-One-Overlap";
		backgroundImageName = @"Background-Glow-Day";
	} else if ([conditionCode isEqualToString:@"02n"]) {
		imageName = @"Cirrus-One-Overlap";
		backgroundImageName = @"Background-Glow-Night";
	} else if ([conditionCode isEqualToString:@"03d"] || [conditionCode isEqualToString:@"04d"]) { //mostly cloudy
		imageName = @"Cloud-Patch-One";
		backgroundImageName = @"Background-Glow-Day";
	} else if ([conditionCode isEqualToString:@"03n"] || [conditionCode isEqualToString:@"04n"]) {
		imageName = @"Cloud-Patch-One";
		backgroundImageName = @"Background-Glow-Night";
	} else if ([conditionCode isEqualToString:@"09d"]) { //showers
		imageName = @"Cloud-Drizzle";
		backgroundImageName = @"Background-Glow-Day";
	} else if ([conditionCode isEqualToString:@"09n"]) {
		imageName = @"Cloud-Drizzle";
		backgroundImageName = @"Background-Glow-Night";
	} else if ([conditionCode isEqualToString:@"10d"]) { //rain
		imageName = @"Raindrop-Tile-Heavy";
		backgroundImageName = @"Background-Glow-Day";
	} else if ([conditionCode isEqualToString:@"10n"]) {
		imageName = @"Raindrop-Tile-Heavy";
		backgroundImageName = @"Background-Glow-Night";
	} else if ([conditionCode isEqualToString:@"11d"]) { //thunderstorms
		imageName = @"Thunderstorm-Main-Day";
		backgroundImageName = @"Background-Glow-Day";
	} else if ([conditionCode isEqualToString:@"11n"]) {
		imageName = @"Thunderstorm-Main-Night";
		backgroundImageName = @"Background-Glow-Night";
	} else if ([conditionCode isEqualToString:@"13d"]) { //snow
		imageName = @"Wintery-Mix-Flake-7x7";
		backgroundImageName = @"Background-Glow-Day";
	} else if ([conditionCode isEqualToString:@"13n"]) {
		imageName = @"Wintery-Mix-Flake-7x7";
		backgroundImageName = @"Background-Glow-Night";
	} else { //fog or mist
		imageName = @"Cirrus-Three-Overlap";
		if ([conditionCode isEqualToString:@"50d"]) {
			backgroundImageName = @"Background-Glow-Day";
		} else {
			backgroundImageName = @"Background-Glow-Night";
		}
	}

	RWLog(@"IMAGENAME: %@ BACKGROUNDIMAGENAME: %@",imageName,backgroundImageName);
	UIImageView *bgView = [[UIImageView alloc] initWithImage:[self _bitmapImageForName:backgroundImageName inRect:rect]];
	if ([conditionCode containsString:@"n"]) {
		[bgView setBackgroundColor:[UIColor colorWithRed:0.09 green:0.10 blue:0.20 alpha:1.00]];
	} else {
		[bgView setBackgroundColor:[UIColor colorWithRed:0.20 green:0.57 blue:0.75 alpha:1.00]];
	}
	if (imageName != nil) {
		UIImageView *weatherImg = [[UIImageView alloc] initWithImage:[self _bitmapImageForName:imageName inRect:rect]];
		[weatherImg setBackgroundColor:[UIColor clearColor]];
		[bgView addSubview:weatherImg];
	}

	return bgView;
}

-(UIImage*)_bitmapImageForName:(NSString*)imageName inRect:(CGRect)rect {
	NSString *path = [kRWWeatherFrameworkPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.cpbitmap",imageName]];
	NSData *data = [NSData dataWithContentsOfFile:path];
	NSAssert(data, @"no data found");

	UInt32 width;
	UInt32 height;
	[data getBytes:&width  range:NSMakeRange([data length] - sizeof(UInt32) * 5, sizeof(UInt32))];
	[data getBytes:&height range:NSMakeRange([data length] - sizeof(UInt32) * 4, sizeof(UInt32))];

	CGImageRef imageRef = CGImageCreateWithImageInRect([[self imageForBitmapData:data size:CGSizeMake(width, height)] CGImage], rect);
	UIImage *img = [UIImage imageWithCGImage:imageRef]; 
	CGImageRelease(imageRef);
	return img;
}

- (UIImage*)imageForBitmapData:(NSData *)data size:(CGSize)size
{
    void *          bitmapData;
    CGColorSpaceRef colorSpace        = CGColorSpaceCreateDeviceRGB();
    int             bitmapBytesPerRow = (size.width * 4);
    int             bitmapByteCount   = (bitmapBytesPerRow * size.height);

    bitmapData = malloc( bitmapByteCount );
    NSAssert(bitmapData, @"Unable to create buffer");

    [data getBytes:bitmapData length:bitmapByteCount];

    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bitmapData, bitmapByteCount, releasePixels);

    CGImageRef imageRef = CGImageCreate(size.width,
                                        size.height,
                                        8,
                                        32,
                                        bitmapBytesPerRow,
                                        colorSpace,
                                        (CGBitmapInfo)kCGImageAlphaLast,
                                        provider,
                                        NULL,
                                        NO,
                                        kCGRenderingIntentDefault);

    UIImage *image = [UIImage imageWithCGImage:imageRef];

    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);

    return image;
}

void releasePixels(void *info, const void *data, size_t size)
{
    free((void*)data);
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