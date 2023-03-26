//
//  BPViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 5/31/16.
//  Copyright (c) 2016 Omron HealthCare Inc. All rights reserved.
//

#import  "QuartzCore/QuartzCore.h"
#import "BPViewController.h"
#import "AppDelegate.h"
#import "BPReadingsViewController.h"
#import "VitalOptionsTableViewController.h"
#import "ReminderListTableViewController.h"

@interface BPViewController () <UITableViewDataSource, UITableViewDelegate> {
    
    // Tracks Connected Omron Peripheral
    OmronPeripheral *localPeripheral;
    
    NSMutableArray *scannedPeripheral;
    
    BOOL isScanning;
    
    int counter;
}

@property (weak, nonatomic) IBOutlet UILabel *lblTimeStamp;
@property (weak, nonatomic) IBOutlet UILabel *lblSystolic;
@property (weak, nonatomic) IBOutlet UILabel *lblDiastolic;
@property (weak, nonatomic) IBOutlet UILabel *lblPulseRate;
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblSysUnit;
@property (weak, nonatomic) IBOutlet UILabel *lblDiaUnit;
@property (weak, nonatomic) IBOutlet UILabel *lblPulseUnit;
@property (weak, nonatomic) IBOutlet UILabel *lblLocalName;
@property (weak, nonatomic) IBOutlet UILabel *lblUserSelected;
@property (weak, nonatomic) IBOutlet UILabel *lblPeripheralErrorCode;
@property (weak, nonatomic) IBOutlet UILabel *lblPeripheralError;
@property (weak, nonatomic) IBOutlet UILabel *lbldeviceModel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *devicesView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searching;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

- (IBAction)readingListButtonPressed:(id)sender;

- (IBAction)settingsButtonPressed:(id)sender;

@end

@implementation BPViewController

#pragma mark - View Controller Life cycles

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    counter = 0;
    
    self.devicesView.hidden = NO;
    self.searching.hidden = YES;
    
    self.scrollView.backgroundColor = self.devicesView.backgroundColor;
    
    scannedPeripheral = [[NSMutableArray alloc] init];
    
    isScanning = NO;
    
    self.lbldeviceModel.text = [NSString stringWithFormat:@"%@ - Device Information", [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceModelDisplayNameKey]];
    
    [self customNavigationBarTitle:@"Pair & Transfer" withFont:[UIFont fontWithName:@"Courier" size:16]];
    
    // Default to 1 for single user device
    if(self.users.count == 0) {
        self.users = [[NSMutableArray alloc] initWithArray:@[@(1)]];
    }
    
    self.lblUserSelected.text = [self.users componentsJoinedByString:@","];
    
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBloodPressure) {
        
        self.settingsButton.hidden = YES;
        
    }else {
        
        self.settingsButton.hidden = NO;
    }
    
    // Start OmronPeripheralManager
    [self startOmronPeripheralManagerWithHistoricRead:NO withPairing:YES];
}

// Start Omron Peripheral Manager
- (void)startOmronPeripheralManagerWithHistoricRead:(BOOL)isHistoric withPairing:(BOOL)pairing {
    
    OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
    
    // Filter device to scan and connect (optional)
    if([self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceGroupIDKey] && [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]) {
        
        NSMutableArray *filterDevices = [[NSMutableArray alloc] init];
        
        // New Supported Format - Add entire data model to filter list
        [filterDevices addObject:self.filterDeviceModel];
        
        peripheralConfig.deviceFilters = filterDevices;// Filter Devices
    }
    
    // Set Scan timeout interval (optional)
    peripheralConfig.timeoutInterval = 10; // Seconds
    
    // Holds settings
    NSMutableArray *deviceSettings = [[NSMutableArray alloc] init];
    
    // Disclaimer: Read definition before usage
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] != OMRONBLEDeviceCategoryActivity) {
        peripheralConfig.enableAllDataRead = isHistoric;
    }
    
    peripheralConfig.enableiBeaconWithTransfer = true;
    
    // Blood pressure settings (optional)
    [self getBloodPressureSettings:&deviceSettings withPairing:pairing];
    
    // Activity device settings (optional)
    [self getActivitySettings:&deviceSettings];
    
    // Set settings
    peripheralConfig.deviceSettings = deviceSettings;
    
    // Set User Hash Id (mandatory)
    peripheralConfig.userHashId = @"<email_address_of_user>"; // Email address of logged in User
    
    // Pass the last sequence number of reading  tracked by app - "SequenceKey" for each vital data (user number and sequence number mapping)
    // peripheralConfig.sequenceNumbersForTransfer = @{@1 : @42, @2 : @8};
    
    // Set Configuration to New Configuration (mandatory to set configuration)
    [(OmronPeripheralManager *)[OmronPeripheralManager sharedManager] setConfiguration:peripheralConfig];
    
    // Start OmronPeripheralManager (mandatory)
    [[OmronPeripheralManager sharedManager] startManager];
    
    // Notification Listener for BLE State Change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(centralManagerDidUpdateStateNotification:)
                                                 name:OMRONBLECentralManagerDidUpdateStateNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    // Remove Notification listeners
    [[NSNotificationCenter defaultCenter] removeObserver:self name:OMRONBLECentralManagerDidUpdateStateNotification object:nil];
    
    // Stop Scanning for devices if scanning
    [[OmronPeripheralManager sharedManager] stopScanPeripherals];
}

#pragma mark - Table View Data Source and Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return scannedPeripheral.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 65.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OmronPeripheral *peripheral = [scannedPeripheral objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    cell.textLabel.font = [UIFont fontWithName:@"Courier" size:16];
    cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:12];
    cell.textLabel.text = peripheral.localName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"UUID : %@ \nRSSI: %@", peripheral.UUID, peripheral.RSSI];
    cell.detailTextLabel.numberOfLines = 5;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.devicesView.hidden = YES;
        
        OmronPeripheral *peripheral = [scannedPeripheral objectAtIndex:indexPath.row];
        
        // Or use below
        //        OmronPeripheral *peripheralLocal = [[OmronPeripheral alloc] initWithLocalName:peripheral.localName andUUID:peripheral.UUID];
        
        if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceUsersKey] intValue] == 1) {
            // If single device check with direction connection
            [self connectPeripheral:peripheral];
        }else {
            // if multiple deviecs check with wait functionality
            [self connectPeripheralWithWait:peripheral];
        }
    });
}

#pragma mark - Connect to Device

- (IBAction)ConnectClick:(id)sender {
    
    [self resetLabels];
    
    self.devicesView.hidden = NO;
    self.searching.hidden = NO;
    
    scannedPeripheral = [[NSMutableArray alloc] init];
    [self.tableView reloadData];
    
    self.lblStatus.text = @"Scanning...";
    
    [self startOmronPeripheralManagerWithHistoricRead:NO withPairing:YES];
    
    // Connection State
    [self setConnectionStateNotifications];
    
    [self startScanning];
}


#pragma mark - OmronPeripheralManager Scan Function

- (void)startScanning {
    
    if(isScanning) {
        
        // Stop Scanning
        [self.btnConnect setTitle:@"Scan" forState:UIControlStateNormal];
        
        // Stop Scanning of Omron Peripherals
        [[OmronPeripheralManager sharedManager] stopScanPeripheralsWithCompletionBlock:^(NSError *error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if(error == nil) {
                    
                    self.devicesView.hidden = NO;
                    self.searching.hidden = YES;
                    
                    scannedPeripheral = [[NSMutableArray alloc] initWithArray:@[]];
                    [self.tableView reloadData];
                }
            });
            
        }];
        
    }else {
        
        [self.btnConnect setTitle:@"Stop Scan" forState:UIControlStateNormal];
        
        NSLog(@"Start Scan");
        
        // Start Scanning of Omron Peripherals
        [[OmronPeripheralManager sharedManager] startScanPeripheralsWithCompletionBlock:^(NSArray *retrievedPeripherals, NSError *error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSLog(@"Retrieved Peripherals - %@", retrievedPeripherals);
                
                if(error == nil) {
                    
                    scannedPeripheral = [[NSMutableArray alloc] initWithArray:retrievedPeripherals];
                    [self.tableView reloadData];
                    
                }else {
                    
                    NSLog(@"Error - %@", error);
                    
                    isScanning = !isScanning;
                    
                    [self resetLabels];
                    
                    scannedPeripheral = [[NSMutableArray alloc] initWithArray:retrievedPeripherals];
                    [self.tableView reloadData];
                    
                    self.lblPeripheralErrorCode.text = [NSString stringWithFormat:@"Code: %ld", (long)error.code];
                    self.lblPeripheralError.text = [error localizedDescription];
                    
                }
            });
        }];
    }
    
    isScanning = !isScanning;
}

#pragma mark - OmronPeripheralManager Connect / Pair Function

- (void)connectPeripheral:(OmronPeripheral *)peripheral {
    
    isScanning = NO;
    
    self.lblStatus.text = @"Connecting...";
    
    [self.btnConnect setTitle:@"Scan" forState:UIControlStateNormal];
    
    // Connects to Peripheral and Pairs device without Wait
    [[OmronPeripheralManager sharedManager] connectPeripheral:peripheral withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        [self connectionUpdateWithPeripheral:peripheral withError:error withWait:NO];
        
    }];
}

- (void)connectPeripheralWithWait:(OmronPeripheral *)peripheral {
    
    isScanning = NO;
    
    self.lblStatus.text = @"Connecting...";
    
    [self.btnConnect setTitle:@"Scan" forState:UIControlStateNormal];
    
    // Connects to Peripheral and Pairs device + Wait
    [[OmronPeripheralManager sharedManager] connectPeripheral:peripheral withWait:true withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        [self connectionUpdateWithPeripheral:peripheral withError:error withWait:YES];
        
    }];
}

- (void)resumeConnection {
    
    if([self.users count] > 1) {
        
        [[OmronPeripheralManager sharedManager] resumeConnectPeripheralWithUsers:self.users withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
            
            [self connectionUpdateWithPeripheral:peripheral withError:error withWait:NO];
        }];
        
    }else {
        
        [[OmronPeripheralManager sharedManager] resumeConnectPeripheralWithUser:[[self.users firstObject] intValue] withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
            
            [self connectionUpdateWithPeripheral:peripheral withError:error withWait:NO];
        }];
    }
}

- (void)connectionUpdateWithPeripheral:(OmronPeripheral *)peripheral withError:(NSError *)error withWait:(BOOL)wait {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(error == nil) {
            
            self.lblLocalName.text = [NSString stringWithFormat:@"%@\n\n%@", peripheral.localName, peripheral.UUID];
            
            // Save Peripheral Details
            localPeripheral = peripheral;
            
            // Retrieves Peripheral Configuration with GroupId and GroupIncludedGroupID
            OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
            NSMutableDictionary *deviceConfig = [peripheralConfig retrievePeripheralConfigurationWithGroupId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIDKey] andGroupIncludedId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]];
            NSLog(@"Device Information - %@", [peripheral getDeviceInformation]);
            NSLog(@"Device Configuration - %@", deviceConfig);
            NSLog(@"Device Settings - %@", [peripheral getDeviceSettings]);
            
            // Wait
            if(wait) {
                [self performSelector:@selector(resumeConnection) withObject:nil afterDelay:2.0];
            }else {
                self.lblPeripheralError.text = @"Paired Successfully!";
                
                [peripheral getVitalDataWithCompletionBlock:^(NSMutableDictionary *vitalData, NSError *error) {
                    
                    if(error == nil) {
                        
                        if(vitalData.allKeys.count > 0) {
                            
                            NSLog(@"Vital Data - %@", vitalData);
                        }
                    }
                }];
            }
            
        }else {
            
            [self resetLabels];
            
            self.lblPeripheralErrorCode.text = [NSString stringWithFormat:@"Code: %ld", (long)error.code];
            self.lblPeripheralError.text = [error localizedDescription];
            
            NSLog(@"Error - %@", error);
        }
    });
}

- (void)endConnection {
    
    [[OmronPeripheralManager sharedManager] endConnectPeripheralWithCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error == nil) {
                
                self.lblLocalName.text = [NSString stringWithFormat:@"%@\n\n%@", peripheral.localName, peripheral.UUID];
                
                // Save Peripheral Details
                localPeripheral = peripheral;
                
                self.lblPeripheralError.text = @"Disconnected! ";
                
                // Retrieves Peripheral Configuration with GroupId and GroupIncludedGroupID
                OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
                NSMutableDictionary *deviceConfig = [peripheralConfig retrievePeripheralConfigurationWithGroupId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIDKey] andGroupIncludedId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]];
                NSLog(@"Device Information - %@", [peripheral getDeviceInformation]);
                NSLog(@"Device Configuration - %@", deviceConfig);
                NSLog(@"Device Settings - %@", [peripheral getDeviceSettings]);
                
            }else {
                
                [self resetLabels];
                
                self.lblPeripheralErrorCode.text = [NSString stringWithFormat:@"Code: %ld", (long)error.code];
                self.lblPeripheralError.text = [error localizedDescription];
                
                NSLog(@"Error - %@", error);
            }
        });
    }];
}

#pragma mark - OmronPeripheralManager Disconnect Function

- (void)disconnectDeviceWithMessage:(NSString *)message {
    
    self.lblStatus.text = @"Disconnecting...";
    
    // Disconnects Omron Peripherals
    [[OmronPeripheralManager sharedManager] disconnectPeripheral:localPeripheral withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        if(error == nil) {
            
            self.lblStatus.text = @"Disconnected";
            self.lblPeripheralError.text = message;
            
        }else {
            
            [self resetLabels];
            
            self.lblPeripheralErrorCode.text = [NSString stringWithFormat:@"Code: %ld", (long)error.code];
            self.lblPeripheralError.text = [error localizedDescription];
            
            NSLog(@"Error - %@", error);
        }
    }];
}

#pragma mark - OmronPeripheralManager Transfer Function

- (IBAction)TransferClick:(id)sender {
    
    counter++;
    
    [self resetLabels];
    
    if(localPeripheral) {
        
        if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
            [self startOmronPeripheralManagerWithHistoricRead:NO withPairing:NO];
            [self performDataTransfer];
        }else {
            UIAlertController *transferType = [UIAlertController
                                              alertControllerWithTitle:@"Transfer"
                                              message:@"Do you want to transfer all historic readings from device?"
                                              preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okButton = [UIAlertAction
                                       actionWithTitle:@"Yes"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                
                [self startOmronPeripheralManagerWithHistoricRead:YES withPairing:NO];
                [self performDataTransfer];
                
            }];
            UIAlertAction *cancelButton = [UIAlertAction
                                       actionWithTitle:@"No"
                                       style:UIAlertActionStyleDestructive
                                       handler:^(UIAlertAction * action) {
                
                [self startOmronPeripheralManagerWithHistoricRead:NO withPairing:NO];
                [self performDataTransfer];
            }];
            
            [transferType addAction:okButton];
            [transferType addAction:cancelButton];
            [self presentViewController:transferType animated:YES completion:nil];
        }

    }else {
        
        self.lblPeripheralError.text = @"No device paired";
    }
}

- (void)performDataTransfer {
    
    // Connection State
    [self setConnectionStateNotifications];
    
    // Only Activity Device - HeartGuide
    [self onPeriodicNotifications];
    
    OmronPeripheral *peripheralLocal = [[OmronPeripheral alloc] initWithLocalName:localPeripheral.localName andUUID:localPeripheral.UUID];
    
    if([self.users count] > 1) {
        // Use param different to check function availability
        [self transferUsersDataWithPeripheral:peripheralLocal];
    }else {
        // Use regular function with one user type
        [self transferUserDataWithPeripheral:peripheralLocal];
    }
}

// Single User data transfer
- (void)transferUserDataWithPeripheral:(OmronPeripheral *)peripheral {
    
    OMRONVitalDataTransferCategory category = OMRONVitalDataTransferCategoryAll;
    
    // Activity
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
        if(counter %2 != 0) {
            category = OMRONVitalDataTransferCategoryBloodPressure;
        }
    }
    
    /*
     * Starts Data Transfer from Omron Peripherals.
     * endDataTransferFromPeripheralWithCompletionBlock of OmronConnectivityLibrary need to be called once data retrieved is saved
     * For single user device, selected user will be passed as 1
     * withWait : Only YES is supported now
     */
    [[OmronPeripheralManager sharedManager] startDataTransferFromPeripheral:peripheral withUser:[[self.users firstObject] intValue] withWait:YES withType:category withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(error == nil) {
                
                localPeripheral = peripheral;
                
                NSLog(@"Device Information - %@", [peripheral getDeviceInformation]);
                NSLog(@"Device Settings - %@", [peripheral getDeviceSettings]);
                
                // Retrieves Vital data for required user (should be same as value passed in function startDataTransferFromPeripheral:withUser:withWait:withCompletionBlock
                [peripheral getVitalDataWithCompletionBlock:^(NSMutableDictionary *vitalData, NSError *error) {
                    
                    if(error == nil) {
                        
                        [self uploadData:vitalData withPeripheral:peripheral withWait:YES];
                        
                    }else {
                        
                        // Error retrieving Peripheral vital data
                        NSLog(@"Error retrieving Peripheral Vital data - %@", error.description);
                        
                        [self disconnectDeviceWithMessage:error.localizedDescription];
                    }
                }];
                
            }else {
                
                [self resetLabels];
                
                self.lblPeripheralErrorCode.text = [NSString stringWithFormat:@"Code: %ld", (long)error.code];
                self.lblPeripheralError.text = [error localizedDescription];
                
                NSLog(@"Error - %@", error);
            }
        });
    }];
}

// Data transfer with multiple users
- (void)transferUsersDataWithPeripheral:(OmronPeripheral *)peripheral {
    
    /*
     * Starts Data Transfer from Omron Peripherals.
     * endDataTransferFromPeripheralWithCompletionBlock of OmronConnectivityLibrary need to be called once data retrieved is saved
     * For single user device, selected user will be passed as 1
     * withWait : Only YES is supported now
     */
    [[OmronPeripheralManager sharedManager] startDataTransferFromPeripheral:peripheral withUsers:self.users withWait:YES withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(error == nil) {
                
                localPeripheral = peripheral;
                
                NSLog(@"Device Information - %@", [peripheral getDeviceInformation]);
                NSLog(@"Device Settings - %@", [peripheral getDeviceSettings]);
                
                // Retrieves Vital data for required user (should be same as value passed in function startDataTransferFromPeripheral:withUser:withWait:withCompletionBlock
                [peripheral getVitalDataWithCompletionBlock:^(NSMutableDictionary *vitalData, NSError *error) {
                    
                    if(error == nil) {
                        
                        [self uploadData:vitalData withPeripheral:peripheral withWait:YES];
                        
                    }else {
                        
                        // Error retrieving Peripheral vital data
                        NSLog(@"Error retrieving Peripheral Vital data - %@", error.description);
                        
                        [self disconnectDeviceWithMessage:error.localizedDescription];
                    }
                }];
                
            }else {
                
                [self resetLabels];
                
                self.lblPeripheralErrorCode.text = [NSString stringWithFormat:@"Code: %ld", (long)error.code];
                self.lblPeripheralError.text = [error localizedDescription];
                
                NSLog(@"Error - %@", error);
            }
        });
    }];
}

#pragma mark - Vital Data Save

- (void)uploadData:(NSMutableDictionary *)vitalData withPeripheral:(OmronPeripheral *)peripheral withWait:(BOOL)isWait {
    
    NSMutableDictionary *deviceInfo = peripheral.getDeviceInformation;
    
    if(vitalData.allKeys.count > 0) {
        
        for (NSString *key in vitalData.allKeys) {
            
            // Blood Pressure Data
            if([key isEqualToString:OMRONVitalDataBloodPressureKey]) {
                
                NSMutableArray *uploadData = [vitalData objectForKey:key];
                
                // Save to DB
                if([uploadData count] > 0) {
                    
                    NSLog(@"BP Data - %@", uploadData);
                    
                    [self saveBPReadingsToDB:uploadData withDeviceInfo:deviceInfo];
                }
                
                // Update UI with last element in Blood Pressure
                NSMutableDictionary *latestData = [uploadData lastObject];
                
                if(latestData) {
                    
                    [self updateUIWithVitalData:latestData];
                    
                }else {
                    
                    self.lblPeripheralError.text = @"No new blood pressure readings";
                }
            }
            
            // Activity Data
            else if([key isEqualToString:OMRONVitalDataActivityKey]) {
                
                NSMutableArray *activityData = vitalData[key];
                
                for (NSMutableDictionary *data in activityData) {
                    
                    for (NSString *activityKey in data.allKeys) {
                        
                        NSLog(@"Activity Data With Key : %@ \n %@ \n", activityKey, data[activityKey]);
                        
                        if([activityKey isEqualToString:OMRONActivityAerobicStepsPerDay] || [activityKey isEqualToString:OMRONActivityStepsPerDay] || [activityKey isEqualToString:OMRONActivityDistancePerDay] || [activityKey isEqualToString:OMRONActivityWalkingCaloriesPerDay]) {
                            
                            NSMutableDictionary *typeActivityData = data[activityKey];
                            
                            // Save to DB
                            [self saveActivityDataToDB:typeActivityData withDeviceInfo:deviceInfo withMainTable:@"ActivityData" withSubTable:@"ActivityDividedData" withType:activityKey];
                        }
                    }
                }
            }
            
            // Sleep Data
            else if([key isEqualToString:OMRONVitalDataSleepKey]) {
                
                NSMutableArray *sleepData = vitalData[key];
                
                for (NSMutableDictionary *data in sleepData) {
                    
                    NSLog(@"Sleep Data : %@", data);
                }
                
                // Save to DB
                [self saveSleepDataToDB:sleepData withDeviceInfo:deviceInfo withMainTable:@"SleepData"];
                
            }
            
            // Records Data
            else if([key isEqualToString:OMRONVitalDataRecordKey]) {
                
                NSLog(@"Record Data With Key : %@ \n %@ \n", key, vitalData[key]);
                
                NSMutableArray *recordsData = [vitalData objectForKey:key];
                
                // Save to DB
                [self saveRecordsDataToDB:recordsData withDeviceInfo:deviceInfo];
            }
        }
        
    }else {
        
        self.lblPeripheralError.text = @"No new readings transferred";
    }
    
    // To showcase delay and end data transfer - required when doing operations in app in between data transfer
    if(isWait)
        [self performSelector:@selector(continueDataTransfer) withObject:nil afterDelay:1.0];
    else
        [self continueDataTransfer];
    
}

- (void)continueDataTransfer {
    
    // End Data Transfer and update device
    [[OmronPeripheralManager sharedManager] endDataTransferFromPeripheralWithCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(error == nil) {
                
                NSLog(@"Device Information - %@", [peripheral getDeviceInformation]);
                NSLog(@"Device Settings - %@", [peripheral getDeviceSettings]);
                
                [peripheral getVitalDataWithCompletionBlock:^(NSMutableDictionary *vitalData, NSError *error) {
                    
                    if(error == nil) {
                        
                        if(vitalData.allKeys.count > 0) {
                            
                            NSLog(@"Vital Data - %@", vitalData);
                            
                            for (NSString *key in vitalData.allKeys) {
                                
                                if([key isEqualToString:OMRONVitalDataBloodPressureKey]) {
                                    
                                    NSMutableArray *uploadData = [vitalData objectForKey:key];
                                    NSMutableDictionary *latestData = [uploadData lastObject];
                                    
                                    if(latestData) {
                                        
                                        [self updateUIWithVitalData:latestData];
                                    }
                                }
                            }
                        }else {
                            
                            self.lblPeripheralError.text = @"No new readings transferred";
                        }
                    }
                }];
            }else {
                
                [self resetLabels];
                
                self.lblPeripheralErrorCode.text = [NSString stringWithFormat:@"Code: %ld", (long)error.code];
                self.lblPeripheralError.text = [error localizedDescription];
                
                NSLog(@"Error - %@", error);
            }
        });
    }];

}

#pragma mark -
#pragma mark - Data Save

- (void)saveBPReadingsToDB:(NSMutableArray *)dataList withDeviceInfo:(NSMutableDictionary *)deviceInfo {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    for (NSMutableDictionary *bpItem in dataList) {
        
        NSManagedObject *bpInfo = [NSEntityDescription
                                   insertNewObjectForEntityForName:@"BPData"
                                   inManagedObjectContext:context];
        
        
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataSystolicKey] forKey:@"systolic"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataDiastolicKey] forKey:@"diastolic"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataPulseKey] forKey:@"pulse"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataAtrialFibrillationDetectionFlagKey] forKey:@"afib"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataIrregularHeartBeatCountKey] forKey:@"irregularHBCount"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataIrregularFlagKey] forKey:@"irregularHBDisplay"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataMovementFlagKey] forKey:@"movementFlag"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataErrorCodeKey] forKey:@"errorCode"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataDisplayedErrorCodeNightModeKey] forKey:@"nightModeErrorCode"];
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataMeasurementModeKey] forKey:@"measurementMode"];
        
        [bpInfo setValue:[NSString stringWithFormat:@"%@", [bpItem valueForKey:OMRONVitalDataMeasurementStartDateKey]] forKey:@"startDate"];
        
        // Set Device Information
        [bpInfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
        [bpInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey]] forKey:@"displayName"];
        [bpInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationIdentityNameKey]] forKey:@"deviceIdentity"];
        [bpInfo setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:@"category"];
        
        [bpInfo setValue:[bpItem valueForKey:OMRONVitalDataUserIdKey] forKey:@"user"];
        
        NSError *error;
        if (![context save:&error]) {
            
        }
    }
}

- (void)saveActivityDataToDB:(NSMutableDictionary *)data withDeviceInfo:(NSMutableDictionary *)deviceInfo withMainTable:(NSString *)mainTable withSubTable:(NSString *)subTable withType:(NSString *)type {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    NSManagedObject *stepInfo = [NSEntityDescription
                                 insertNewObjectForEntityForName:mainTable
                                 inManagedObjectContext:context];
    
    [stepInfo setValue:[NSString stringWithFormat:@"%@", [data valueForKey:OMRONActivityDataStartDateKey]] forKey:@"startDate"];
    [stepInfo setValue:[NSString stringWithFormat:@"%@", [data valueForKey:OMRONActivityDataEndDateKey]] forKey:@"endDate"];
    [stepInfo setValue:[NSString stringWithFormat:@"%@", [data valueForKey:OMRONActivityDataMeasurementKey]] forKey:@"measurement"];
    [stepInfo setValue:[NSString stringWithFormat:@"%@", [data valueForKey:OMRONActivityDataSequenceKey]] forKey:@"sequence"];
    [stepInfo setValue:type forKey:@"type"];
    
    
    // Set Device Information
    [stepInfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
    [stepInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey]] forKey:@"displayName"];
    [stepInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationIdentityNameKey]] forKey:@"deviceIdentity"];
    [stepInfo setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:@"category"];
    
    NSError *error;
    if ([context save:&error]) {
        
        NSManagedObjectContext *dividedContext = [appDel managedObjectContext];
        
        for (NSMutableDictionary *dividedData in [data objectForKey:OMRONActivityDataDividedDataKey]) {
            
            NSManagedObject *stepDividedInfo = [NSEntityDescription
                                                insertNewObjectForEntityForName:subTable
                                                inManagedObjectContext:dividedContext];
            
            [stepDividedInfo setValue:[NSString stringWithFormat:@"%@", [dividedData valueForKey:OMRONActivityDividedDataMeasurementKey]] forKey:@"measurement"];
            [stepDividedInfo setValue:[NSString stringWithFormat:@"%@", [dividedData valueForKey:OMRONActivityDividedDataStartDateKey]] forKey:@"startDate"];
            [stepDividedInfo setValue:[NSString stringWithFormat:@"%@", [data valueForKey:OMRONActivityDataSequenceKey]] forKey:@"sequence"];
            [stepDividedInfo setValue:type forKey:@"type"];
            
            [stepDividedInfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
            
            NSError *errorDivided;
            if (![dividedContext save:&errorDivided]) {
                
                NSLog(@"Error Saving Divided Data");
            }
        }
    }else {
        
        NSLog(@"Error Saving Activity Data");
    }
}

- (void)saveSleepDataToDB:(NSMutableArray *)dataList withDeviceInfo:(NSMutableDictionary *)deviceInfo withMainTable:(NSString *)mainTable {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    for (NSMutableDictionary *sleepData in dataList) {
        
        NSManagedObject *sleepInfo = [NSEntityDescription
                                      insertNewObjectForEntityForName:mainTable
                                      inManagedObjectContext:context];
        
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepDataStartDateKey]] forKey:@"startDate"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepDataEndDateKey]] forKey:@"endDate"];
        
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepTimeInBedKey]] forKey:@"timeInBed"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepSleepOnsetTimeKey]] forKey:@"onSetTime"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepWakeTimeKey]] forKey:@"wakeTime"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepTotalSleepTimeKey]] forKey:@"totalSleepTime"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepSleepEfficiencyKey]] forKey:@"efficiency"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [sleepData valueForKey:OMRONSleepArousalDuringSleepTimeKey]] forKey:@"arousalDuringSleepTime"];
        
        NSError *error1;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[sleepData valueForKey:OMRONSleepBodyMotionLevelKey] options:NSJSONWritingPrettyPrinted error:&error1];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", jsonString] forKey:@"bodyMotionLevel"];
        
        // Set Device Information
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey]] forKey:@"displayName"];
        [sleepInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationIdentityNameKey]] forKey:@"deviceIdentity"];
        [sleepInfo setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:@"category"];
        
        NSError *error;
        if ([context save:&error]) {
            
            
        }else {
            
            NSLog(@"Error Saving Sleep Data");
        }
    }
}

- (void)saveRecordsDataToDB:(NSMutableArray *)dataList withDeviceInfo:(NSMutableDictionary *)deviceInfo {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    for (NSMutableDictionary *recordData in dataList) {
        
        NSManagedObject *recordInfo = [NSEntityDescription
                                       insertNewObjectForEntityForName:@"RecordData"
                                       inManagedObjectContext:context];
        
        [recordInfo setValue:[NSString stringWithFormat:@"%@", [recordData valueForKey:OMRONRecordDataDateKey]] forKey:@"startDate"];
        
        // Set Device Information
        [recordInfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
        [recordInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey]] forKey:@"displayName"];
        [recordInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationIdentityNameKey]] forKey:@"deviceIdentity"];
        [recordInfo setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:@"category"];
        
        NSError *error;
        if ([context save:&error]) {
            
        }else {
            
            NSLog(@"Error Saving Activity Records Data");
        }
    }
}

#pragma mark -
#pragma mark - CoreBluetooth Notifications

- (void)centralManagerDidUpdateStateNotification:(NSNotification *)aNotification {
    
    OMRONBLEBluetoothState bluetoothState = (OMRONBLEBluetoothState)[aNotification.object unsignedIntegerValue] ;
    
    if(bluetoothState == OMRONBLEBluetoothStateOn) {
        NSLog(@"%@",  @"Bluetooth is currently powered on.");
    }else if(bluetoothState == OMRONBLEBluetoothStateOff) {
        NSLog(@"%@",  @"Bluetooth is currently powered off.");
    }else if(bluetoothState == OMRONBLEBluetoothStateUnknown) {
        NSLog(@"%@",  @"Bluetooth is in unknown state");
    }
}

- (void)peripheralDisconnected {
    
    NSLog(@"Omron Peripheral Disconnected");
}

- (void)setConnectionStateNotifications {
    
    [[OmronPeripheralManager sharedManager] onConnectStateChangeWithCompletionBlock:^(int state) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSString *status = @"-";
            
            if (state == OMRONBLEConnectionStateConnecting) {
                status = @"Connecting...";
            } else if (state == OMRONBLEConnectionStateConnected) {
                status = @"Connected";
            } else if (state == OMRONBLEConnectionStateDisconnecting) {
                status = @"Disconnecting...";
            } else if (state == OMRONBLEConnectionStateDisconnect) {
                status = @"Disconnected";
            }
            
            self.lblStatus.text = status;
        });
    }];
}

- (void)onPeriodicNotifications {
    
    [[OmronPeripheralManager sharedManager] onPeriodicWithCompletionBlock:^{
        
        NSLog(@"Periodic call from device");
    }];
}

#pragma mark -
#pragma mark - Navigations and actions

- (IBAction)readingListButtonPressed:(id)sender {
    
    if(localPeripheral) {
        
        [localPeripheral getDeviceInformationWithCompletionBlock:^(NSMutableDictionary *deviceInfo, NSError *error) {
            
            NSLog(@"Device Information - %@", deviceInfo);
            
            NSMutableDictionary *currentDevice = [[NSMutableDictionary alloc] init];
            [currentDevice setValue:[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] forKey:@"localName"];
            [currentDevice setValue:[deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey] forKey:@"displayName"];
            [currentDevice setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:@"category"];
            
            if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBloodPressure) {
                
                // Blood Pressure Device
                BPReadingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BPReadingsViewController"];
                controller.selectedDevice = currentDevice;
                
                [self.navigationController pushViewController:controller animated:YES];
                
            }else if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
                
                // Blood Pressure Device
                VitalOptionsTableViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"VitalOptionsTableViewController"];
                controller.selectedDevice = currentDevice;
                
                [self.navigationController pushViewController:controller animated:YES];
                
            }
            
        }];
    }
}

- (IBAction)settingsButtonPressed:(id)sender {
    
    // Blood Pressure Device
    ReminderListTableViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"ReminderListTableViewController"];
    controller.selectedPeripheral = localPeripheral;
    controller.filterDeviceModel = self.filterDeviceModel;
    controller.settingsModel = self.settingsModel;
    
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark -
#pragma mark - Settings update for Connectivity library

- (void)updateSettings {
    
    OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
    
    // Filter device to scan and connect (optional)
    if([self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceGroupIDKey] && [self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]) {
        
        NSMutableArray *filterDevices = [[NSMutableArray alloc] init];
        
        // New Supported Format - Add entire data model to filter list
        [filterDevices addObject:self.filterDeviceModel];
        
        peripheralConfig.deviceFilters = filterDevices;// Filter Devices
    }
    
    // Set Scan timeout interval (optional)
    peripheralConfig.timeoutInterval = 60; // Seconds
    
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] != OMRONBLEDeviceCategoryActivity) {
        peripheralConfig.enableAllDataRead = YES;
    }
    
    NSMutableArray *deviceSettigs = [[NSMutableArray alloc] init];
    
    // Set Personal Settings in Configuration (mandatory for Activity devices)
    if([[self.settingsModel allKeys] count] > 1 ) {
        
        NSLog(@"Settings Model - %@", self.settingsModel);
        
        NSDictionary *settings = @{ OMRONDevicePersonalSettingsUserHeightKey : self.settingsModel[@"personalHeight"],
                                    OMRONDevicePersonalSettingsUserWeightKey : self.settingsModel[@"personalWeight"],
                                    OMRONDevicePersonalSettingsUserStrideKey : self.settingsModel[@"personalStride"],
                                    OMRONDevicePersonalSettingsTargetStepsKey : @"1000",
                                    OMRONDevicePersonalSettingsTargetSleepKey : @"600"
        };
        
        NSMutableDictionary *personalSettings = [[NSMutableDictionary alloc] init];
        [personalSettings setObject:settings forKey:OMRONDevicePersonalSettingsKey];
        
        
        // Test Functions
        // Time Format
        NSDictionary *timeFormatSettings = @{ OMRONDeviceTimeSettingsFormatKey : @(OMRONDeviceTimeFormat24Hour) };
        NSMutableDictionary *timeSettings = [[NSMutableDictionary alloc] init];
        [timeSettings setObject:timeFormatSettings forKey:OMRONDeviceTimeSettingsKey];
        
        // Date Format
        NSDictionary *dateFormatSettings = @{ OMRONDeviceDateSettingsFormatKey : @(OMRONDeviceDateFormatMonthDay) };
        NSMutableDictionary *dateSettings = [[NSMutableDictionary alloc] init];
        [dateSettings setObject:dateFormatSettings forKey:OMRONDeviceDateSettingsKey];
        
        // Distance Format
        NSDictionary *distanceFormatSettings = @{ OMRONDeviceDistanceSettingsUnitKey : @(OMRONDeviceDistanceUnitKilometer) };
        NSMutableDictionary *distanceSettings = [[NSMutableDictionary alloc] init];
        [distanceSettings setObject:distanceFormatSettings forKey:OMRONDeviceDistanceSettingsKey];
        
        // Sleep Settings
        // TODO: Values to test
        NSDictionary *sleepTimeSettings = @{ OMRONDeviceSleepSettingsAutomaticKey: @(OMRONDeviceSleepAutomaticOff),
                                             OMRONDeviceSleepSettingsAutomaticStartTimeKey : @"4",
                                             OMRONDeviceSleepSettingsAutomaticStopTimeKey : @"9"
        };
        NSMutableDictionary *sleepSettings = [[NSMutableDictionary alloc] init];
        [sleepSettings setObject:sleepTimeSettings forKey:OMRONDeviceSleepSettingsKey];
        
        // Alarm Settings
        
        // Alarm1 Time
        NSMutableDictionary *alarmTime1 = [[NSMutableDictionary alloc] init];
        [alarmTime1 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
        [alarmTime1 setValue:@"54" forKey:OMRONDeviceAlarmSettingsMinuteKey];
        // Alarm1 Days (SUN-SAT)
        // Enable – 1, Disable - 0
        NSMutableDictionary *alarmDays1 = [[NSMutableDictionary alloc] init];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
        [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
        // Set Alarm and Time Settings
        NSMutableDictionary *alarm1 = [[NSMutableDictionary alloc] init];
        [alarm1 setObject: alarmDays1 forKey: OMRONDeviceAlarmSettingsDaysKey];
        [alarm1 setObject: alarmTime1 forKey: OMRONDeviceAlarmSettingsTimeKey];
        [alarm1 setValue:@(OMRONDeviceAlarmTypeMeasure) forKey: OMRONDeviceAlarmSettingsTypeKey];
        
        // Alarm2 Time
        NSMutableDictionary *alarmTime2 = [[NSMutableDictionary alloc] init];
        [alarmTime2 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
        [alarmTime2 setValue:@"56" forKey:OMRONDeviceAlarmSettingsMinuteKey];
        // Alarm2 Days (SUN-SAT)
        // Enable – 1, Disable - 0
        NSMutableDictionary *alarmDays2 = [[NSMutableDictionary alloc] init];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
        [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
        // Set Alarm and Time Settings
        NSMutableDictionary *alarm2 = [[NSMutableDictionary alloc] init];
        [alarm2 setObject: alarmDays2 forKey: OMRONDeviceAlarmSettingsDaysKey];
        [alarm2 setObject: alarmTime2 forKey: OMRONDeviceAlarmSettingsTimeKey];
        [alarm2 setValue:@(OMRONDeviceAlarmTypeNormal) forKey: OMRONDeviceAlarmSettingsTypeKey];
        
        
        // Alarm3 Time
        NSMutableDictionary *alarmTime3 = [[NSMutableDictionary alloc] init];
        [alarmTime3 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
        [alarmTime3 setValue:@"58" forKey:OMRONDeviceAlarmSettingsMinuteKey];
        // Alarm3 Days (SUN-SAT)
        // Enable – 1, Disable - 0
        NSMutableDictionary *alarmDays3 = [[NSMutableDictionary alloc] init];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
        [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
        // Set Alarm and Time Settings
        NSMutableDictionary *alarm3 = [[NSMutableDictionary alloc] init];
        [alarm3 setObject: alarmDays3 forKey: OMRONDeviceAlarmSettingsDaysKey];
        [alarm3 setObject: alarmTime3 forKey: OMRONDeviceAlarmSettingsTimeKey];
        [alarm3 setValue:@(OMRONDeviceAlarmTypeMedication) forKey: OMRONDeviceAlarmSettingsTypeKey];
        
        // Add Alarm1, Alarm2, Alarm3 to List
        NSMutableArray *alarms = [[NSMutableArray alloc] init];
        [alarms addObject: alarm1];
        [alarms addObject: alarm2];
        [alarms addObject: alarm3];
        
        NSMutableDictionary *alarmSettings = [[NSMutableDictionary alloc] init];
        [alarmSettings setObject:alarms forKey:OMRONDeviceAlarmSettingsKey];
        
        NSMutableArray *notificationEnabledList = [[NSMutableArray alloc] init];
        [notificationEnabledList addObject:@"com.google.Gmail"];
        [notificationEnabledList addObject:@"com.apple.mobilemail"];
        [notificationEnabledList addObject:@"com.apple.mobilephone"];
        [notificationEnabledList addObject:@"com.apple.MobileSMS"];
        
        NSMutableDictionary *notificationSettings = [[NSMutableDictionary alloc] init];
        [notificationSettings setObject:notificationEnabledList forKey:OMRONDeviceNotificationSettingsKey];
        
        // Notification enable settings
        NSDictionary *notificationEnableSettings = @{ OMRONDeviceNotificationStatusKey : @(OMRONDeviceNotificationStatusOff) };
        NSMutableDictionary *notificationSettingsEnable = [[NSMutableDictionary alloc] init];
        [notificationSettingsEnable setObject:notificationEnableSettings forKey:OMRONDeviceNotificationEnableSettingsKey];
        
        
        [deviceSettigs addObject:personalSettings];
        [deviceSettigs addObject:notificationSettingsEnable];
        [deviceSettigs addObject:timeSettings];
        [deviceSettigs addObject:dateSettings];
        [deviceSettigs addObject:distanceSettings];
        [deviceSettigs addObject:sleepSettings];
        [deviceSettigs addObject:alarmSettings];
        [deviceSettigs addObject:notificationSettings];
        
        peripheralConfig.deviceSettings = deviceSettigs;
    }
    
    peripheralConfig.deviceSettings = deviceSettigs;
    
    
    // Set User Hash Id (mandatory)
    peripheralConfig.userHashId = @"<email_address_of_user>"; // Email address of logged in User
    
    // Set Configuration to New Configuration (mandatory to set configuration)
    [(OmronPeripheralManager *)[OmronPeripheralManager sharedManager] setConfiguration:peripheralConfig];
}

- (void)getBloodPressureSettings:(NSMutableArray **)deviceSettings withPairing:(BOOL)pairing{
    
    // Blood Pressure
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryBloodPressure) {
        
        // Blood Pressure Settings (Personal settings)
        NSDictionary *bloodPressurePersonalSettings = @{ OMRONDevicePersonalSettingsBloodPressureDCIKey: @(OMRONDevicePersonalSettingsBloodPressureDCINotAvailable),
                                                         OMRONDevicePersonalSettingsBloodPressureTruReadEnableKey : @(OMRONDevicePersonalSettingsBloodPressureTruReadOn),
                                                         OMRONDevicePersonalSettingsBloodPressureTruReadIntervalKey : @(OMRONDevicePersonalSettingsBloodPressureTruReadInterval30)
        };
        NSDictionary *settings = @{ OMRONDevicePersonalSettingsBloodPressureKey : bloodPressurePersonalSettings };
        
        NSMutableDictionary *personalSettings = [[NSMutableDictionary alloc] init];
        [personalSettings setObject:settings forKey:OMRONDevicePersonalSettingsKey];
        
        NSMutableDictionary *scanSettings = [[NSMutableDictionary alloc] init];
        if(pairing) {
            // Pairing settings
            NSDictionary *scanModeSettings = @{ OMRONDeviceScanSettingsModeKey : @(OMRONDeviceScanSettingsModePairing) };
            [scanSettings setObject:scanModeSettings forKey:OMRONDeviceScanSettingsKey];
        }else {
            // Transfer settings
            NSDictionary *scanModeSettings = @{ OMRONDeviceScanSettingsModeKey : @(OMRONDeviceScanSettingsModeMismatchSequence) };
            [scanSettings setObject:scanModeSettings forKey:OMRONDeviceScanSettingsKey];
        }
        
        [*deviceSettings addObject:personalSettings];
        [*deviceSettings addObject:scanSettings];
    }
}

- (void)getActivitySettings:(NSMutableArray **)deviceSettings {
    
    // Activity
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
        
        // Set Personal Settings in Configuration (mandatory for Activity devices)
        if([[self.settingsModel allKeys] count] > 1 ) {
            
            NSLog(@"Settings Model - %@", self.settingsModel);
            
            NSDictionary *settings = @{ OMRONDevicePersonalSettingsUserHeightKey : self.settingsModel[@"personalHeight"],
                                        OMRONDevicePersonalSettingsUserWeightKey : self.settingsModel[@"personalWeight"],
                                        OMRONDevicePersonalSettingsUserStrideKey : self.settingsModel[@"personalStride"],
                                        OMRONDevicePersonalSettingsTargetStepsKey : @"1000",
                                        OMRONDevicePersonalSettingsTargetSleepKey : @"420"
            };
            
            NSMutableDictionary *personalSettings = [[NSMutableDictionary alloc] init];
            [personalSettings setObject:settings forKey:OMRONDevicePersonalSettingsKey];
            
            
            // Test Functions
            // Time Format
            NSDictionary *timeFormatSettings = @{ OMRONDeviceTimeSettingsFormatKey : @(OMRONDeviceTimeFormat12Hour) };
            NSMutableDictionary *timeSettings = [[NSMutableDictionary alloc] init];
            [timeSettings setObject:timeFormatSettings forKey:OMRONDeviceTimeSettingsKey];
            
            // Date Format
            NSDictionary *dateFormatSettings = @{ OMRONDeviceDateSettingsFormatKey : @(OMRONDeviceDateFormatDayMonth) };
            NSMutableDictionary *dateSettings = [[NSMutableDictionary alloc] init];
            [dateSettings setObject:dateFormatSettings forKey:OMRONDeviceDateSettingsKey];
            
            // Distance Format
            NSDictionary *distanceFormatSettings = @{ OMRONDeviceDistanceSettingsUnitKey : @(OMRONDeviceDistanceUnitMile) };
            NSMutableDictionary *distanceSettings = [[NSMutableDictionary alloc] init];
            [distanceSettings setObject:distanceFormatSettings forKey:OMRONDeviceDistanceSettingsKey];
            
            // Sleep Settings
            // TODO: Values to test
            NSDictionary *sleepTimeSettings = @{ OMRONDeviceSleepSettingsAutomaticKey: @(OMRONDeviceSleepAutomaticOff),
                                                 OMRONDeviceSleepSettingsAutomaticStartTimeKey : @"3",
                                                 OMRONDeviceSleepSettingsAutomaticStopTimeKey : @"20"
            };
            NSMutableDictionary *sleepSettings = [[NSMutableDictionary alloc] init];
            [sleepSettings setObject:sleepTimeSettings forKey:OMRONDeviceSleepSettingsKey];
            
            // Alarm Settings
            
            // Alarm1 Time
            NSMutableDictionary *alarmTime1 = [[NSMutableDictionary alloc] init];
            [alarmTime1 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
            [alarmTime1 setValue:@"54" forKey:OMRONDeviceAlarmSettingsMinuteKey];
            // Alarm1 Days (SUN-SAT)
            // Enable – 1, Disable - 0
            NSMutableDictionary *alarmDays1 = [[NSMutableDictionary alloc] init];
            [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
            [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
            [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
            [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
            [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
            [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
            [alarmDays1 setValue: @(OMRONDeviceAlarmStatusOff) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
            // Set Alarm and Time Settings
            NSMutableDictionary *alarm1 = [[NSMutableDictionary alloc] init];
            [alarm1 setObject: alarmDays1 forKey: OMRONDeviceAlarmSettingsDaysKey];
            [alarm1 setObject: alarmTime1 forKey: OMRONDeviceAlarmSettingsTimeKey];
            [alarm1 setValue:@(OMRONDeviceAlarmTypeMeasure) forKey: OMRONDeviceAlarmSettingsTypeKey];
            
            // Alarm2 Time
            NSMutableDictionary *alarmTime2 = [[NSMutableDictionary alloc] init];
            [alarmTime2 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
            [alarmTime2 setValue:@"56" forKey:OMRONDeviceAlarmSettingsMinuteKey];
            // Alarm2 Days (SUN-SAT)
            // Enable – 1, Disable - 0
            NSMutableDictionary *alarmDays2 = [[NSMutableDictionary alloc] init];
            [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
            [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
            [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
            [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
            [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
            [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
            [alarmDays2 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
            // Set Alarm and Time Settings
            NSMutableDictionary *alarm2 = [[NSMutableDictionary alloc] init];
            [alarm2 setObject: alarmDays2 forKey: OMRONDeviceAlarmSettingsDaysKey];
            [alarm2 setObject: alarmTime2 forKey: OMRONDeviceAlarmSettingsTimeKey];
            [alarm2 setValue:@(OMRONDeviceAlarmTypeNormal) forKey: OMRONDeviceAlarmSettingsTypeKey];
            
            
            // Alarm3 Time
            NSMutableDictionary *alarmTime3 = [[NSMutableDictionary alloc] init];
            [alarmTime3 setValue:@"16" forKey:OMRONDeviceAlarmSettingsHourKey];
            [alarmTime3 setValue:@"58" forKey:OMRONDeviceAlarmSettingsMinuteKey];
            // Alarm3 Days (SUN-SAT)
            // Enable – 1, Disable - 0
            NSMutableDictionary *alarmDays3 = [[NSMutableDictionary alloc] init];
            [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySundayKey];
            [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayMondayKey];
            [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayTuesdayKey];
            [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayWednesdayKey];
            [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayThursdayKey];
            [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDayFridayKey];
            [alarmDays3 setValue: @(OMRONDeviceAlarmStatusOn) forKey: OMRONDeviceAlarmSettingsDaySaturdayKey];
            // Set Alarm and Time Settings
            NSMutableDictionary *alarm3 = [[NSMutableDictionary alloc] init];
            [alarm3 setObject: alarmDays3 forKey: OMRONDeviceAlarmSettingsDaysKey];
            [alarm3 setObject: alarmTime3 forKey: OMRONDeviceAlarmSettingsTimeKey];
            [alarm3 setValue:@(OMRONDeviceAlarmTypeMedication) forKey: OMRONDeviceAlarmSettingsTypeKey];
            
            // Add Alarm1, Alarm2, Alarm3 to List
            NSMutableArray *alarms = [[NSMutableArray alloc] init];
            [alarms addObject: alarm1];
            [alarms addObject: alarm2];
            [alarms addObject: alarm3];
            
            NSMutableDictionary *alarmSettings = [[NSMutableDictionary alloc] init];
            [alarmSettings setObject:alarms forKey:OMRONDeviceAlarmSettingsKey];
            
            NSMutableArray *notificationEnabledList = [[NSMutableArray alloc] init];
            [notificationEnabledList addObject:@"com.google.Gmail"];
            [notificationEnabledList addObject:@"com.apple.mobilemail"];
            [notificationEnabledList addObject:@"com.apple.mobilephone"];
            [notificationEnabledList addObject:@"com.apple.MobileSMS"];
            [notificationEnabledList addObject:@"com.omronhealthcare.connectivitylibrary"];
            
            NSMutableDictionary *notificationSettings = [[NSMutableDictionary alloc] init];
            [notificationSettings setObject:notificationEnabledList forKey:OMRONDeviceNotificationSettingsKey];
            
            // Notification enable settings
            NSDictionary *notificationEnableSettings = @{ OMRONDeviceNotificationStatusKey : @(OMRONDeviceNotificationStatusOn) };
            NSMutableDictionary *notificationSettingsEnable = [[NSMutableDictionary alloc] init];
            [notificationSettingsEnable setObject:notificationEnableSettings forKey:OMRONDeviceNotificationEnableSettingsKey];
            
            [*deviceSettings addObject:personalSettings];
            [*deviceSettings addObject:notificationSettingsEnable];
            [*deviceSettings addObject:notificationSettings];
            
            [*deviceSettings addObject:timeSettings];
            [*deviceSettings addObject:dateSettings];
            [*deviceSettings addObject:distanceSettings];
            [*deviceSettings addObject:sleepSettings];
            [*deviceSettings addObject:alarmSettings];
        }
    }
}


#pragma mark - Utility UI Functions

- (void)updateUIWithVitalData:(NSMutableDictionary *)vitalData {
    
    self.lblSysUnit.text = @"mmHg";
    self.lblDiaUnit.text = @"mmHg";
    self.lblPulseUnit.text = @"bpm";
    
    // Set display unit
    self.lblSysUnit.hidden = NO;
    self.lblDiaUnit.hidden = NO;
    self.lblPulseUnit.hidden = NO;
    
    self.lblSystolic.text =  [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONVitalDataSystolicKey]];
    self.lblDiastolic.text = [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONVitalDataDiastolicKey]];
    self.lblPulseRate.text = [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONVitalDataPulseKey]];
    
    NSDate *date = [vitalData valueForKey:OMRONVitalDataMeasurementDateKey];
    NSString *bpDate = [self stringFromDate:date
                                     locale:nil
                             withDateFormat:@"yyyy-MM-dd"
                             withTimeFormat:@"HH:mm:ss"];
    self.lblTimeStamp.text = bpDate;
}

- (void)resetLabels {
    
    [self.btnConnect setTitle:@"Scan" forState:UIControlStateNormal];
    
    self.devicesView.hidden = YES;
    self.searching.hidden = YES;
    
    self.lblSysUnit.hidden = YES;
    self.lblDiaUnit.hidden = YES;
    self.lblPulseUnit.hidden = YES;
    self.lblSystolic.text =  @"-";
    self.lblDiastolic.text = @"-";
    self.lblPulseRate.text = @"-";
    self.lblTimeStamp.text = @"-";
    self.lblStatus.text = @"-";
    self.lblPeripheralError.text = @"-";
    self.lblPeripheralErrorCode.text = @"-";
}


@end
