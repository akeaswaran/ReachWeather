//RWForecast.m
#import "RWForecast.h"
#import "RWWeatherController.h"
#import "HexColor.h"
#import <QuartzCore/QuartzCore.h>

@implementation RWForecast

- (instancetype)initWithDictionary:(NSDictionary *)dayData {
	
	RWLog(@"INITIALIZING RWFORECAST WITH DICT: %@",dayData);

	self = [super init];
    if (self) {
    	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
		NSNumber *celsiusNum = settings[kRWCelsiusEnabledKey];
		BOOL celsiusEnabled = celsiusNum ? [celsiusNum boolValue] : 0;

    	NSInteger highTemp = [self kelvinToLocalTemp:[dayData[@"temp"][@"max"] doubleValue]];
		NSInteger lowTemp = [self kelvinToLocalTemp:[dayData[@"temp"][@"min"] doubleValue]];

		if (!highTemp || !lowTemp) {
			_highTemperature = @"--\u00B0C";
			_lowTemperature = @"--\u00B0C";
		} else {
			if (celsiusEnabled) {
				_highTemperature = [NSString stringWithFormat:@"%ld\u00B0C",(long)highTemp];
				_lowTemperature = [NSString stringWithFormat:@"%ld\u00B0C",(long)lowTemp];
		    } else {
				_highTemperature = [NSString stringWithFormat:@"%ld\u00B0F",(long)highTemp];
				_lowTemperature = [NSString stringWithFormat:@"%ld\u00B0F",(long)lowTemp];
		    }
		}

	    CGFloat unixTime = [dayData[@"dt"] doubleValue];
	    _date = [self stringFromUnixDate:unixTime];

	    NSArray *weatherItems = dayData[@"weather"];
	    NSDictionary *weather = weatherItems[0];
	    _condition = weather[@"main"];

	    _conditionCode = weather[@"icon"];
 	}
    return self;
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

-(NSString*)stringFromUnixDate:(CGFloat)unixTimestamp {
	NSTimeInterval timeInterval = unixTimestamp;
	NSDate *unixDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
	NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
	NSDateComponents *dateComponents = [calendar components:( NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear ) fromDate:unixDate];

	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setMonth:[dateComponents month]];
	[comps setDay:[dateComponents day]];
	[comps setYear:[dateComponents year]];
	NSDate* date = [calendar dateFromComponents:comps];
	return [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
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


-(UIImage*)_weatherImageForConditionCode {
	NSString *imageName;
	RWLog(@"CONDITION CODE: %@",_conditionCode);

	if ([_conditionCode isEqualToString:@"01d"] || [_conditionCode isEqualToString:@"01n"]) { //sunny
		imageName = @"mostly-sunny";
	} else if ([_conditionCode isEqualToString:@"02d"] || [_conditionCode isEqualToString:@"02n"]) { //partly cloudy
		imageName = @"partly-cloudy";
	} else if ([_conditionCode isEqualToString:@"03d"] || [_conditionCode isEqualToString:@"03n"] || [_conditionCode isEqualToString:@"04d"] || [_conditionCode isEqualToString:@"04n"]) { //mostly cloudy
		imageName = @"mostly-cloudy";
	} else if ([_conditionCode isEqualToString:@"09d"] || [_conditionCode isEqualToString:@"09n"]) { //showers
		imageName = @"showers";
	} else if ([_conditionCode isEqualToString:@"10d"] || [_conditionCode isEqualToString:@"10n"]) { //rain
		imageName = @"rain";
	} else if ([_conditionCode isEqualToString:@"11d"] || [_conditionCode isEqualToString:@"11n"]) { //thunderstorms
		imageName = @"storm";
	} else if ([_conditionCode isEqualToString:@"13d"] || [_conditionCode isEqualToString:@"13n"]) { //snow
		imageName = @"snow";
	} else {
		imageName = @"foggy"; //fog
	}

	NSString *imagePath = [kRWBundlePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",imageName]];
	return [UIImage imageWithContentsOfFile:imagePath];
}

-(BOOL)_imageBundleExists {
	if ([[NSFileManager defaultManager] fileExistsAtPath:kRWBundlePath]) {
		RWLog(@"WEATHER.FRAMEWORK EXISTS, USING IMAGES");
		return YES;
	} else {
		RWLog(@"WEATHER.FRAMEWORK DOES NOT EXIST, USING TEXT");
		return NO;
	}
}

- (UIView*)forecastViewForDayCount:(NSInteger)dayCount {
	CGRect containerFrame = [[RWWeatherController sharedInstance] forecastsContainerFrame];
	CGFloat highFontSize = 28.0;
	CGFloat lowFontSize = 22.0;
	if (IS_IPHONE_5) {
		highFontSize = 25.0;
		lowFontSize = 19.0;
	}

	UIView *dayView = [[UIView alloc] initWithFrame:CGRectMake(0,0,containerFrame.size.width / dayCount,containerFrame.size.height)];

	UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,dayView.frame.size.width,20.0)];
	[dateLabel setFont:[UIFont systemFontOfSize:14.0]];
	[dateLabel setTextAlignment:NSTextAlignmentCenter];
	[dateLabel setTextColor:[self settingsDetailColor]];
	[dateLabel setText:_date];
	[dayView addSubview:dateLabel];

	UIImageView *conditionImageView = [[UIImageView alloc] initWithImage:[self _weatherImageForConditionCode]];
	UIImage* originalImage = [self _weatherImageForConditionCode];
	[conditionImageView setContentMode:UIViewContentModeCenter];
	UIImage* imageForRendering = [originalImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	conditionImageView.image = imageForRendering;
	conditionImageView.tintColor = [self settingsDetailColor]; 
	CGRect frame = conditionImageView.frame;
	frame.origin.x = (dayView.frame.size.width / 2.0) - (frame.size.width / 2.0);
	frame.origin.y = dateLabel.frame.size.height + 4.0;
	conditionImageView.frame = frame;
	[dayView addSubview:conditionImageView];

	UILabel *highLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,conditionImageView.frame.origin.y + conditionImageView.frame.size.height + 4.0,dayView.frame.size.width,highFontSize + 4.0)];
	[highLabel setFont:[UIFont systemFontOfSize:highFontSize]];
	[highLabel setTextAlignment:NSTextAlignmentCenter];
	[highLabel setTextColor:[self settingsTitleColor]];
	[highLabel setText:_highTemperature];
	[dayView addSubview:highLabel];

	UILabel *lowLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,highLabel.frame.origin.y + highLabel.frame.size.height + 4.0,dayView.frame.size.width,lowFontSize + 4.0)];
	[lowLabel setFont:[UIFont systemFontOfSize:lowFontSize]];
	[lowLabel setTextAlignment:NSTextAlignmentCenter];
	[lowLabel setTextColor:[self settingsTitleColor]];
	[lowLabel setText:_lowTemperature];
	[dayView addSubview:lowLabel];
	
	return dayView;
}

@end