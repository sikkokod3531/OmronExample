//
//  BodyCompositionViewController.m
//  OmronLibrarySample
//
//  Created by Hitesh Bhardwaj on 09/04/19.
//  Copyright © 2019 Omron HealthCare Inc. All rights reserved.
//

#import  "QuartzCore/QuartzCore.h"
#import "BodyCompositionViewController.h"
#import "AppDelegate.h"
#import "WeightReadingsViewController.h"
#import "PersonalSettingsBodyCompositionViewController.h"

@interface BodyCompositionViewController ()<UITableViewDataSource, UITableViewDelegate, PersonalSettingsBodyCompositionViewControllerDelegate> {
    
    // Tracks Connected Omron Peripheral
    OmronPeripheral *localPeripheral;
    
    NSMutableArray *scannedPeripheral;
    
    BOOL isScanning;
}
@property (weak, nonatomic) IBOutlet UILabel *lblTimeStamp;
@property (weak, nonatomic) IBOutlet UILabel *lblWeight;
@property (weak, nonatomic) IBOutlet UILabel *lblWeightUnit;
@property (weak, nonatomic) IBOutlet UILabel *lblBodyFat;
@property (weak, nonatomic) IBOutlet UILabel *lblRestingMetabolism;
@property (weak, nonatomic) IBOutlet UILabel *lblSkeletalMuscle;
@property (weak, nonatomic) IBOutlet UILabel *lblBMI;
@property (weak, nonatomic) IBOutlet UILabel *lblDCI;
@property (weak, nonatomic) IBOutlet UILabel *lblVisceralFat;
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;
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

@implementation BodyCompositionViewController

#pragma mark - View Controller Life cycles

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
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
    
    // Start OmronPeripheralManager
    [self startOmronPeripheralManagerWithHistoricRead:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (localPeripheral != nil) {
        // Set DCI
        // For each user number
        [self updateDCI:localPeripheral];
    }
}

- (void)updateDCI:(OmronPeripheral *)peripheral {
    NSMutableArray *dci = [[NSMutableArray alloc] init];
    
    for (NSNumber *userNumber in self.users) {
        int selectedUser = userNumber.intValue;
        id deviceSettings = [peripheral getDeviceSettingsWithUser:selectedUser];
        if(![deviceSettings isKindOfClass:[NSError class]]) {
            NSNumber *dciValue = [[deviceSettings valueForKey:OMRONDevicePersonalSettingsWeightKey] valueForKey:OMRONDevicePersonalSettingsWeightDCIKey];
            [dci addObject:dciValue];
        }
    }
    self.lblDCI.text =  [dci componentsJoinedByString:@","];
}

// Start Omron Peripheral Manager
- (void)startOmronPeripheralManagerWithHistoricRead:(BOOL)isHistoric {
    
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
    
    // Set Device settings to the peripheral
    peripheralConfig.deviceSettings = self.deviceSettings;
    
    // Set User Hash Id (mandatory)
    peripheralConfig.userHashId = @"<email_address_of_user>"; // Email address of logged in User
    
    // Disclaimer: Read definition before usage
    peripheralConfig.enableAllDataRead = isHistoric;
    
    peripheralConfig.enableiBeaconWithTransfer = true;
    
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
        //         OmronPeripheral *peripheralLocal = [[OmronPeripheral alloc] initWithLocalName:peripheral.localName andUUID:peripheral.UUID];
        
        if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceUsersKey] intValue] == 1 || self.pairType == weight) {
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
    
    // Connects to Peripheral and Pairs device + Wait
    [[OmronPeripheralManager sharedManager] connectPeripheral:peripheral withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
        [self connectionUpdateWithPeripheral:peripheral withError:error withWait:NO];
    }];
}

- (void)connectPeripheralWithWait:(OmronPeripheral *)peripheral {
    
    isScanning = NO;
    
    self.lblStatus.text = @"Connecting...";
    
    [self.btnConnect setTitle:@"Scan" forState:UIControlStateNormal];
    
    // Connects to Peripheral and Pairs device + Wait
    [[OmronPeripheralManager sharedManager] connectPeripheral:peripheral withWait:YES withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
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
            
            NSLog(@"Device Information - %@", [peripheral getDeviceInformation]);
            
            // Retrieves Peripheral Configuration with GroupId and GroupIncludedGroupID
            OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
            NSMutableDictionary *deviceConfig = [peripheralConfig retrievePeripheralConfigurationWithGroupId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIDKey] andGroupIncludedId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]];
            NSLog(@"Device Configuration - %@", deviceConfig);
            NSLog(@"Device Settings - %@", [peripheral getDeviceSettings]);
            
            // Wait
            if(wait) {
                [self performSelector:@selector(resumeConnection) withObject:nil afterDelay:2.0];
            }else {
                self.lblPeripheralError.text = @"Paired Successfully!";
                // Set DCI
                [self updateDCI:peripheral];
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
                
                NSLog(@"Device Information - %@", [peripheral getDeviceInformation]);
                
                // Retrieves Peripheral Configuration with GroupId and GroupIncludedGroupID
                OmronPeripheralManagerConfig *peripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
                NSMutableDictionary *deviceConfig = [peripheralConfig retrievePeripheralConfigurationWithGroupId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIDKey] andGroupIncludedId:[peripheral valueForKey:OMRONBLEConfigDeviceGroupIncludedGroupIDKey]];
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
    
    [self resetLabels];
    
    if(localPeripheral) {
        
        // BCM Weight only option
        if(self.pairType == weight) {
        
            [self startOmronPeripheralManagerWithHistoricRead:NO];
            [self performDataTransfer];
            return;
        }
        
        UIAlertController *transferType = [UIAlertController
                                          alertControllerWithTitle:@"Transfer"
                                          message:@"Do you want to transfer all historic readings from device?"
                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okButton = [UIAlertAction
                                   actionWithTitle:@"Yes"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
            
            [self startOmronPeripheralManagerWithHistoricRead:YES];
            [self performDataTransfer];
            
        }];
        UIAlertAction *cancelButton = [UIAlertAction
                                   actionWithTitle:@"No"
                                   style:UIAlertActionStyleDestructive
                                   handler:^(UIAlertAction * action) {
            
            [self startOmronPeripheralManagerWithHistoricRead:NO];
            [self performDataTransfer];
        }];
        
        [transferType addAction:okButton];
        [transferType addAction:cancelButton];
        [self presentViewController:transferType animated:YES completion:nil];
    
    }else {
        
        self.lblPeripheralError.text = @"No device paired";
    }
}

- (void)performDataTransfer {
    
    // Connection State
    [self setConnectionStateNotifications];
    
    OmronPeripheral *peripheralLocal = [[OmronPeripheral alloc] initWithLocalName:localPeripheral.localName andUUID:localPeripheral.UUID];
    
    self.lblStatus.text = @"Connecting...";
    
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
    
    /*
     * Starts Data Transfer from Omron Peripherals.
     * endDataTransferFromPeripheralWithCompletionBlock of OmronConnectivityLibrary need to be called once data retrieved is saved
     * For single user device, selected user will be passed as 1
     * withWait : Only YES is supported now
     */
    [[OmronPeripheralManager sharedManager] startDataTransferFromPeripheral:peripheral withUser:[[self.users firstObject] intValue] withWait:YES withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
        
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
    NSLog(@"Device Information - %@", deviceInfo);
    
    if(vitalData.allKeys.count > 0) {
        
        for (NSString *key in vitalData.allKeys) {
            
            // Blood Pressure Data
            if([key isEqualToString:OMRONVitalDataWeightKey]) {
                
                NSMutableArray *uploadData = [vitalData objectForKey:key];
                
                // Save to DB
                if([uploadData count] > 0) {
                    
                    NSLog(@"Weight Data - %@", uploadData);
                    
                    [self saveWeightReadingsToDB:uploadData withDeviceInfo:deviceInfo];
                }
                
                // Update UI with last element in Blood Pressure
                NSMutableDictionary *latestData = [uploadData lastObject];
                
                if(latestData) {
                    
                    [self updateUIWithVitalData:latestData];
                    
                }else {
                    
                    self.lblPeripheralError.text = @"No new weight readings";
                }
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

- (void)saveWeightReadingsToDB:(NSMutableArray *)dataList withDeviceInfo:(NSMutableDictionary *)deviceInfo {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    for (NSMutableDictionary *weightItem in dataList) {
        
        NSManagedObject *weightinfo = [NSEntityDescription
                                       insertNewObjectForEntityForName:@"WeightData"
                                       inManagedObjectContext:context];
        
        [weightinfo setValue:[NSString stringWithFormat:@"%@", [weightItem valueForKey:OMRONWeightDataStartDateKey]] forKey:@"startDate"];
        
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightKey] forKey:@"weight"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightBodyFatLevelClassificationKey] forKey:@"bodyFatLevelClassification"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightBodyFatPercentageKey] forKey:@"bodyFatPercentage"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightRestingMetabolismKey] forKey:@"restingMetabolism"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightSkeletalMusclePercentageKey] forKey:@"skeletalMusclePercentage"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightBMIKey] forKey:@"bMI"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightVisceralFatLevelKey] forKey:@"visceralFatLevel"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightVisceralFatLevelClassificationKey] forKey:@"visceralFatLevelClassification"];
        [weightinfo setValue:[NSString stringWithFormat:@"%@", [weightItem valueForKey:OMRONWeightSkeletalMuscleLevelClassificationKey]] forKey:@"skeletalMuscleLevelClassification"];
        
        // Set Device Information
        [weightinfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
        [weightinfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey]] forKey:@"displayName"];
        [weightinfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationIdentityNameKey]] forKey:@"deviceIdentity"];
        [weightinfo setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:@"category"];
        [weightinfo setValue:[weightItem valueForKey:OMRONWeightDataUserIdKey] forKey:@"user"];
        
        NSError *error;
        if (![context save:&error]) {
            
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
            
            // Weight Scale Device
            WeightReadingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"WeightReadingsViewController"];
            controller.selectedDevice = currentDevice;
            
            [self.navigationController pushViewController:controller animated:YES];
            
        }];
    }
}

- (IBAction)settingsButtonPressed:(id)sender {
    
    // Body Composition Device
    PersonalSettingsBodyCompositionViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PersonalSettingsBodyCompositionViewController"];
    controller.delegate = self;
    controller.selectedPeripheral = localPeripheral;
    controller.currentOperation = update;
    controller.users = self.users;
    
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark -
#pragma mark - Utility UI Functions

- (void)updateUIWithVitalData:(NSMutableDictionary *)vitalData {
    
    self.lblWeightUnit.text = @"Kg";
    
    // Set display unit
    self.lblWeightUnit.hidden = NO;
    
    self.lblWeight.text =  [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONWeightKey]];
    self.lblBodyFat.text = [NSString stringWithFormat:@"%@%%", [vitalData valueForKey:OMRONWeightBodyFatPercentageKey]];
    self.lblRestingMetabolism.text = [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONWeightRestingMetabolismKey]];
    self.lblSkeletalMuscle.text = [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONWeightSkeletalMusclePercentageKey]];
    self.lblBMI.text = [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONWeightBMIKey]];
    self.lblVisceralFat.text = [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONWeightVisceralFatLevelKey]];
    
    NSTimeInterval timeStamp = [[vitalData valueForKey:OMRONWeightDataStartDateKey] doubleValue];
    NSString *weightDate = [self stringFromDate:[NSDate dateWithTimeIntervalSince1970:timeStamp]
                                         locale:nil
                                 withDateFormat:@"yyyy-MM-dd"
                                 withTimeFormat:@"HH:mm:ss"];
    self.lblTimeStamp.text = weightDate;
}

- (void)resetLabels {
    
    [self.btnConnect setTitle:@"Scan" forState:UIControlStateNormal];
    
    self.devicesView.hidden = YES;
    self.searching.hidden = YES;
    self.lblStatus.text = @"-";
    self.lblPeripheralError.text = @"-";
    self.lblPeripheralErrorCode.text = @"-";
}

#pragma mark -
#pragma mark - PersonalSettingsBodyCompositionViewControllerDelegate

- (void)updateLocalPeripheral:(OmronPeripheral *)peripheral {
    localPeripheral = peripheral;
}

@end
