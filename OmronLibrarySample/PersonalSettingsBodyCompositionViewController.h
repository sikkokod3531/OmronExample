//
//  PersonalSettingsBodyCompositionViewController.h
//  OmronLibrarySample
//
//  Created by Hitesh Bhardwaj on 11/04/19.
//  Copyright © 2019 Omron HealthCare Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "BPViewController.h"
#import "ReminderAddTableViewController.h"

typedef enum {
    pair,
    update
} OperationType;

@protocol PersonalSettingsBodyCompositionViewControllerDelegate <NSObject>
@required
- (void)updateLocalPeripheral:(OmronPeripheral *)peripheral;
@end

@interface PersonalSettingsBodyCompositionViewController : BaseViewController

@property (nonatomic, strong) NSMutableDictionary *filterDeviceModel;
@property (nonatomic, strong) NSMutableArray *users;
@property (nonatomic, strong) OmronPeripheral *selectedPeripheral;
@property (nonatomic, assign) OperationType currentOperation;
@property (nonatomic, assign) PairType pairType;

@property (weak, nonatomic) IBOutlet UITextField *dateOfBirthField;
@property (weak, nonatomic) IBOutlet UITextField *heightField;
@property (weak, nonatomic) IBOutlet UITextField *weightUnitField;
@property (weak, nonatomic) IBOutlet UITextField *genderField;
@property (weak, nonatomic) IBOutlet UITextField *dciField;

@property (weak, nonatomic) IBOutlet UIButton *updateButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (nonatomic, weak) id <PersonalSettingsBodyCompositionViewControllerDelegate> delegate;

@end
