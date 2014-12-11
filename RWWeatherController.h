//RWWeatherController.h

#import <UIKit/UIKit.h>
#import "Headers.h"

typedef void (^RWWeatherCompletionBlock)(NSDictionary *result, NSError *error);

@interface RWWeatherController : UIViewController {
	SBWindow *backgroundWindow;
}
@property (strong, nonatomic) UIImageView *weatherImageView;
@property (strong, nonatomic) UILabel *cityLabel;
@property (strong, nonatomic) UILabel *temperatureLabel;
@property (strong, nonatomic) UILabel *weatherDescriptionLabel;
@property (strong, nonatomic) UILabel *dateTimeLabel;

+(instancetype)sharedInstance;
-(void)setupWidget;
-(void)deconstructWidget;
-(void)setBackgroundWindow:(SBWindow*)window;

@end