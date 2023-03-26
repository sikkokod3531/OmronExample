//
//  DeviceDetailsViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/16/20.
//  Copyright © 2020 Omron HealthCare Inc. All rights reserved.
//

#import "DeviceDetailsViewController.h"
#import <OmronConnectivityLibrary/OmronConnectivityLibrary.h>

@interface DeviceDetailsViewController ()

@end

@implementation DeviceDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *title = [NSString stringWithFormat:@"%@", [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceModelDisplayNameKey]];
    
    [self customNavigationBarTitle:title withFont:[UIFont fontWithName:@"Courier" size:16]];
    
    self.deviceMainImage.image = [UIImage imageNamed:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceImageKey]];
    
    NSString *details = [NSString stringWithFormat:@"Model: %@\nSeries: %@\nIdentifier: %@\nCategory ID: %@\nModel ID: %@", [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceModelNameKey], [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceModelSeriesKey], [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceIdentifierKey], [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceGroupIDKey], [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]];
    
    self.deviceDetailsTextView.text = details;
}

@end
