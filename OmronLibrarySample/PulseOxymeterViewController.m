//
//  PulseOxymeterViewController.m
//  OmronLibrarySample
//
//  Created by Shohei Tomoe on 2022/10/27.
//  Copyright © 2022 Omron HealthCare Inc. All rights reserved.
//

#import  "QuartzCore/QuartzCore.h"
#import "PulseOxymeterViewController.h"
#import "AppDelegate.h"
#import "PulseOxymeterReadingsViewController.h"

#import "AppDelegate.h"

@interface PulseOxymeterViewController () <UITableViewDataSource, UITableViewDelegate> {
    
    // Tracks Connected Omron Peripheral
    OmronPeripheral *localPeripheral;
    
    NSMutableArray *scannedPeripheral;
    
    BOOL isScanning;
    
    int counter;
}

@property (weak, nonatomic) IBOutlet UILabel *lblTimeStamp;
@property (weak, nonatomic) IBOutlet UILabel *lblSpO2;
@property (weak, nonatomic) IBOutlet UILabel *lblPulseRate;
@property (weak, nonatomic) IBOutlet UILabel *lblStatus;
@property (weak, nonatomic) IBOutlet UILabel *lblSpO2Unit;
@property (weak, nonatomic) IBOutlet UILabel *lblPulseRateUnit;
@property (weak, nonatomic) IBOutlet UILabel *lblLocalName;
@property (weak, nonatomic) IBOutlet UILabel *lblPeripheralErrorCode;
@property (weak, nonatomic) IBOutlet UILabel *lblPeripheralError;
@property (weak, nonatomic) IBOutlet UILabel *lbldeviceModel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *devicesView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *searching;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

- (IBAction)readingListButtonPressed:(id)sender;

@end

@implementation PulseOxymeterViewController

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
    
    // Disclaimer: Read definition before usage
    peripheralConfig.enableAllDataRead = isHistoric;
    
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
            [self startOmronPeripheralManagerWithHistoricRead:YES withPairing:NO];
            [self performDataTransfer];
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
            
            // PulseOximeter Data
            if([key isEqualToString:OMRONVitalDataPulseOximeterKey]) {
                
                NSMutableArray *uploadData = [vitalData objectForKey:key];
                
                // Save to DB
                if([uploadData count] > 0) {
                    NSLog(@"Pulse Oxymeter Data - %@", uploadData);
                    NSLog(@"Pulse Oxymeter Data With Key : %@ \n %@ \n", key, vitalData[key]);
                    
                    // Save to DB
                    [self savePulseOxymeterToDB:uploadData withDeviceInfo:deviceInfo];
                    
                }
                    
                // Update UI with last element in Palus Oxymeter
                NSMutableDictionary *latestData = [uploadData lastObject];
                
                if(latestData) {
                    
                    [self updateUIWithVitalData:latestData];
                    
                }else {
                    
                    self.lblPeripheralError.text = @"No new pluse Oxymeter readings";
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
                            
                            NSLog(@"Vital Data - %@", vitalData);
                            
                            for (NSString *key in vitalData.allKeys) {
                                
                                if([key isEqualToString:OMRONVitalDataPulseOximeterKey]) {
                                    
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

- (void)savePulseOxymeterToDB:(NSMutableArray *)dataList withDeviceInfo:(NSMutableDictionary *)deviceInfo {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    
    NSManagedObjectContext *context = [appDel managedObjectContext];
    
    for (NSMutableDictionary *bpItem in dataList) {
        
        NSManagedObject *poInfo = [NSEntityDescription
                                   insertNewObjectForEntityForName:@"PulseOxymeterData"
                                   inManagedObjectContext:context];
        
        
        [poInfo setValue:[bpItem valueForKey:OMRONPulseOximeterSPO2LevelKey] forKey:@"spO2"];
        [poInfo setValue:[bpItem valueForKey:OMRONPulseOximeterPulseRateKey] forKey:@"pulse"];
        
        [poInfo setValue:[NSString stringWithFormat:@"%@", [bpItem valueForKey:OMRONPulseOximeterDataStartDateKey]] forKey:@"startDate"];
        
        // Set Device Information
        [poInfo setValue:[NSString stringWithFormat:@"%@", [[deviceInfo valueForKey:OMRONDeviceInformationLocalNameKey] lowercaseString]] forKey:@"localName"];
        [poInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationDisplayNameKey]] forKey:@"displayName"];
        [poInfo setValue:[NSString stringWithFormat:@"%@", [deviceInfo valueForKey:OMRONDeviceInformationIdentityNameKey]] forKey:@"deviceIdentity"];
        [poInfo setValue:[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] forKey:@"category"];
        
        [poInfo setValue:[bpItem valueForKey:OMRONPulseOximeterDataUserIdKey] forKey:@"user"];
        
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
            
            if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryPulseOximeter) {
                
                PulseOxymeterReadingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PulseOxymeterReadingsViewController"];
                controller.selectedDevice = currentDevice;
                
                [self.navigationController pushViewController:controller animated:YES];
                
            }
            
        }];
    }
}

#pragma mark - Utility UI Functions

- (void)updateUIWithVitalData:(NSMutableDictionary *)vitalData {
    
    self.lblSpO2Unit.text = @"%";
    self.lblPulseRateUnit.text = @"bpm";
    
    // Set display unit
    self.lblSpO2Unit.hidden = NO;
    self.lblPulseRateUnit.hidden = NO;
    
    self.lblSpO2.text =  [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONPulseOximeterSPO2LevelKey]];
    self.lblPulseRate.text = [NSString stringWithFormat:@"%@", [vitalData valueForKey:OMRONPulseOximeterPulseRateKey]];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[vitalData valueForKey:OMRONPulseOximeterDataStartDateKey] doubleValue]];
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
    
    self.lblSpO2Unit.hidden = YES;
    self.lblPulseRateUnit.hidden = YES;
    self.lblSpO2.text =  @"-";
    self.lblPulseRate.text = @"-";
    self.lblTimeStamp.text = @"-";
    self.lblStatus.text = @"-";
    self.lblPeripheralError.text = @"-";
    self.lblPeripheralErrorCode.text = @"-";
}


@end

