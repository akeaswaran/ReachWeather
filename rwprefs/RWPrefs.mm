
#import "RWPrefs.h"
#import <UIKit/UIKit.h>

#define kRWSettingsPath @"/var/mobile/Library/Preferences/me.akeaswaran.reachweather.plist"
#define kRWEnabledKey @"tweakEnabled"
#define kRWCityKey @"city"
#define kRWCelsiusEnabledKey @"celsiusEnabled"
#define kRWLanguageKey @"language"
#define kRWDetailedViewKey @"detailedView"
#define kRWManualControlKey @"manualControl"

@implementation RWPrefsListController
- (id)specifiers {
	if (_specifiers == nil) {
        NSMutableArray *specifiers = [[NSMutableArray alloc] init];
        
        [self setTitle:@"ReachWeather"];
        
        PSSpecifier *firstGroup = [PSSpecifier groupSpecifierWithName:@"Options"];
        [firstGroup setProperty:@"Manual Control disables the reset timer on Reachability, keeping the view open indefinitely until you close it manually." forKey:@"footerText"];
        
        PSSpecifier *enabled = [PSSpecifier preferenceSpecifierNamed:@"Enabled"
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [enabled setIdentifier:kRWEnabledKey];
        [enabled setProperty:@(YES) forKey:@"enabled"];

        PSSpecifier *celsius = [PSSpecifier preferenceSpecifierNamed:@"Use Celsius?"
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [celsius setIdentifier:kRWCelsiusEnabledKey];
        [celsius setProperty:@(YES) forKey:@"enabled"];

        PSSpecifier *detailedEnabled = [PSSpecifier preferenceSpecifierNamed:@"Detailed View"
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [detailedEnabled setIdentifier:kRWDetailedViewKey];
        [detailedEnabled setProperty:@(YES) forKey:@"enabled"];
        
        PSSpecifier *manualControl = [PSSpecifier preferenceSpecifierNamed:@"Manual Control"
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [manualControl setIdentifier:kRWManualControlKey];
        [manualControl setProperty:@(YES) forKey:@"enabled"];

        PSSpecifier *secondGroup = [PSSpecifier groupSpecifierWithName:@"Customization"];
        [secondGroup setProperty:@"Enter the name of the city how it's written (including spaces and special characters). No need to capitalize or abbreviate." forKey:@"footerText"];

        PSTextFieldSpecifier *cityField = [PSTextFieldSpecifier preferenceSpecifierNamed:@"City" target:self set:@selector(setValue:forSpecifier:) get:@selector(getValueForSpecifier:) detail:Nil cell:PSEditTextCell edit:Nil];
        [cityField setPlaceholder:@"your city"];
        [cityField setIdentifier:kRWCityKey];
        [cityField setProperty:@(YES) forKey:@"enabled"];
        [cityField setKeyboardType:UIKeyboardTypeASCIICapable autoCaps:UITextAutocapitalizationTypeWords autoCorrection:UITextAutocorrectionTypeYes];
               
        PSSpecifier *thirdGroup = [PSSpecifier groupSpecifierWithName:@"Localization"];

        PSSpecifier *language = [PSSpecifier preferenceSpecifierNamed:@"Language"
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:[RWLanguagesListController class]
                                                                cell:PSLinkListCell
                                                                edit:Nil];
        [language setIdentifier:kRWLanguageKey];
        [language setValues:[self languageValues] titles:[self languageTitles]];
        [language setProperty:@(YES) forKey:@"enabled"];


        PSSpecifier *fourthGroup = [PSSpecifier groupSpecifierWithName:@"Developer"];
        [fourthGroup setProperty:@"This tweak is open source. You can check out this and other projects on my GitHub." forKey:@"footerText"];
        
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
        [specifiers addObject:celsius];
        [specifiers addObject:detailedEnabled];
        [specifiers addObject:manualControl];

        [specifiers addObject:secondGroup];
        [specifiers addObject:cityField];

        [specifiers addObject:thirdGroup];
        [specifiers addObject:language];
        
        [specifiers addObject:fourthGroup];
        [specifiers addObject:github];
        _specifiers = specifiers;
    }
    
    return _specifiers;
}

- (id)getValueForSpecifier:(PSSpecifier *)specifier
{
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
    if (settings[specifier.identifier] && ![specifier.identifier isEqual:kRWCityKey] && ![specifier.identifier isEqual:kRWLanguageKey]) {
        NSNumber *settingEnabled = settings[specifier.identifier];
        if (settingEnabled.intValue == 1) {
            return [NSNumber numberWithBool:YES];
        } else {
            return [NSNumber numberWithBool:NO];
        }
    } else {
        if ([specifier.identifier isEqual:kRWCityKey]) {
            if ([settings[kRWCityKey] isEqualToString:@""]) {
                return nil;
            } else {
                return [settings objectForKey:kRWCityKey];
            }
        } else {
            if ([settings[kRWLanguageKey] isEqualToString:@""]) {
                return nil;
            } else {
                return [settings objectForKey:kRWLanguageKey];
            }
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

- (NSArray *)languageTitles {
    return @[@"English",@"Russian",@"Italian",@"Spanish",@"Ukrainian",@"German",@"Portugese",@"Romanian",@"Polish",@"Finnish",@"Dutch",@"French",@"Bulgarian",@"Swedish",@"Chinese Traditional",@"Chinese Simplified",@"Turkish",@"Croatian",@"Catalan"];
}

- (NSArray *)languageValues {
    return @[@"en",@"ru",@"it",@"es",@"uk",@"de",@"pt",@"ro",@"pl",@"fi",@"nl",@"fr",@"bg",@"sv",@"zh_tw",@"zh_cn",@"tr",@"hr",@"ca"];
}

@end

@implementation RWLanguagesListController

@end
