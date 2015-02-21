//RWWeatherController.h

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Headers.h"

typedef void (^RWWeatherCompletionBlock)(NSDictionary *result, NSError *error);
typedef void (^RWForecastCompletionBlock)(NSArray *results, NSError *error);

@interface RWWeatherController : UIViewController <UIScrollViewDelegate, CLLocationManagerDelegate> {
	SBWindow *backgroundWindow;
	UIImageView *widgetBackgroundView;
	UIView *widgetContainerView;
	NSMutableArray *widgets;
	UIActivityIndicatorView *loadingSpinner;

	NSString *currentWeatherCondition;
	NSString *temperatureCondition;
	NSString *highTempCondition;
	NSString *lowTempCondition;
	NSString *pressureCondition;
	NSString *humidityCondition;
	NSString *curCity;
	NSString *curIconCode;

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

	CLLocationManager *locationManager;
	BOOL isUpdating;
}

+ (instancetype)sharedInstance;
+ (BOOL)isActivatorInstalled;

-(void)activateWidgetArea;
-(void)setBackgroundWindow:(SBWindow*)window;
-(CGRect)forecastsContainerFrame;
-(void)setupWidget;
-(void)deconstructWidget;

@end