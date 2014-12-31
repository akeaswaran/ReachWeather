//RWWeatherController.h

#import <UIKit/UIKit.h>
#import "Headers.h"

typedef void (^RWWeatherCompletionBlock)(NSDictionary *result, NSError *error);
typedef void (^RWForecastCompletionBlock)(NSArray *results, NSError *error);

@interface RWWeatherController : UIViewController <UIScrollViewDelegate> {
	SBWindow *backgroundWindow;
	UIImageView *widgetBackgroundView;
	NSString *curIconCode;
	UIView *widgetContainerView;
	NSMutableArray *widgets;

	NSString *currentWeatherCondition;
	NSString *temperatureCondition;
	NSString *highTempCondition;
	NSString *lowTempCondition;
	NSString *pressureCondition;
	NSString *humidityCondition;

	UILabel *cityLabel;
	UILabel *temperatureLabel;
	UILabel *weatherDescriptionLabel;

	UIPageControl *pageControl;
	UILabel *highLabel;
	UILabel *lowLabel;
	UILabel *pressureLabel;
	UILabel *humidityLabel;

	UILabel *timeLabel;
	NSTimer *dateTimer;

	NSArray *forecasts;
}

+ (instancetype)sharedInstance;
+ (BOOL)isActivatorInstalled;

-(void)activateWidgetArea;
-(void)setBackgroundWindow:(SBWindow*)window;
-(CGRect)forecastsContainerFrame;
-(void)setupWidget;
-(void)deconstructWidget;

@end