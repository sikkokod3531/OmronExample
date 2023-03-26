//
//  DeviceListViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 5/31/16.
//  Copyright (c) 2016 Omron HealthCare Inc. All rights reserved.
//

#import "DeviceListViewController.h"
#import "UserSelectViewController.h"
#import "BPViewController.h"
#import "PersonalSettingsViewController.h"
#import "DeviceDetailsViewController.h"
#import "TemperatureRecordingViewController.h"
#import "PersonalSettingsBodyCompositionViewController.h"

@interface DeviceListViewController () {
    
    NSMutableArray *deviceList;
    
    NSMutableDictionary *omronCommonDevice;
    
    BOOL isLoading;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)infoBtnPressed:(id)sender;

@end

@implementation DeviceListViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Customize Navigation Bar
    [self customNavigationBarTitle:@"OMRON Connected Devices" withFont:[UIFont fontWithName:@"Courier" size:16]];
    
    if(![[NSUserDefaults standardUserDefaults] valueForKey:@"LibraryKey"]) {
        
        [self showPromptForPartnerKey];
        
    }else {
        
        [self reloadConfiguration];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    // Remove Notification listeners
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OMRONBLEConfigDeviceAvailabilityNotification object:nil];
}

- (void)configAvailabilityNotification:(NSNotification *)aNotification {
    
    // Remove Notification listeners
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OMRONBLEConfigDeviceAvailabilityNotification object:nil];
    
    OMRONConfigurationStatus configFileStatus = (OMRONConfigurationStatus)[aNotification.object unsignedIntegerValue] ;
    
    isLoading = NO;
    
    if(configFileStatus == OMRONConfigurationFileSuccess) {
        
        NSLog(@"%@",  @"Config File Extract Success");
        
        [self loadDeviceList];
        
    }else if(configFileStatus == OMRONConfigurationFileError) {
        
        NSLog(@"%@",  @"Config File Extract Failure");
        
        [self showAlertWithTitle:@"Configuration File Error!" withAction:NO];
        
    }else if(configFileStatus == OMRONConfigurationFileUpdateError) {
        
        NSLog(@"%@",  @"Config File Update Failure");
        
        [self loadDeviceList];
        
        [self showAlertWithTitle:@"Configuration Update Error!" withAction:NO];
    }
    
}

- (void)loadDeviceList {
    
    // Get Devices List from Configuration File in Framework
    NSDictionary *configDictionary = [[NSDictionary alloc] initWithDictionary:[[OmronPeripheralManager sharedManager] retrieveManagerConfiguration]];
    
    deviceList = [NSMutableArray arrayWithArray:[configDictionary objectForKey:OMRONBLEConfigDeviceKey]];
    
    if([deviceList count] == 0) {
        
        [self showAlertWithTitle:@"Invalid Library API key configured\nOR\nNo devices supported for API Key\n\nPlease try again using ⓘ button. " withAction:NO];
    }
    [self.tableView reloadData];
}

#pragma mark - Table View Data Source and Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if(isLoading)
        return 1;
    
    return [deviceList count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 100.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    
    if(isLoading) {
        
        cell.textLabel.font = [UIFont fontWithName:@"Courier" size:16];
        cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:12];
        cell.textLabel.text = @"Loading Devices";
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.detailTextLabel.text = @"Please wait...";
        cell.detailTextLabel.textAlignment = NSTextAlignmentCenter;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        
    }else {
        
        if(deviceList.count != 0) {
            NSDictionary *currentItem = [deviceList objectAtIndex:indexPath.row];
            cell.textLabel.font = [UIFont fontWithName:@"Courier" size:16];
            cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:12];
            cell.textLabel.text =  [currentItem valueForKey:OMRONBLEConfigDeviceModelNameKey];
            cell.detailTextLabel.text = [currentItem valueForKey:OMRONBLEConfigDeviceIdentifierKey];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
            cell.imageView.image = [UIImage imageNamed:[currentItem valueForKey:OMRONBLEConfigDeviceThumbnailKey]];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if(isLoading) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableDictionary *currentDevice = [NSMutableDictionary dictionaryWithDictionary:[deviceList objectAtIndex:indexPath.row]];
        
        if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBloodPressure) {
            
            // Blood Pressure Device
            
            if([[currentDevice valueForKey:OMRONBLEConfigDeviceUsersKey] intValue] > 1) {
                
                // No User - Show User Selection Screen
                
                UserSelectViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"UserSelectViewController"];
                controller.numberOfUsers = [[currentDevice valueForKey:OMRONBLEConfigDeviceUsersKey] intValue];
                controller.filterDeviceModel = [NSMutableDictionary dictionaryWithDictionary:[deviceList objectAtIndex:indexPath.row]];
                
                [self.navigationController pushViewController:controller animated:YES];
                
            }else {
                
                NSMutableDictionary *localModel = [[NSMutableDictionary alloc] initWithDictionary:[deviceList objectAtIndex:indexPath.row]];
                
                BPViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BPViewController"];
                controller.filterDeviceModel = localModel;
                
                [self.navigationController pushViewController:controller animated:YES];
                
            }
        }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
            
            // Activity Device
            
            PersonalSettingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PersonalSettingsViewController"];
            controller.filterDeviceModel = [NSMutableDictionary dictionaryWithDictionary:[deviceList objectAtIndex:indexPath.row]];//
            
            [self.navigationController pushViewController:controller animated:YES];
            
        }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBodyComposition) {
            
            if([[currentDevice valueForKey:OMRONBLEConfigDeviceUsersKey] intValue] > 1) {
                
                UserSelectViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"UserSelectViewController"];
                controller.numberOfUsers = [[currentDevice valueForKey:OMRONBLEConfigDeviceUsersKey] intValue];
                controller.filterDeviceModel = [NSMutableDictionary dictionaryWithDictionary:[deviceList objectAtIndex:indexPath.row]];
                
                [self.navigationController pushViewController:controller animated:YES];
                
            }else {
                
                PersonalSettingsBodyCompositionViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PersonalSettingsBodyCompositionViewController"];
                controller.filterDeviceModel = [NSMutableDictionary dictionaryWithDictionary:[deviceList objectAtIndex:indexPath.row]];
                controller.currentOperation = pair;
                [self.navigationController pushViewController:controller animated:YES];
            }
            
        
        }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryWheeze) {
            
            // TODO: Temporary setting for BP screen
            NSMutableDictionary *localModel = [[NSMutableDictionary alloc] initWithDictionary:[deviceList objectAtIndex:indexPath.row]];
            
            BPViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BPViewController"];
            controller.filterDeviceModel = localModel;
            
            [self.navigationController pushViewController:controller animated:YES];
            
        }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryTemperature) {
            
            NSMutableDictionary *localModel = [[NSMutableDictionary alloc] initWithDictionary:[deviceList objectAtIndex:indexPath.row]];
            
            TemperatureRecordingViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"TemperatureRecordingViewController"];
            controller.filterDeviceModel = localModel;
            
            [self.navigationController pushViewController:controller animated:YES];
        
        }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryPulseOximeter) {
            
            NSMutableDictionary *localModel = [[NSMutableDictionary alloc] initWithDictionary:[deviceList objectAtIndex:indexPath.row]];
            
            BPViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PulseOxymeterViewController"];
            controller.filterDeviceModel = localModel;
            
            [self.navigationController pushViewController:controller animated:YES];
        
        }
        
    });
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableDictionary *currentDevice = [NSMutableDictionary dictionaryWithDictionary:[deviceList objectAtIndex:indexPath.row]];
        
        DeviceDetailsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"DeviceDetailsViewController"];
        controller.filterDeviceModel = currentDevice;
        [self.navigationController pushViewController:controller animated:YES];
        
    });
}

- (IBAction)infoBtnPressed:(id)sender {
    
    [self showPromptForPartnerKey];
}

- (void)showPromptForPartnerKey {
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *details = [NSString stringWithFormat:@"Sample App Version : %@\nLibrary Version : %@\n\nTap ⓘ to configure later", version, [[OmronPeripheralManager sharedManager] libVersion]];
    
    UIAlertController *configKey = [UIAlertController
                                    alertControllerWithTitle:@"Configure OMRON Library Key"
                                    message:details
                                    preferredStyle:UIAlertControllerStyleAlert];
    
    [configKey addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        {
            textField.placeholder = @"Enter API Key";
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            textField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        }
    }];
    
    UIAlertAction *okButton = [UIAlertAction
                               actionWithTitle:@"OK"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
        
        NSString *apiKey = configKey.textFields[0].text;
        
        if(![apiKey isEqualToString:@""]) {
            [[NSUserDefaults standardUserDefaults] setValue:apiKey forKey:@"LibraryKey"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self reloadConfiguration];
        }
    }];
    
    UIAlertAction *cancelButton = [UIAlertAction
                                   actionWithTitle:@"Cancel"
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction * action) {
        
        [self loadDeviceList];
    }];
    
    [configKey addAction:okButton];
    [configKey addAction:cancelButton];
    [self presentViewController:configKey animated:YES completion:nil];
}

- (void)reloadConfiguration {
    
    [[OmronPeripheralManager sharedManager] setAPIKey:[[NSUserDefaults standardUserDefaults] valueForKey:@"LibraryKey"] options:nil];
    
    if(![[NSUserDefaults standardUserDefaults] valueForKey:@"LibraryKey"]) {
        
        [self showPromptForPartnerKey];
        
    }else {
        
        isLoading = YES;
        
        // Load Omron Device Models
        [self loadDeviceList];
        
        // Notification Listener for Configuration Availability
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(configAvailabilityNotification:)
                                                     name:OMRONBLEConfigDeviceAvailabilityNotification
                                                   object:nil];
    }
}

@end
