//
//  BaseViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 9/12/20.
//  Copyright © 2020 Omron HealthCare Inc. All rights reserved.
//

#import "BaseViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)showAlertWithTitle:(NSString *)title withAction:(BOOL)userAction {
    
    UIAlertController *configError = [UIAlertController
                                      alertControllerWithTitle:@""
                                      message:title
                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
        
        if(userAction) {
            exit(0);
        }
    }];
    
    [configError addAction:okButton];
    [self presentViewController:configError animated:YES completion:nil];
}

#pragma mark - Customize Navigation Bar

- (void)customNavigationBarTitle:(NSString *)title withFont:(UIFont *)font{
    
    // Creates Title
    UILabel *labelTop = [[UILabel alloc] initWithFrame:CGRectZero];
    labelTop.text = title;
    labelTop.font = font;
    labelTop.textColor = [UIColor colorWithRed:0/255.0 green:114.0/255.0 blue:188.0/255.0 alpha:1.0];
    [labelTop sizeToFit];
    self.navigationItem.titleView = labelTop;
}

#pragma mark - Utility Data Functions

- (NSString *)stringFromDate:(NSDate *)date
                      locale:(NSLocale *)locale
              withDateFormat:(NSString *)dateFormat
              withTimeFormat:(NSString *)timeFormat {
    
    NSDateFormatter *formatter;
    
    formatter = [[NSDateFormatter alloc] init];
    if( dateFormat) {
        formatter.dateFormat = dateFormat;
        if( locale) formatter.locale = locale;
    } else {
        formatter.locale = [NSLocale currentLocale];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
    }
    NSString *dateString = [formatter stringFromDate:date];
    
    formatter = [[NSDateFormatter alloc] init];
    if( timeFormat) {
        formatter.dateFormat = timeFormat;
        if( locale) formatter.locale = locale;
    } else {
        formatter.locale = [NSLocale currentLocale];
        formatter.dateStyle = NSDateFormatterNoStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
    }
    NSString *timeString = [formatter stringFromDate:date];
    
    return [NSString stringWithFormat:@"%@ %@",dateString,timeString];
}


- (NSNumber *)roundFloatNumber:(float)number
                      exponent:(float)exponent {
    float fractionDigitBase = powf(10.0, exponent);
    float roundValue = (roundf(number * fractionDigitBase) / fractionDigitBase) * 100;
    return [[NSNumber alloc] initWithFloat:roundValue];
}

- (NSNumber *)getNumberFromString:(NSString *)numberString {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    return [formatter numberFromString:numberString];
}


#pragma mark - Audio Permission functions

- (void)requestMicrophonePermission {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (status != AVAuthorizationStatusAuthorized) {
        __weak typeof(self) weakSelf = self;
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            if (!granted) {
                [weakSelf showGoToSettingsAlert];
            }
        }];
    }
}

- (void)showGoToSettingsAlert {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Audio Permission is Required", nil)
                                                                        message:NSLocalizedString(@"Please give permissions on the setting screen.", nil)
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction * actionOk = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * _Nonnull action) {
            NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }];
        
        [alert addAction:actionOk];
        
        UIAlertAction *cancelButton = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction * action) {
        }];
        
        [alert addAction:cancelButton];
        
        [weakSelf presentViewController:alert animated:YES completion:nil];
    });
}

@end
