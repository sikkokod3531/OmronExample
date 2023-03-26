//
//  DeviceDetailsViewController.h
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/16/20.
//  Copyright © 2020 Omron HealthCare Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface DeviceDetailsViewController : BaseViewController

@property (nonatomic, strong) NSMutableDictionary *filterDeviceModel;
@property (weak, nonatomic) IBOutlet UIImageView *deviceMainImage;
@property (weak, nonatomic) IBOutlet UITextView *deviceDetailsTextView;

@end

NS_ASSUME_NONNULL_END
