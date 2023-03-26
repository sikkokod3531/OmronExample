//
//  UserSelectViewController.h
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 5/31/16.
//  Copyright (c) 2016 Omron HealthCare Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@interface UserSelectViewController : BaseViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) int numberOfUsers;
@property (nonatomic, strong) NSMutableDictionary *filterDeviceModel;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end
