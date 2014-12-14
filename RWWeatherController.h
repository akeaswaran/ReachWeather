//RWWeatherController.h

#import <UIKit/UIKit.h>
#import "Headers.h"

typedef void (^RWWeatherCompletionBlock)(NSDictionary *result, NSError *error);

@interface RWWeatherController : UIViewController {
	SBWindow *backgroundWindow;
	NSString *currentWeatherCondition;
	NSString *temperatureCondition;
}

@property (strong, nonatomic) UILabel *cityLabel;
@property (strong, nonatomic) UILabel *temperatureLabel;
@property (strong, nonatomic) UILabel *weatherDescriptionLabel;

+(instancetype)sharedInstance;
-(void)setBackgroundWindow:(SBWindow*)window;
-(void)setupWidget;
-(void)deconstructWidget;

@end