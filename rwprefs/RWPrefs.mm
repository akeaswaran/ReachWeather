//RWPrefs.m
#import "RWPrefs.h"
#import "../Headers.h"
#import <UIKit/UIKit.h>

@implementation RWPrefsListController

-(NSString*)localizedStringWithKey:(NSString*)key {
  NSBundle *tweakBundle = [NSBundle bundleWithPath:kRWBundlePath];
  return [tweakBundle localizedStringForKey:key value:@"" table:nil];
}

- (id)specifiers {
	if (_specifiers == nil) {
        NSMutableArray *specifiers = [[NSMutableArray alloc] init];
        
        [self setTitle:@"ReachWeather"];
        
        PSSpecifier *firstGroup = [PSSpecifier groupSpecifierWithName:[self localizedStringWithKey:@"TWEAK_OPTIONS"]];
        [firstGroup setProperty:[self localizedStringWithKey:@"TWEAK_OPTIONS_DETAIL"] forKey:@"footerText"];
        
        PSSpecifier *enabled = [PSSpecifier preferenceSpecifierNamed:@"Enabled"
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [enabled setIdentifier:kRWEnabledKey];
        [enabled setProperty:@(YES) forKey:@"enabled"];
        
        PSSpecifier *manualControl = [PSSpecifier preferenceSpecifierNamed:[self localizedStringWithKey:@"MANUAL_CONTROL"]
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [manualControl setIdentifier:kRWManualControlKey];
        [manualControl setProperty:@(YES) forKey:@"enabled"];

        PSSpecifier *secondGroup = [PSSpecifier groupSpecifierWithName:[self localizedStringWithKey:@"CUSTOMIZATION"]];
        [secondGroup setProperty:[self localizedStringWithKey:@"CUSTOMIZATION_DETAIL"] forKey:@"footerText"];

        PSTextFieldSpecifier *cityField = [PSTextFieldSpecifier preferenceSpecifierNamed:[self localizedStringWithKey:@"CITY"] target:self set:@selector(setValue:forSpecifier:) get:@selector(getValueForSpecifier:) detail:Nil cell:PSEditTextCell edit:Nil];
        [cityField setPlaceholder:[self localizedStringWithKey:@"YOUR_CITY"]];
        [cityField setIdentifier:kRWCityKey];
        [cityField setProperty:@(YES) forKey:@"enabled"];
        [cityField setKeyboardType:UIKeyboardTypeASCIICapable autoCaps:UITextAutocapitalizationTypeWords autoCorrection:UITextAutocorrectionTypeYes];

        PSSpecifier *mainColorSwitch = [PSSpecifier preferenceSpecifierNamed:[self localizedStringWithKey:@"CUSTOM_TITLE_COLOR"]
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [mainColorSwitch setIdentifier:kRWTitleColorSwitchKey];
        [mainColorSwitch setProperty:@(YES) forKey:@"enabled"];

        PSTextFieldSpecifier *mainColorField = [PSTextFieldSpecifier preferenceSpecifierNamed:nil target:self set:@selector(setValue:forSpecifier:) get:@selector(getValueForSpecifier:) detail:Nil cell:PSEditTextCell edit:Nil];
        [mainColorField setPlaceholder:[self localizedStringWithKey:@"HEX_CODE"]];
        [mainColorField setIdentifier:kRWTitleColorKey];
        [mainColorField setProperty:@(YES) forKey:@"enabled"];
        [mainColorField setKeyboardType:UIKeyboardTypeASCIICapable autoCaps:UITextAutocapitalizationTypeAllCharacters autoCorrection:UITextAutocorrectionTypeNo];

        PSSpecifier *infoColorSwitch = [PSSpecifier preferenceSpecifierNamed:[self localizedStringWithKey:@"CUSTOM_DETAIL_COLOR"]
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [infoColorSwitch setIdentifier:kRWDetailColorSwitchKey];
        [infoColorSwitch setProperty:@(YES) forKey:@"enabled"];

        PSTextFieldSpecifier *infoColorField = [PSTextFieldSpecifier preferenceSpecifierNamed:nil target:self set:@selector(setValue:forSpecifier:) get:@selector(getValueForSpecifier:) detail:Nil cell:PSEditTextCell edit:Nil];
        [infoColorField setPlaceholder:[self localizedStringWithKey:@"HEX_CODE"]];
        [infoColorField setIdentifier:kRWDetailColorKey];
        [infoColorField setProperty:@(YES) forKey:@"enabled"];
        [infoColorField setKeyboardType:UIKeyboardTypeASCIICapable autoCaps:UITextAutocapitalizationTypeAllCharacters autoCorrection:UITextAutocorrectionTypeNo];

        PSSpecifier *thirdGroup = [PSSpecifier groupSpecifierWithName:@"UI Options"];
        [thirdGroup setProperty:[self localizedStringWithKey:@"WEATHER_IMAGES_DETAIL"] forKey:@"footerText"];

        PSSpecifier *centerEnabled = [PSSpecifier preferenceSpecifierNamed:[self localizedStringWithKey:@"CENTER_WEATHER_VIEW"]
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [centerEnabled setIdentifier:kRWCenterMainViewKey];
        [centerEnabled setProperty:@(YES) forKey:@"enabled"];

        PSSpecifier *detailedEnabled = [PSSpecifier preferenceSpecifierNamed:[self localizedStringWithKey:@"ENABLE_DETAIL_PAGE"]
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [detailedEnabled setIdentifier:kRWDetailedViewKey];
        [detailedEnabled setProperty:@(YES) forKey:@"enabled"];

        PSSpecifier *clockEnabled = [PSSpecifier preferenceSpecifierNamed:[self localizedStringWithKey:@"ENABLE_CLOCK_PAGE"]
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [clockEnabled setIdentifier:kRWClockViewKey];
        [clockEnabled setProperty:@(YES) forKey:@"enabled"];

        PSSpecifier *forecastEnabled = [PSSpecifier preferenceSpecifierNamed:[self localizedStringWithKey:@"ENABLE_FORECAST_PAGE"]
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [forecastEnabled setIdentifier:kRWForecastViewKey];
        [forecastEnabled setProperty:@(YES) forKey:@"enabled"];

        PSSpecifier *forecastType = [PSSpecifier preferenceSpecifierNamed:[self localizedStringWithKey:@"FORECAST_TYPE"]
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:[RWForecastTypesListController class]
                                                                cell:PSLinkListCell
                                                                edit:Nil];
        [forecastType setIdentifier:kRWForecastTypeKey];
        [forecastType setValues:[self forecastTypeValues] titles:[self forecastTypeTitles]];
        [forecastType setProperty:@(YES) forKey:@"enabled"];

        PSSpecifier *celsius = [PSSpecifier preferenceSpecifierNamed:[self localizedStringWithKey:@"USE_CELSIUS"]
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [celsius setIdentifier:kRWCelsiusEnabledKey];
        [celsius setProperty:@(YES) forKey:@"enabled"];

        PSSpecifier *weatherImages = [PSSpecifier preferenceSpecifierNamed:[self localizedStringWithKey:@"ENABLE_WEATHER_IMAGES"]
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:Nil
                                                                cell:PSSwitchCell
                                                                edit:Nil];
        [weatherImages setIdentifier:kRWWeatherImagesKey];
        [weatherImages setProperty:@(YES) forKey:@"enabled"];
               
        PSSpecifier *fourthGroup = [PSSpecifier groupSpecifierWithName:[self localizedStringWithKey:@"LOCALIZATION"]];

        PSSpecifier *language = [PSSpecifier preferenceSpecifierNamed:[self localizedStringWithKey:@"LANGUAGE"]
                                                              target:self
                                                                 set:@selector(setValue:forSpecifier:)
                                                                 get:@selector(getValueForSpecifier:)
                                                              detail:[RWLanguagesListController class]
                                                                cell:PSLinkListCell
                                                                edit:Nil];
        [language setIdentifier:kRWLanguageKey];
        [language setValues:[self languageValues] titles:[self languageTitles]];
        [language setProperty:@(YES) forKey:@"enabled"];


        PSSpecifier *fifthGroup = [PSSpecifier groupSpecifierWithName:[self localizedStringWithKey:@"THIRD_PARTY"]];

        PSSpecifier *hexClrs = [PSSpecifier preferenceSpecifierNamed:@"HexColors"
                                                              target:self
                                                                 set:nil
                                                                 get:nil
                                                              detail:Nil
                                                                cell:PSLinkCell
                                                                edit:Nil];
        hexClrs.name = @"HexColors";
        hexClrs->action = @selector(openHexColors);
        [hexClrs setIdentifier:@"hexClrs"];
        [hexClrs setProperty:@(YES) forKey:@"enabled"];
        
        PSSpecifier *icons8 = [PSSpecifier preferenceSpecifierNamed:@"Icons8"
                                                              target:self
                                                                 set:nil
                                                                 get:nil
                                                              detail:Nil
                                                                cell:PSLinkCell
                                                                edit:Nil];
        icons8.name = @"Icons8";
        icons8->action = @selector(openIcons8);
        [icons8 setIdentifier:@"icons8"];
        [icons8 setProperty:@(YES) forKey:@"enabled"];

        PSSpecifier *sixthGroup = [PSSpecifier groupSpecifierWithName:[self localizedStringWithKey:@"DEVELOPER"]];
        [sixthGroup setProperty:[self localizedStringWithKey:@"DEVELOPER_DETAIL"] forKey:@"footerText"];
        
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
        [specifiers addObject:manualControl];

        [specifiers addObject:secondGroup];
        [specifiers addObject:cityField];
        [specifiers addObject:mainColorSwitch];
        [specifiers addObject:mainColorField];
        [specifiers addObject:infoColorSwitch];
        [specifiers addObject:infoColorField];

        [specifiers addObject:thirdGroup];
        [specifiers addObject:clockEnabled];
        [specifiers addObject:centerEnabled];
        [specifiers addObject:detailedEnabled];
        [specifiers addObject:forecastEnabled];
        [specifiers addObject:forecastType];
        [specifiers addObject:celsius];
        [specifiers addObject:weatherImages];

        [specifiers addObject:fourthGroup];
        [specifiers addObject:language];

        [specifiers addObject:fifthGroup];
        [specifiers addObject:hexClrs];
        [specifiers addObject:icons8];
        
        [specifiers addObject:sixthGroup];
        [specifiers addObject:github];

        _specifiers = specifiers;
    }
    
    return _specifiers;
}

- (id)getValueForSpecifier:(PSSpecifier *)specifier
{
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kRWSettingsPath];
    if (settings[specifier.identifier] && ![specifier.identifier isEqual:kRWCityKey] && ![specifier.identifier isEqual:kRWLanguageKey] && ![specifier.identifier isEqual:kRWForecastTypeKey] && ![specifier.identifier isEqual:kRWTitleColorKey] && ![specifier.identifier isEqual:kRWDetailColorKey]) {
        NSNumber *settingEnabled = settings[specifier.identifier];
        if (settingEnabled.intValue == 1) {
            return [NSNumber numberWithBool:YES];
        } else {
            return [NSNumber numberWithBool:NO];
        }
    } else {
        if ([specifier.identifier isEqual:kRWCityKey]) {
            if ([settings[kRWCityKey] isEqualToString:@""]) {
                return @"New York";
            } else {
                return [settings objectForKey:kRWCityKey];
            }
        } else if ([specifier.identifier isEqual:kRWLanguageKey]) {
            if ([settings[kRWLanguageKey] isEqualToString:@""]) {
                return @"en";
            } else {
                return [settings objectForKey:kRWLanguageKey];
            }
        } else if ([specifier.identifier isEqual:kRWForecastTypeKey]) {
            if ([settings[kRWForecastTypeKey] isEqualToString:@""]) {
                return @"3";
            } else {
                return [settings objectForKey:kRWForecastTypeKey];
            }
        } else if ([specifier.identifier isEqual:kRWTitleColorKey]) {
            if ([settings[kRWTitleColorKey] isEqualToString:@""]) {
                return @"#FFFFFF";
            } else {
                return [settings objectForKey:kRWTitleColorKey];
            }
        } else {
            if ([settings[kRWDetailColorKey] isEqualToString:@""]) {
                return @"#AAAAAA";
            } else {
                return [settings objectForKey:kRWDetailColorKey];
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

- (void)openIcons8
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://icons8.com/license"]];
}

- (void)openHexColors
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/mRs-/HexColors"]];
}

- (NSArray *)languageTitles {
    return @[@"English",@"Russian",@"Italian",@"Spanish",@"Ukrainian",@"German",@"Portugese",@"Romanian",@"Polish",@"Finnish",@"Dutch",@"French",@"Bulgarian",@"Swedish",@"Chinese Traditional",@"Chinese Simplified",@"Turkish",@"Croatian",@"Catalan"];
}

- (NSArray *)languageValues {
    return @[@"en",@"ru",@"it",@"es",@"uk",@"de",@"pt",@"ro",@"pl",@"fi",@"nl",@"fr",@"bg",@"sv",@"zh_tw",@"zh_cn",@"tr",@"hr",@"ca"];
}

- (NSArray *)forecastTypeTitles {
  return @[[self localizedStringWithKey:@"THREE_DAY"], [self localizedStringWithKey:@"FIVE_DAY"]];
}

- (NSArray *)forecastTypeValues {
  return @[@"3",@"5"];
}

@end

@implementation RWLanguagesListController

@end

@implementation RWForecastTypesListController

@end
