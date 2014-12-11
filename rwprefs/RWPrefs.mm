#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTextFieldSpecifier.h>
#import <UIKit/UIKit.h>

#define kRWSettingsPath @"/var/mobile/Library/Preferences/me.akeaswaran.reachweather.plist"
#define kRWEnabledKey @"tweakEnabled"
#define kRWCityKey @"city"

@interface RWPrefsListController: PSListController {
}
@end

@implementation RWPrefsListController
- (id)specifiers {
	if (_specifiers == nil) {
        NSMutableArray *specifiers = [[NSMutableArray alloc] init];
        
        [self setTitle:@"ReachWeather"];
        
        PSSpecifier *firstGroup = [PSSpecifier groupSpecifierWithName:@"ReachWeather 0.0.1"];
        [firstGroup setProperty:@"© 2014 Akshay Easwaran" forKey:@"footerText"];
        
        PSSpecifier *enabled = [PSSpecifier preferenceSpecifierNamed:@"Enabled"
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [enabled setIdentifier:kRWEnabledKey];
        [enabled setProperty:@(YES) forKey:@"enabled"];

        PSTextFieldSpecifier *cityField = [PSTextFieldSpecifier preferenceSpecifierNamed:@"City" target:self set:@selector(setValue:forSpecifier:) get:@selector(getValueForSpecifier:) detail:Nil cell:PSEditTextCell edit:Nil];
        [cityField setPlaceholder:@"your city"];
        [cityField setIdentifier:kRWCityKey];
        [cityField setProperty:@(YES) forKey:@"enabled"];
        [cityField setKeyboardType:UIKeyboardTypeASCIICapable autoCaps:UITextAutocapitalizationTypeWords autoCorrection:UITextAutocorrectionTypeYes];
               

        PSSpecifier *secondGroup = [PSSpecifier groupSpecifierWithName:@"Developer"];
        [secondGroup setProperty:@"This tweak is open source. You can check out this and other projects on my GitHub." forKey:@"footerText"];
        
        PSSpecifier *github = [PSSpecifier preferenceSpecifierNamed:@"github"
                                                              target:self
                                                                 set:nil
                                                                 get:nil
                                                              detail:Nil
                                                                cell:PSLinkCell
                                                                edit:Nil];
        github.name = @"https://github.com/akeaswaran";
        github->action = @selector(openGithub);
        [github setIdentifier:@"github"];
        [github setProperty:@(YES) forKey:@"enabled"];
        [github setProperty:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/RWPrefs.bundle/github.png"] forKey:@"iconImage"];
        
        [specifiers addObject:firstGroup];
        [specifiers addObject:enabled];
        [specifiers addObject:cityField];
        [specifiers addObject:secondGroup];
        [specifiers addObject:github];
        _specifiers = specifiers;
    }
    
    return _specifiers;
}

- (id)getValueForSpecifier:(PSSpecifier *)specifier
{
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
    if (settings[specifier.identifier]) {
        NSNumber *settingEnabled = settings[specifier.identifier];
        if (settingEnabled.intValue == 1) {
            return [NSNumber numberWithBool:YES];
        } else {
            return [NSNumber numberWithBool:NO];
        }
    }
    return [NSNumber numberWithBool:NO];
}

- (void)setValue:(id)value forSpecifier:(PSSpecifier *)specifier
{
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath]];
    [defaults setObject:value forKey:specifier.identifier];
    [defaults writeToFile:kRWSettingsPath atomically:YES];

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("me.akeaswaran.reachweather/ReloadSettings"), NULL, NULL, YES);
}

- (void)openGithub
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/akeaswaran"]];
}

@end
