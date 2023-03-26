//
//  UserSelectViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 5/31/16.
//  Copyright (c) 2016 Omron HealthCare Inc. All rights reserved.
//

#import "UserSelectViewController.h"
#import "BPViewController.h"
#import "PersonalSettingsBodyCompositionViewController.h"

@interface UserSelectViewController () {
    
    NSMutableAttributedString *atrStrin;
    NSMutableArray *userList;
}

@end

@implementation UserSelectViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    userList = [[NSMutableArray alloc] init];
    
    NSString *title = [NSString stringWithFormat:@"%@ - Select User", [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceModelDisplayNameKey]];
    
    [self customNavigationBarTitle:title withFont:[UIFont fontWithName:@"Courier" size:16]];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.numberOfUsers;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    
    return 200 ;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 50.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    
    UIView* footerView = [[UIView alloc] initWithFrame:CGRectMake(25, 0, tableView.frame.size.width - 50, 40)];
    
    UIButton *pairBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    pairBtn.frame = CGRectZero;
    [pairBtn addTarget:self action:@selector(tapSubmitButton) forControlEvents:UIControlEventTouchUpInside];
    pairBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [pairBtn setBackgroundColor:[UIColor colorWithRed:0/255.0 green:114.0/255.0 blue:188.0/255.0 alpha:1.0]];
    [pairBtn setTitle:@"Start" forState:UIControlStateNormal];
    pairBtn.titleLabel.font =  [UIFont fontWithName:@"Courier" size:18];
    
    [footerView addSubview:pairBtn];
    
    [pairBtn addConstraint:[NSLayoutConstraint constraintWithItem:pairBtn attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:40]];
    [pairBtn addConstraint:[NSLayoutConstraint constraintWithItem:pairBtn attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:200]];
    
    if ([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBodyComposition) {
        
        UIButton *weightOnlyPairBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        weightOnlyPairBtn.frame = CGRectZero;
        [weightOnlyPairBtn addTarget:self action:@selector(tapSubmitButtonForWeightOnly) forControlEvents:UIControlEventTouchUpInside];
        weightOnlyPairBtn.translatesAutoresizingMaskIntoConstraints = NO;
        [weightOnlyPairBtn setBackgroundColor:[UIColor colorWithRed:0/255.0 green:114.0/255.0 blue:188.0/255.0 alpha:1.0]];
        [weightOnlyPairBtn setTitle:@"Start - Weight only" forState:UIControlStateNormal];
        weightOnlyPairBtn.titleLabel.font =  [UIFont fontWithName:@"Courier" size:18];
        
        [footerView addSubview:weightOnlyPairBtn];
        
        [weightOnlyPairBtn addConstraint:[NSLayoutConstraint constraintWithItem:weightOnlyPairBtn attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:40]];
        [weightOnlyPairBtn addConstraint:[NSLayoutConstraint constraintWithItem:weightOnlyPairBtn attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1 constant:250]];
        
        [footerView addConstraint:[NSLayoutConstraint constraintWithItem:pairBtn attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:footerView attribute:NSLayoutAttributeTop multiplier:1 constant:50]];
        [footerView addConstraint:[NSLayoutConstraint constraintWithItem:weightOnlyPairBtn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:footerView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
        [footerView addConstraint:[NSLayoutConstraint constraintWithItem:weightOnlyPairBtn attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:pairBtn attribute:NSLayoutAttributeBottom multiplier:1 constant:50]];
        
    }else {
        
        [footerView addConstraint:[NSLayoutConstraint constraintWithItem:pairBtn attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:footerView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
        
    }
    
    [footerView addConstraint:[NSLayoutConstraint constraintWithItem:pairBtn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:footerView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    
    return footerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *prefCellIdentifier = @"DeviceTableViewCell";
    
    UITableViewCell *userselectionCell = [tableView dequeueReusableCellWithIdentifier:prefCellIdentifier];
    if (userselectionCell == nil) {
        userselectionCell = (UITableViewCell *)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:prefCellIdentifier];
    }
    
    [userselectionCell.textLabel setText:[NSString stringWithFormat:@"User %ld",(long)indexPath.row+1]];
    userselectionCell.textLabel.font = [UIFont fontWithName:@"Courier" size:16];
    
    UISwitch *userSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    [userSwitch setOnTintColor:[UIColor colorWithRed:0/255.0 green:114.0/255.0 blue:188.0/255.0 alpha:1.0]];
    [userSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    userselectionCell.accessoryView = userSwitch;
    [userSwitch setTag:indexPath.row];
    userSwitch.on = NO;
    
    if ([userList containsObject:[NSNumber numberWithInt:(int)indexPath.row + 1]]) {
        userSwitch.on = YES;
    }
    userSwitch = nil;
    return userselectionCell;
}


- (void)switchValueChanged:(UISwitch *)userSwitch{
    if (userSwitch.isOn) {
        [userList addObject:[NSNumber numberWithInt:(int)userSwitch.tag+1]];
    }else{
        [userList removeObject:[NSNumber numberWithInt:(int)userSwitch.tag+1]];
    }
    [self.tableView reloadData];
}

#pragma mark - Action

- (void)tapSubmitButton
{
    if (userList.count == 0) {
        
        [self showAlertWithTitle:@"Please select at least one user number" withAction:NO];
        
    }else if ([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBodyComposition) {
        
        PersonalSettingsBodyCompositionViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PersonalSettingsBodyCompositionViewController"];
        controller.filterDeviceModel = self.filterDeviceModel;
        controller.users = userList;
        controller.currentOperation = pair;
        [self.navigationController pushViewController:controller animated:YES];
    }else {
        
        BPViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BPViewController"];
        controller.filterDeviceModel = self.filterDeviceModel;
        controller.users = userList;
        [self.navigationController pushViewController:controller animated:YES];
        
    }
}

- (void)tapSubmitButtonForWeightOnly {
    
    PersonalSettingsBodyCompositionViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PersonalSettingsBodyCompositionViewController"];
    controller.filterDeviceModel = self.filterDeviceModel;
    controller.users = userList; //empty
    controller.currentOperation = pair;
    controller.pairType = weight;
    [self.navigationController pushViewController:controller animated:YES];
}

@end
