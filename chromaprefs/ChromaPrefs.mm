#import <Preferences/Preferences.h>
#import <Social/Social.h>
#import <MessageUI/MessageUI.h>
#import <sys/utsname.h>
#import "ColorPicker/HRColorPickerView.h"
#import "CircleViews.h"

#define TWEAK_VERSION @"1.5.1"
#define prefsPath @"/User/Library/Preferences/me.chewitt.chromaprefs.plist"

NSInteger system_nd(const char* command) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    return system(command);
#pragma GCC diagnostic pop
}

static BOOL iPad = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;

NSString *machineName() {
    struct utsname systemInfo;
    uname(&systemInfo);

    return [NSString stringWithCString:systemInfo.machine
            encoding:NSUTF8StringEncoding];
}

static UIColor *UIColorFromHexString(NSString* hexString) {
    unsigned rgbValue = 0;
    NSScanner* scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

static NSString *HexStringFromUIColor(UIColor* colour) {
    CGFloat r, g, b, a;
    [colour getRed:&r green:&g blue:&b alpha:&a];
    int rgb = (NSInteger)(r * 255.0f)<<16 | (int)(g * 255.0f)<<8 | (int)(b * 255.0f)<<0;
    return [NSString stringWithFormat:@"#%06x", rgb];
}

@interface ChromaPrefsListController:PSListController <MFMailComposeViewControllerDelegate, UIAlertViewDelegate>
-(void) showDisableAlert;
@end

@implementation ChromaPrefsListController
-(id) specifiers {
    if (_specifiers == nil) {
        UIBarButtonItem* likeButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/ChromaPrefs.bundle/heart.png"] style:UIBarButtonItemStylePlain target:self action:@selector(composeTweet)];
        ((UINavigationItem*)self.navigationItem).rightBarButtonItem = likeButton;
        _specifiers = [self loadSpecifiersFromPlistName:@"ChromaPrefs" target:self];

        PSSpecifier* copyright = [self specifierForID:@"copyright"];
        NSString* footer = [copyright propertyForKey:@"footerText"];
        footer = [footer stringByReplacingOccurrencesOfString:@"$" withString:TWEAK_VERSION];
        [copyright setProperty:footer forKey:@"footerText"];
    }
    return _specifiers;
}

-(void) viewWillAppear:(BOOL)b {
    [super viewWillAppear:b];
    [self reloadSpecifier:[self specifierForID:@"LightTint"]];
    [self reloadSpecifier:[self specifierForID:@"DarkTint"]];
}

-(void) goToTinct {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://package/me.chewitt.tinct"]];
}


-(void) composeTweet {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        SLComposeViewController* tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        NSString* device = @"iPhone";
        if (iPad) {
            device = @"iPad";
        }
        [tweetSheet setInitialText:[NSString stringWithFormat:@"I'm using Chroma (by @friggog) to customise my %@'s UI!", device]];
        UIViewController* rootViewController = (UIViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
        [rootViewController presentViewController:tweetSheet animated:YES completion:nil];
    }
    else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
                              message:@"Unable to tweet at this time."
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    }
}

-(void) openEmailLink {
    NSString* currSysVer = [[UIDevice currentDevice] systemVersion];
    NSString* device = machineName();

    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController* picker = [[MFMailComposeViewController alloc] init];
        picker.mailComposeDelegate = self;
        [picker setSubject:[NSString stringWithFormat:@"Chroma %@ - %@ : %@", TWEAK_VERSION, device, currSysVer]];

        NSArray* toRecipients = [NSArray arrayWithObject:@"contact@chewitt.me"];
        [picker setToRecipients:toRecipients];

        UIViewController* rootViewController = (UIViewController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
        [rootViewController presentViewController:picker animated:YES completion:NULL];
        //[picker release];
    }
    else {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error"
                              message:@"You seem to be unable to send emails."
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil
                              , nil];
        [alert show];
        //[alert release];
    }
}

-(void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [controller dismissViewControllerAnimated:YES completion:NULL];
}

-(void) openTwitterLink {
    NSURL* appURL = [NSURL URLWithString:@"twitter:///user?screen_name=friggog"];
    if ([[UIApplication sharedApplication] canOpenURL:appURL]) {
        [[UIApplication sharedApplication] openURL:appURL];
    }
    else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/friggog"]];
    }
}

-(void) openDonateLink {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://bit.ly/1kfttCg"]];
}

-(void) setEnabledWithValue:(id)value andSpecifier:(id)specifier {
    [self setPreferenceValue:value specifier:specifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self showDisableAlert];
}

-(void) showDisableAlert {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Respring Required"
                          message:@"To enable/disable Chroma you need to respring and restart any running apps."
                          delegate:self
                          cancelButtonTitle:@"Later"
                          otherButtonTitles:@"Now"
                          , nil];
    [alert show];
}

-(void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        system_nd("killall SpringBoard");
    }
}

-(id) readPreferenceValue:(PSSpecifier*)spec {
    NSDictionary* dic = [NSDictionary dictionaryWithContentsOfFile:prefsPath] ? :[NSDictionary dictionary];
    id val = nil;
    if (! dic[spec.properties[@"key"]]) {
        val = spec.properties[@"default"];
    }
    else {
        val = dic[spec.properties[@"key"]];
    }

    if ([spec.properties[@"negate"] boolValue]) {
        val = [NSNumber numberWithInt:(NSInteger) ! [val boolValue]];
    }
    return val;
}

-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)spec {
    [super setPreferenceValue:value specifier:spec];
    NSMutableDictionary* defaults = [NSMutableDictionary dictionary] ? :[NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:prefsPath]];
    if ([spec.properties[@"negate"] boolValue]) {
        [defaults setObject:[NSNumber numberWithInt:(NSInteger) ! [value boolValue]] forKey:spec.properties[@"key"]];
    }
    else {
        [defaults setObject:value forKey:spec.properties[@"key"]];
    }
    [defaults writeToFile:prefsPath atomically:YES];
    CFStringRef toPost = (__bridge CFStringRef)spec.properties[@"PostNotification"];
    if (toPost) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
}

@end

@interface ChromaBannerCell:PSTableCell {}
@end

@implementation ChromaBannerCell
-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        CGRect frame = [self frame];
        frame.size.height = 100;
        NSString* bundleName = @"ChromaPrefs";

        UIView* containerView = [[UIView alloc] initWithFrame:frame];
        containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        UIImageView* titleImage = [[UIImageView alloc] initWithFrame:frame];
        titleImage.contentMode = UIViewContentModeScaleAspectFill;
        titleImage.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        if (iPad) {
            titleImage.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle/banner_ipad.png", bundleName]];
            containerView.layer.cornerRadius = 5;
            containerView.clipsToBounds = YES;
        }
        else {
            titleImage.image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/%@.bundle/banner_iphone.png", bundleName]];
        }

        [containerView addSubview:titleImage];
        [self.contentView addSubview:containerView];
    }
    return self;
}

@end

@interface ChromaAdvancedController:PSListController {}
@end

@implementation ChromaAdvancedController
-(id) specifiers {
    if (_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"ChromaAdvancedPrefs" target:self];// retain];
    }
    return _specifiers;
}

@end

@interface ChromaInfoController:PSListController {}
@end

@implementation ChromaInfoController
-(id) specifiers {
    if (_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"ChromaInfoPrefs" target:self];// retain];
    }
    return _specifiers;
}

@end

@interface ChromaColourPickerController:PSListController {
    HRColorPickerView* colorPickerView;
}
@end

@implementation ChromaColourPickerController

-(id) specifiers {
    if (_specifiers == nil) {
        if (! colorPickerView) {
            [self performSelector:@selector(createPickerView) withObject:nil afterDelay:0.01];
        }
        PSSpecifier* spec = [PSSpecifier preferenceSpecifierNamed:@" "
                             target:self
                             set:nil
                             get:nil
                             detail:nil
                             cell:[PSTableCell cellTypeFromString:@"PSGroupCell"]
                             edit:0];
        _specifiers = [NSArray arrayWithObjects:spec, nil];
    }
    return _specifiers;
}

-(void) createPickerView {
    colorPickerView = [[HRColorPickerView alloc] init];
    CGRect frame = ((UIView*)self.table).frame;
    frame = CGRectMake(0, 0, frame.size.width, frame.size.height-66);
    if (iPad) {
        frame = CGRectMake(frame.size.width/2-200, 25, 400, 600);
    }
    colorPickerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    colorPickerView.frame = frame;
    colorPickerView.backgroundColor = [UIColor clearColor];
    UIColor* col = UIColorFromHexString([self.specifier propertyForKey:@"default"]);
    if ([self readPreferenceValue:self.specifier]) {
        col = UIColorFromHexString([self readPreferenceValue:self.specifier]);
    }
    colorPickerView.color = col;
    colorPickerView.alphaValue = 1.0;
    [colorPickerView addTarget:self
     action:@selector(action:)
     forControlEvents:UIControlEventValueChanged];
    [self.table addSubview:colorPickerView];
}

-(void) action:(HRColorPickerView*)obj {
    [self setPreferenceValue:HexStringFromUIColor(obj.color) specifier:self.specifier];
    [(PSListController*)_parentController reloadSpecifier:self.specifier];
}

-(id) readPreferenceValue:(PSSpecifier*)spec {
    NSDictionary* dic = [NSDictionary dictionaryWithContentsOfFile:prefsPath] ? :[NSDictionary dictionary];
    id val = nil;
    if (! dic[spec.properties[@"key"]]) {
        val = spec.properties[@"default"];
    }
    else {
        val = dic[spec.properties[@"key"]];
    }

    if ([spec.properties[@"negate"] boolValue]) {
        val = [NSNumber numberWithInt:(NSInteger) ! [val boolValue]];
    }
    return val;
}

-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)spec {
    [super setPreferenceValue:value specifier:spec];
    NSMutableDictionary* defaults = [NSMutableDictionary dictionary] ? :[NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:prefsPath]];
    if ([spec.properties[@"negate"] boolValue]) {
        [defaults setObject:[NSNumber numberWithInt:(NSInteger) ! [value boolValue]] forKey:spec.properties[@"key"]];
    }
    else {
        [defaults setObject:value forKey:spec.properties[@"key"]];
    }
    [defaults writeToFile:prefsPath atomically:YES];
    CFStringRef toPost = (__bridge CFStringRef)spec.properties[@"PostNotification"];
    if (toPost) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
    }
}

@end

@interface ChromaLinkToColourPickerCell:PSTableCell {
    CircleColourView* circle;
}
@end

@implementation ChromaLinkToColourPickerCell
-(id) initWithStyle:(NSInteger)arg1 reuseIdentifier:(id)arg2 specifier:(id)arg3 {
    self = [super initWithStyle:arg1 reuseIdentifier:arg2 specifier:arg3];
    if (self) {
        circle = [[CircleColourView alloc] initWithFrame:CGRectMake(self.frame.size.width-30, 7, 30, 30) andColour:[UIColor clearColor]];
        [self.contentView addSubview:circle];
        [self valueLabel].hidden = YES;
    }
    return self;
}

-(void) setValue:(id)value {
    [super setValue:value];
    UIColor* col = UIColorFromHexString(value);
    circle.backgroundColor = col;
}

@end

// vim:ft=objc
