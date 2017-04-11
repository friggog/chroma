#import "Headers.h"

#define PreferencesChangedNotification "me.chewitt.chromaprefs.settingschanged"
#define PreferencesFilePath [NSString stringWithFormat:@"/var/mobile/Library/Preferences/me.chewitt.chromaprefs.plist"]

#define isCurrentApp(string) [[[NSBundle mainBundle] bundleIdentifier] isEqual : string]

static NSDictionary* preferences;
static NSDictionary* excludedApps;
static NSMutableArray* excludedAppsArray;
static UIColor* darkColour;
static UIColor* lightColour;
static BOOL enabled;

static UIColor *UIColorFromHexString(NSString* hexString) {
    unsigned rgbValue = 0;
    NSScanner* scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

static void updatePrefs() {
    preferences = [[NSDictionary alloc] initWithContentsOfFile:PreferencesFilePath];

    if ([preferences objectForKey:@"Colour"] != nil) {
        darkColour = UIColorFromHexString([preferences valueForKey:@"Colour"]);
    }
    else {
        darkColour = UIColorFromHexString(@"#007AFF");
    }

    if ([preferences objectForKey:@"LightColour"] != nil) {
        lightColour = UIColorFromHexString([preferences valueForKey:@"LightColour"]);
    }
    else {
        lightColour = UIColorFromHexString(@"#FFFFFF");
    }

    if ([preferences objectForKey:@"Enabled"] != nil) {
        enabled = [[preferences valueForKey:@"Enabled"] boolValue];
    }
    else {
        enabled = YES;
    }

    excludedApps = [[NSDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/me.chewitt.chromaprefs.excluded.plist"];
    excludedAppsArray = [NSMutableArray array];

    for (id key in excludedApps) {
        if ([[excludedApps valueForKey:key] boolValue] == YES) {
            [excludedAppsArray addObject:key];
        }
    }

    [[%c(UIApplication) sharedApplication] keyWindow];
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void* observer, CFStringRef name, const void* object, CFDictionaryRef userInfo) {
    updatePrefs();
}

%hook UIColor

+(id)systemBlueColor {
    return darkColour;
}

+(id) systemRedColor {
    if (enabled && (isCurrentApp(@"com.apple.mobilecal") || isCurrentApp(@"com.apple.mobiletimer")) ) {
        return darkColour;
    }
    else {
        return %orig;
    }
}/*
    +(id)systemGreenColor{
    if(enabled )
      return darkColour;
    else
      return %orig;
    }*/

+(id) systemOrangeColor {
    if (enabled  && ! isCurrentApp(@"com.apple.mobilemail")) {
        return darkColour;
    }
    else {
        return %orig;
    }
}

+(id) systemYellowColor {
    return lightColour;
}

+(id) systemTealColor {
    return lightColour;
}

+(id) systemPinkColor {
    return darkColour;
}

+(id) _systemInteractionTintColor {
    return darkColour;
}

+(id) _systemSelectedColor {
    return darkColour;
}

+(id) systemDarkRedColor {
    return darkColour;
}

+(id) systemDarkGreenColor {
    return darkColour;
}

+(id) systemDarkBlueColor {
    return darkColour;
}

+(id) systemDarkOrangeColor {
    return darkColour;
}

+(id) systemDarkTealColor {
    return darkColour;
}

+(id) systemDarkPinkColor {
    return darkColour;
}

+(id) systemDarkYellowColor {
    return darkColour;
}

+(id) externalSystemTealColor {
    return darkColour;
}

+(id) externalSystemRedColor {
    return darkColour;
}

+(id) externalSystemGreenColor {
    return darkColour;
}

+(id) tableCellBlueTextColor {
    return darkColour;
}

+(id) twitterColorTwitterBlue {
    return darkColour;
}

%end

%hook UIApplication

-(id)keyWindow {
    UIWindow* o = %orig;
    if (enabled  && ! isCurrentApp(@"com.apple.weather")) {
        if (isCurrentApp(@"com.apple.camera") || isCurrentApp(@"com.apple.facetime") || isCurrentApp(@"com.apple.Passbook") || isCurrentApp(@"com.apple.compass")) {       //[o.tintColor isEqual:[UIColor systemTealColor]] || [o.tintColor isEqual:[UIColor systemYellowColor]])
            [o setTintColor:lightColour];
        }
        else {
            [o setTintColor:darkColour];
        }
    }
    return o;
}

%end

%hook UISwitch

-(void)layoutSubviews {
    %orig;
    [self setOnTintColor:darkColour];
}
-(void) setOnTintColor:(id)col {
    %orig(darkColour);
}

%end

///////////////////////////////////   GC   /////////////////////////////////////

%hook GKColorPalette

- (id)emphasizedTextColor {
    return darkColour;
}
-(id) emphasizedTextOnDarkBackgroundColor {
    return darkColour;
}

-(id) systemInteractionColor {
    return darkColour;
}

%end

%hook GKUITheme

- (id)tabbarIconChallengesSelected : (BOOL)arg1 {
    return [%orig imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(id) tabbarIconFriendsSelected:(BOOL)arg1 {
    return [%orig imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(id) tabbarIconGamesSelected:(BOOL)arg1 {
    return [%orig imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(id) tabbarIconMeSelected:(BOOL)arg1 {
    return [%orig imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

-(id) tabbarIconTurnsSelected:(BOOL)arg1 {
    return [%orig imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

%end

/////////////////////////////////   Itunes   ///////////////////////////////////

%hook SUApplication
-(id)interactionTintColor {
    return darkColour;
}
%end

////////////////////////////////////////////////////////////////////////////////

%ctor {
    updatePrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PreferencesChangedCallback, CFSTR(PreferencesChangedNotification), NULL, CFNotificationSuspensionBehaviorCoalesce);
    if (! [excludedAppsArray containsObject:[[NSBundle mainBundle] bundleIdentifier]] && enabled) {
        %init;
    }
}
