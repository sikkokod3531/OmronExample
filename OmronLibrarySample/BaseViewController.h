//
//  BaseViewController.h
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 9/12/20.
//  Copyright © 2020 Omron HealthCare Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// Pair Type
typedef enum {
    bcm,
    weight
} PairType;

@interface BaseViewController : UIViewController

- (void)showAlertWithTitle:(NSString *)title withAction:(BOOL)action;

- (void)customNavigationBarTitle:(NSString *)title withFont:(UIFont *)font;

- (NSString *)stringFromDate:(NSDate *)date
                      locale:(NSLocale *)locale
              withDateFormat:(NSString *)dateFormat
              withTimeFormat:(NSString *)timeFormat;

- (NSNumber *)roundFloatNumber:(float)number
                      exponent:(float)exponent;

- (NSNumber *)getNumberFromString:(NSString *)numberString;

- (void)requestMicrophonePermission;

@end

NS_ASSUME_NONNULL_END
