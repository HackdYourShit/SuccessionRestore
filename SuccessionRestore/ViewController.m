//
//  ViewController.m
//  SuccessionRestore
//
//  Created by Sam Gardner on 9/27/17.
//  Copyright © 2017 Sam Gardner. All rights reserved.
//

#import "ViewController.h"
#include <sys/sysctl.h>
#include <CoreFoundation/CoreFoundation.h>
#include <spawn.h>
#include <sys/stat.h>
#import "NSTask.h"

static int dmgdl(char* url, char* dmg)
{
    char *args[] = {"/Applications/SuccessionRestore.app/dmgdl", url, dmg};
    pid_t pid;
    int stat;
    posix_spawn(&pid, args[0], NULL, NULL, args, NULL);
    waitpid(pid, &stat, 0);
    return stat;
}

static int dmgdec(char* arg, char* dmg, char* flag, char* key, char* _out)
{
    char *args[] = {"/Applications/SuccessionRestore.app/dmgdec", arg, dmg, flag, key, _out};
    pid_t pid;
    int stat;
    posix_spawn(&pid, args[0], NULL, NULL, args, NULL);
    waitpid(pid, &stat, 0);
    return stat;
}

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create a size_t and set it to the size used to allocate modelChar
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    //Gets iOS device model (ex iPhone9,1 == iPhone 7 GSM) and changes label.
    char *modelChar = malloc(size);
    sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithUTF8String:modelChar];
    free(modelChar);
    self.deviceModelLabel.text = [NSString stringWithFormat:@"%@", deviceModel];
    
    //Gets iOS version (if you need an example, maybe you should learn about iOS more before learning to develop for it) and changes label.
    NSString *deviceVersion = [[UIDevice currentDevice] systemVersion];
    self.iOSVersionLabel.text = [NSString stringWithFormat:@"%@", deviceVersion];
    
    // Set size to the size used to allocate buildChar
    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    
    //Gets iOS device build number (ex 10.1.1 == 14B100 or 14B150) and changes label.
    //Thanks, Apple, for releasing two versions of 10.1.1, you really like making things hard on us.
    char *buildChar = malloc(size);
    sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
    NSString *deviceBuild = [NSString stringWithUTF8String:buildChar];
    free(buildChar);
    self.iOSBuildLabel.text = [NSString stringWithFormat:@"%@", deviceBuild];
    
    //Checks to see if DMG has already been downloaded and sets features accordingly
    BOOL DMGAlreadyDownloaded = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/mobile/Media/Succession/rfs.dmg"];
    if (DMGAlreadyDownloaded == YES) {
        [_downloadDMGButton setTitle:@"Redownload clean rootfilesystem" forState:UIControlStateNormal];
        [_prepareToRestoreButton setTitle:@"Prepare to restore!" forState:UIControlStateNormal];
        [_prepareToRestoreButton setEnabled:YES];
        [_prepareToRestoreButton setUserInteractionEnabled:YES];
        [_prepareToRestoreButton setTitleColor:[UIColor colorWithRed:255.0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0] forState:UIControlStateNormal];
    } else {
        [_downloadDMGButton setTitle:@"Download a clean rootfilesystem" forState:UIControlStateNormal];
        [_prepareToRestoreButton setTitle:@"Please download a rootfilesystem first" forState:UIControlStateNormal];
        [_prepareToRestoreButton setEnabled:NO];
        [_prepareToRestoreButton setUserInteractionEnabled:NO];
        [_prepareToRestoreButton setTitleColor:[UIColor colorWithRed:173.0/255.0 green:173.0/255.0 blue:173.0/255.0 alpha:1.0] forState:UIControlStateNormal];
    }
}
- (void)viewDidAppear:(BOOL)animated {
    //Checks to see if app is in the root applications folder. Uses viewDidAppear instead of viewDidLoad because viewDidLoad doesn't like UIAlertControllers.
    BOOL isRoot = [[NSFileManager defaultManager] fileExistsAtPath:@"/Applications/SuccessionRestore.app"];
    if (isRoot == YES) {
        
    } else {
        UIAlertController *notRunningAsRoot = [UIAlertController alertControllerWithTitle:@"Succession isn't running as root" message:@"You need a jailbreak to use this app" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *exitApp = [UIAlertAction actionWithTitle:@"Exit" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *closeApp) {
            exit(0);
            }];
        [notRunningAsRoot addAction:exitApp];
        [self presentViewController:notRunningAsRoot animated:YES completion:nil];
    }
    
}

- (IBAction)contactSupportButton:(id)sender {
    //Opens a PM to my reddit
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.reddit.com/message/compose/?to=samg_is_a_ninja"]];
}

- (IBAction)donateButton:(id)sender {
    //Hey, someone actually decided to donate?! <3
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/Sam4Gardner/2"]];
}

- (IBAction)infoNotAccurateButton:(id)sender {
    //Code that runs the "Information not correct" button
    UIAlertController *infoNotAccurateButtonInfo = [UIAlertController alertControllerWithTitle:@"Please provide your own DMG" message:@"Please extract a clean IPSW for your device/iOS version and place the largest DMG file in /var/mobile/Media/Succession. On iOS 9 and older, you will need to decrypt the DMG first." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [infoNotAccurateButtonInfo addAction:okAction];
    [self presentViewController:infoNotAccurateButtonInfo animated:YES completion:nil];
}

- (IBAction)startDownloadingButton:(id)sender {
    //This code should look familiar, this time instead of setting labels, the information is used to download the right file.
    
    // Create a size_t and set it to the size used to allocate modelChar
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    
    //Gets iOS device model (ex iPhone9,1 == iPhone 7 GSM) and changes label.
    char *modelChar = malloc(size);
    sysctlbyname("hw.machine", modelChar, &size, NULL, 0);
    NSString *deviceModel = [NSString stringWithUTF8String:modelChar];
    free(modelChar);
    
    //Gets iOS version (if you need an example, maybe you should learn about iOS more before learning to develop for it) and changes label.
    NSString *deviceVersion = [[UIDevice currentDevice] systemVersion];
    
    // Set size to the size used to allocate buildChar
    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    
    //Gets iOS device build number (ex 10.1.1 == 14B100 or 14B150) and changes label.
    //Thanks, Apple, for releasing two versions of 10.1.1, you really like making things hard on us.
    char *buildChar = malloc(size);
    sysctlbyname("kern.osversion", buildChar, &size, NULL, 0);
    NSString *deviceBuild = [NSString stringWithUTF8String:buildChar];
    free(buildChar);
    
    // API to get ipsw of any firmware with the buildid and model
    NSString *link = [NSString stringWithFormat:@"http://api.ipsw.me/v2/%@/%@/url/dl", deviceModel, deviceBuild];
    if ([deviceModel isEqualToString:@"iPhone4,1"])
    {
        if ([deviceVersion isEqualToString:@"8.4.1"])
        {
            
        }
    }
    else if ([deviceModel isEqualToString:@"iPod5,1"])
    {
        if ([deviceVersion isEqualToString:@"8.4.1"])
        {
            
        }
    }
    
    else if ([deviceVersion isEqualToString:@"9.3.5"])
    {
            if ([deviceBuild isEqualToString:@"13G36"])
            {
                
            }
    }
    else {
        UIAlertController *deviceNotSupported = [UIAlertController alertControllerWithTitle:@"Device not supported" message:@"Please extract a clean IPSW for your device/iOS version and place the largest DMG file in /var/mobile/Media/Succession. On iOS 9 and older, you will need to decrypt the DMG first." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *closeApp) {
            exit(0);
        }];
        [deviceNotSupported addAction:okAction];
        [self presentViewController:deviceNotSupported animated:YES completion:nil];;
    }

}
@end
