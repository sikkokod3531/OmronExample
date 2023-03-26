//
//  PersonalSettingsBodyCompositionViewController.m
//  OmronLibrarySample
//
//  Created by Hitesh Bhardwaj on 11/04/19.
//  Copyright © 2019 Omron HealthCare Inc. All rights reserved.
//

#import "PersonalSettingsBodyCompositionViewController.h"
#import "BodyCompositionViewController.h"
#import "AppDelegate.h"

@interface PersonalSettingsBodyCompositionViewController () <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate> {
    
    NSArray *genderArray;
    NSArray *weightUnitArray;
    int selectedFieldForPicker;
    
    UIDatePicker *datePickerView;
    UIPickerView *dataPickerView;
}
@property (weak, nonatomic) IBOutlet UIView *dobOuterView;
@property (weak, nonatomic) IBOutlet UIView *heightOuterView;
@property (weak, nonatomic) IBOutlet UIView *genderOuterView;
@property (weak, nonatomic) IBOutlet UIView *dciOuterView;

- (IBAction)updateDeviceSettingsButtonPressed:(id)sender;

@end

@implementation PersonalSettingsBodyCompositionViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    NSString *title = @"Personal Settings";
    
    [self customNavigationBarTitle:title withFont:[UIFont fontWithName:@"Courier" size:16]];
    
    genderArray = [NSArray arrayWithObjects:@"Male", @"Female", nil];
    weightUnitArray = [NSArray arrayWithObjects:@"Kg", @"Lbs", @"St", nil];
    
    [self setupUI];
}

- (void)setupUI{
    
    // Set Update button title as per operation getting performed
    if (self.currentOperation == pair) {
        [self.updateButton setTitle:@"Next" forState:UIControlStateNormal];
    }else {
        [self.updateButton setTitle:@"Update" forState:UIControlStateNormal];
    }
    
    // Date Picker for Date of Birth
    datePickerView = [[UIDatePicker alloc] init];
    datePickerView.datePickerMode = UIDatePickerModeDate;
    if (@available(iOS 13.4, *)) {
        datePickerView.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    self.dateOfBirthField.inputView = datePickerView;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDate *currentDate = [NSDate date];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:0];
    NSDate *maxDate = [calendar dateByAddingComponents:comps toDate:currentDate options:0];
    [comps setYear:-119];
    NSDate *minDate = [calendar dateByAddingComponents:comps toDate:currentDate options:0];
    
    // Set Max and Min range
    [datePickerView setMaximumDate:maxDate];
    [datePickerView setMinimumDate:minDate];
    
    [datePickerView addTarget:self action:@selector(handleDatePicker:) forControlEvents:UIControlEventValueChanged];
    
    // Add tool bar with Done button to dismiss keyboard
    UIToolbar *toolBar=[[UIToolbar alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    [toolBar setTintColor:[UIColor grayColor]];
    UIBarButtonItem *doneBtn=[[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneButtonClicked)];
    UIBarButtonItem *space=[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [toolBar setItems:[NSArray arrayWithObjects:space,doneBtn, nil]];
    
    [self.dateOfBirthField setInputAccessoryView:toolBar];
    
    // Picker for choosing Gender and Weight Unit
    dataPickerView = [[UIPickerView alloc] init];
    dataPickerView.delegate = self;
    dataPickerView.dataSource = self;
    
    self.weightUnitField.inputView = dataPickerView;
    self.genderField.inputView = dataPickerView;
    
    [self.weightUnitField setInputAccessoryView:toolBar];
    [self.genderField setInputAccessoryView:toolBar];
    [self.heightField setInputAccessoryView:toolBar];
    [self.dciField setInputAccessoryView:toolBar];
    
    self.dciField.text = @"-1";
    
    // Weight only - hide sections
//    if(self.pairType == weight) {
//        self.dobOuterView.hidden = true;
//        self.heightOuterView.hidden = true;
//        self.genderOuterView.hidden = true;
//        self.dciOuterView.hidden = true;
//    }
    
    // Weight only - hide sections
    if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceUsersKey] intValue] == 1) {
        self.dobOuterView.hidden = true;
        self.heightOuterView.hidden = true;
        self.genderOuterView.hidden = true;
    }
}

- (void)handleDatePicker:(UIDatePicker *)sender {
    NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *localDateString = [dateFormatter stringFromDate:[sender date]];
    self.dateOfBirthField.text = localDateString;
}

- (void)doneButtonClicked{
    // Set default values that comes on picker, if user hasn't selected anything from it
    if (selectedFieldForPicker == 0) {
        [self handleDatePicker:datePickerView];
    }else if (selectedFieldForPicker == 2){
        self.weightUnitField.text = [weightUnitArray objectAtIndex:[dataPickerView selectedRowInComponent:0]];
    }else if (selectedFieldForPicker == 3){
        self.genderField.text = [genderArray objectAtIndex:[dataPickerView selectedRowInComponent:0]];
    }
    [self.view endEditing:true];
}

#pragma mark - Textfield Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    selectedFieldForPicker = (int)textField.tag;
    [dataPickerView reloadAllComponents];
    return true;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == _dciField) {
        NSCharacterSet *numbersOnly = [NSCharacterSet characterSetWithCharactersInString:@"-0123456789"];
        NSString *textString = [textField.text stringByAppendingString:string];
        NSCharacterSet *characterSetFromTextField = [NSCharacterSet characterSetWithCharactersInString:textString];
        
        BOOL stringIsValid = [numbersOnly isSupersetOfSet:characterSetFromTextField];
        return stringIsValid;
    }
    return  YES;
}

#pragma mark - Picker View Data Source and Delegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 1;  // Or return whatever as you intend
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView
numberOfRowsInComponent:(NSInteger)component {
    if (selectedFieldForPicker == 2){
        return [weightUnitArray count];
    }else if (selectedFieldForPicker == 3){
        return [genderArray count];
    }
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)thePickerView
             titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (selectedFieldForPicker == 2){
        return [weightUnitArray objectAtIndex:row];
    }else if (selectedFieldForPicker == 3){
        return [genderArray objectAtIndex:row];
    }
    return @"";
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (selectedFieldForPicker == 2){
        self.weightUnitField.text = [weightUnitArray objectAtIndex:row];
    }else if (selectedFieldForPicker == 3){
        self.genderField.text = [genderArray objectAtIndex:row];
    }
}

- (BOOL)validatePersonalInformation {
    
    // Weight only
    if(self.pairType == weight) {
        if(self.weightUnitField.text.length == 0 || self.dciField.text.length == 0) {
            return false;
        }
    }else {
        if([[self.filterDeviceModel valueForKey:OMRONBLEConfigDeviceUsersKey] intValue] == 1) {
            if (self.weightUnitField.text.length == 0 || self.dciField.text.length == 0) {
                return false;
            }
        }else {
            if (self.dateOfBirthField.text.length == 0 || self.heightField.text.length == 0 || self.weightUnitField.text.length == 0 || self.genderField.text.length == 0 || self.dciField.text.length == 0) {
                return false;
            }
        }
    }
    return true;
}

- (IBAction)updateDeviceSettingsButtonPressed:(id)sender {
    
    if ([self validatePersonalInformation] == false) {
        
        [self showAlertWithTitle:@"All fields are mandatory" withAction:NO];
        
        return;
    }
    
    if (self.currentOperation == pair){
        
        NSMutableArray *deviceSettings = [[NSMutableArray alloc] init];
        
        // Common Settings
        NSNumber *weightUnit = @(OMRONDeviceWeightUnitKg);
        if ([self.weightUnitField.text isEqualToString:[weightUnitArray objectAtIndex:1]]) {
            weightUnit = @(OMRONDeviceWeightUnitLbs);
        }else if ([self.weightUnitField.text isEqualToString:[weightUnitArray objectAtIndex:2]]){
            weightUnit = @(OMRONDeviceWeightUnitSt);
        }
        
        // Weight Settings
        // Add other weight common settings if any
        NSDictionary *weightCommonSettings = @{};
        
        // Weight only
        if(self.pairType == weight) {
            // Unit and Weight only
            weightCommonSettings = @{ OMRONDeviceWeightSettingsUnitKey : weightUnit, OMRONDeviceWeightSettingsWeightOnlyKey: @(OMRONDeviceWeightOnlyOff), OMRONDeviceWeightSettingsOneTimeMeasurementKey: @(OMRONDeviceWeightOneTimeMeasurementOn)};
            
            // Weight Settings (Personal settings)
            NSDictionary *weightPersonalSettings = @{ OMRONDevicePersonalSettingsWeightDCIKey: [self getNumberFromString:self.dciField.text]};
            
            NSNumber *gender = @(OMRONDevicePersonalSettingsUserGenderTypeMale);
            if ([self.genderField.text isEqualToString:[genderArray objectAtIndex:1]]) {
                gender = @(OMRONDevicePersonalSettingsUserGenderTypeFemale);
            }
            
            NSDictionary *settings = @{ OMRONDevicePersonalSettingsUserHeightKey : [self roundFloatNumber:[self.heightField.text floatValue] exponent:2.0],
                                        OMRONDevicePersonalSettingsUserDateOfBirthKey : [self.dateOfBirthField.text stringByReplacingOccurrencesOfString:@"-" withString:@""],
                                        OMRONDevicePersonalSettingsUserGenderKey : gender,
                                        OMRONDevicePersonalSettingsWeightKey : weightPersonalSettings
            };
            
            NSMutableDictionary *personalSettings = [[NSMutableDictionary alloc] init];
            [personalSettings setObject:settings forKey:OMRONDevicePersonalSettingsKey];
            
            [deviceSettings addObject:personalSettings];
            
        }else {
            weightCommonSettings = @{ OMRONDeviceWeightSettingsUnitKey : weightUnit};
            // Weight Settings (Personal settings)
            NSDictionary *weightPersonalSettings = @{ OMRONDevicePersonalSettingsWeightDCIKey: [self getNumberFromString:self.dciField.text]};
            
            NSNumber *gender = @(OMRONDevicePersonalSettingsUserGenderTypeMale);
            if ([self.genderField.text isEqualToString:[genderArray objectAtIndex:1]]) {
                gender = @(OMRONDevicePersonalSettingsUserGenderTypeFemale);
            }
            
            NSDictionary *settings = @{ OMRONDevicePersonalSettingsUserHeightKey : [self roundFloatNumber:[self.heightField.text floatValue] exponent:2.0],
                                        OMRONDevicePersonalSettingsUserDateOfBirthKey : [self.dateOfBirthField.text stringByReplacingOccurrencesOfString:@"-" withString:@""],
                                        OMRONDevicePersonalSettingsUserGenderKey : gender,
                                        OMRONDevicePersonalSettingsWeightKey : weightPersonalSettings
            };
            
            NSMutableDictionary *personalSettings = [[NSMutableDictionary alloc] init];
            [personalSettings setObject:settings forKey:OMRONDevicePersonalSettingsKey];
            
            [deviceSettings addObject:personalSettings];
        }
        
        NSMutableDictionary *weightSettings = [[NSMutableDictionary alloc] init];
        [weightSettings setObject:weightCommonSettings forKey:OMRONDeviceWeightSettingsKey];
        
        [deviceSettings addObject:weightSettings];
        
        BodyCompositionViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BodyCompositionViewController"];
        controller.filterDeviceModel = self.filterDeviceModel;
        controller.users = self.users;
        controller.deviceSettings = deviceSettings;
        controller.pairType = self.pairType;
        [self.navigationController pushViewController:controller animated:YES];
        
    }else {
        
        // TODO: Check if all settings are returned properly and then set
        
        // Retrieve existing configuration
        OmronPeripheralManagerConfig *existingPeripheralConfig = [[OmronPeripheralManager sharedManager] getConfiguration];
        NSMutableArray *exitingDeviceSettings = [[NSMutableArray alloc] initWithArray:existingPeripheralConfig.deviceSettings];
        
        // Weight Settings (Personal settings)
        NSDictionary *weightPersonalSettings = @{ OMRONDevicePersonalSettingsWeightDCIKey: [self getNumberFromString:self.dciField.text]};
        
        NSNumber *gender = @(OMRONDevicePersonalSettingsUserGenderTypeMale);
        if ([self.genderField.text isEqualToString:[genderArray objectAtIndex:1]]) {
            gender = @(OMRONDevicePersonalSettingsUserGenderTypeFemale);
        }
        
        NSDictionary *settings = @{ OMRONDevicePersonalSettingsUserHeightKey : [self roundFloatNumber:[_heightField.text floatValue] exponent:2.0],
                                    OMRONDevicePersonalSettingsUserDateOfBirthKey : [self.dateOfBirthField.text stringByReplacingOccurrencesOfString:@"-" withString:@""],
                                    OMRONDevicePersonalSettingsUserGenderKey : gender,
                                    OMRONDevicePersonalSettingsWeightKey : weightPersonalSettings
        };
        
        NSMutableDictionary *personalSettings = [[NSMutableDictionary alloc] init];
        [personalSettings setObject:settings forKey:OMRONDevicePersonalSettingsKey];
        
        NSNumber *weightUnit = @(OMRONDeviceWeightUnitKg);
        if ([self.weightUnitField.text isEqualToString:[weightUnitArray objectAtIndex:1]]) {
            weightUnit = @(OMRONDeviceWeightUnitLbs);
        }else if ([self.weightUnitField.text isEqualToString:[weightUnitArray objectAtIndex:2]]){
            weightUnit = @(OMRONDeviceWeightUnitSt);
        }
        
        // Weight Settings
        // Add other weight common settings if any
        NSDictionary *weightCommonSettings = @{ OMRONDeviceWeightSettingsUnitKey : weightUnit};
        NSMutableDictionary *weightSettings = [[NSMutableDictionary alloc] init];
        [weightSettings setObject:weightCommonSettings forKey:OMRONDeviceWeightSettingsKey];
        
        [exitingDeviceSettings addObject:personalSettings];
        [exitingDeviceSettings addObject:weightSettings];
        
        // Update Device Settings in Configuration
        existingPeripheralConfig.deviceSettings = exitingDeviceSettings;
        [(OmronPeripheralManager *)[OmronPeripheralManager sharedManager] setConfiguration:existingPeripheralConfig];
        
        self.updateButton.enabled = NO;
        self.statusLabel.text = @"Updating Settings...";
        
        // Create an OmronPeripheral object for updating device
        OmronPeripheral *peripheral = [[OmronPeripheral alloc] initWithLocalName:self.selectedPeripheral.localName andUUID:self.selectedPeripheral.UUID];
        
        [[OmronPeripheralManager sharedManager] updatePeripheral:peripheral withUsers:self.users withCompletionBlock:^(OmronPeripheral *peripheral, NSError *error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.updateButton.enabled = YES;
                self.statusLabel.text = @"";
                
                if(error == nil) {
                    
                    [self.delegate updateLocalPeripheral:peripheral];
                    
                    [self showAlertWithTitle:@"Device Settings Updated Successfully" withAction:NO];
                    
                }else {
                    
                    [self showAlertWithTitle:error.localizedDescription withAction:NO];
                }
            });
        }];
    }
}

@end
