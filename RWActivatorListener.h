//RWActivatorListener.h
#import <libactivator/libactivator.h>

@interface RWActivatorListener : NSObject <LAListener>
+(instancetype)sharedListener;
@end