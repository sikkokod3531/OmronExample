//
//  BodyCompositionViewController.h
//  OmronLibrarySample
//
//  Created by Hitesh Bhardwaj on 09/04/19.
//  Copyright © 2019 Omron HealthCare Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import <OmronConnectivityLibrary/OmronConnectivityLibrary.h>

@interface BodyCompositionViewController : BaseViewController

@property (nonatomic, strong) NSMutableDictionary *filterDeviceModel;
@property (nonatomic, strong) NSMutableArray *deviceSettings;
@property (nonatomic, strong) NSMutableArray *users;
@property (weak, nonatomic) IBOutlet UIButton *btnConnect;
@property (nonatomic, assign) PairType pairType;

- (IBAction)ConnectClick:(id)sender;
- (IBAction)TransferClick:(id)sender;

@end
