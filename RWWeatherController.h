//RWWeatherController.h

#import <UIKit/UIKit.h>
#import "Headers.h"

typedef void (^RWWeatherCompletionBlock)(NSDictionary *result, NSError *error);

@interface RWWeatherController : UIViewController <UIScrollViewDelegate> {
	
	SBWindow *backgroundWindow;
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
}

+(instancetype)sharedInstance;
-(void)setBackgroundWindow:(SBWindow*)window;
-(void)setupWidget;
-(void)deconstructWidget;

@end