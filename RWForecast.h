//RWForecast.h
#import <UIKit/UIKit.h>
#import "Headers.h"

@interface RWForecast : NSObject

@property (strong, nonatomic) NSString *highTemperature;
@property (strong, nonatomic) NSString *lowTemperature;
@property (strong, nonatomic) NSString *date;
@property (strong, nonatomic) NSString *condition;
@property (strong, nonatomic) NSString *conditionCode;

- (instancetype)initWithDictionary:(NSDictionary *)dayData;
- (UIView*)forecastViewForDayCount:(NSInteger)dayCount;
@end

