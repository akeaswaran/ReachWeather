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

    	NSInteger highTemp = [self kelvinToLocalTemp:[dayData[@"temp"][@"day"] doubleValue]];
		NSInteger lowTemp = [self kelvinToLocalTemp:[dayData[@"temp"][@"night"] doubleValue]];

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

- (UIView*)forecastViewForDayCount:(NSInteger)dayCount {
	CGRect containerFrame = [[RWWeatherController sharedInstance] forecastsContainerFrame];
	UIView *dayView = [[UIView alloc] initWithFrame:CGRectMake(0,0,containerFrame.size.width / dayCount,containerFrame.size.height)];

	UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,0,dayView.frame.size.width,20.0)];
	[dateLabel setFont:[UIFont systemFontOfSize:14.0]];
	[dateLabel setTextAlignment:NSTextAlignmentCenter];
	[dateLabel setTextColor:[self setDetailColor]];
	[dateLabel setText:_date];

	UILabel *highLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,dateLabel.frame.size.height + 4.0,dayView.frame.size.width,32.0)];
	[highLabel setFont:[UIFont systemFontOfSize:28.0]];
	[highLabel setTextAlignment:NSTextAlignmentCenter];
	[highLabel setTextColor:[self setTitleColor]];
	[highLabel setText:_highTemperature];

	UILabel *lowLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,highLabel.frame.origin.y + highLabel.frame.size.height + 4.0,dayView.frame.size.width,26.0)];
	[lowLabel setFont:[UIFont systemFontOfSize:22.0]];
	[lowLabel setTextAlignment:NSTextAlignmentCenter];
	[lowLabel setTextColor:[self setTitleColor]];
	[lowLabel setText:_lowTemperature];

	UILabel *conditionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0,lowLabel.frame.origin.y + lowLabel.frame.size.height + 4.0, dayView.frame.size.width,20.0)];
	[conditionLabel setFont:[UIFont systemFontOfSize:14.0]];
	[conditionLabel setTextAlignment:NSTextAlignmentCenter];
	[conditionLabel setTextColor:[self setDetailColor]];
	[conditionLabel setText:_condition];

	[dayView addSubview:dateLabel];
	[dayView addSubview:highLabel];
	[dayView addSubview:lowLabel];
	[dayView addSubview:conditionLabel];

	return dayView;
}

@end