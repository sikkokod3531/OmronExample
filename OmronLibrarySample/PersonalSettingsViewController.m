//
//  PersonalSettingsViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/16/17.
//  Copyright © 2017 Omron HealthCare Inc. All rights reserved.
//

#import "PersonalSettingsViewController.h"
#import "BPViewController.h"

@interface PersonalSettingsViewController () <UIPickerViewDataSource, UIPickerViewDelegate> {
    
    float heightFeet;
    float heightInch;
    
    float weight;
    
    float strideFeet;
    float strideInch;
}

@property (weak, nonatomic) IBOutlet UILabel *heightLabel;
@property (weak, nonatomic) IBOutlet UILabel *heightValue;
@property (weak, nonatomic) IBOutlet UIPickerView *heightPicker;
@property (weak, nonatomic) IBOutlet UILabel *weightLabel;
@property (weak, nonatomic) IBOutlet UILabel *weightValue;
@property (weak, nonatomic) IBOutlet UIPickerView *weightPicker;
@property (weak, nonatomic) IBOutlet UILabel *strideLabel;
@property (weak, nonatomic) IBOutlet UILabel *strideValue;
@property (weak, nonatomic) IBOutlet UIPickerView *stridePicker;

@end

@implementation PersonalSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *title = @"Personal Settings";
    
    [self customNavigationBarTitle:title withFont:[UIFont fontWithName:@"Courier" size:16]];
    
    self.tableView.allowsSelection = NO;
    self.heightPicker.delegate = self;
    self.heightPicker.showsSelectionIndicator = YES;
    
    self.weightPicker.delegate = self;
    self.weightPicker.showsSelectionIndicator = YES;
    
    self.stridePicker.delegate = self;
    self.stridePicker.showsSelectionIndicator = YES;
    
    
    [self.heightPicker selectRow:2 inComponent:0 animated:NO];
    [self.heightPicker selectRow:4 inComponent:1 animated:NO];
    
    self.heightValue.text = [NSString stringWithFormat:@"%@' %@\"", [[self getUserDetailsHeightFeetOptions] objectAtIndex:2], [[self getUserDetailsHeightInchesOptions] objectAtIndex:4] ];
    
    heightFeet = [[[self getUserDetailsHeightFeetOptions] objectAtIndex:2] floatValue];
    heightInch = [[[self getUserDetailsHeightInchesOptions] objectAtIndex:4] floatValue];
    
    [self.weightPicker selectRow:50 inComponent:0 animated:NO];
    
    self.weightValue.text = [NSString stringWithFormat:@"%@ lbs", [[self getUserDetailsWeightLbsOptions] objectAtIndex:50]];
    
    weight = [[[self getUserDetailsWeightLbsOptions] objectAtIndex:50] floatValue];
    
    [self.stridePicker selectRow:1 inComponent:0 animated:NO];
    [self.stridePicker selectRow:4 inComponent:1 animated:NO];
    
    self.strideValue.text = [NSString stringWithFormat:@"%@' %@\"", [[self getUserDetailsStrideFeetOptions] objectAtIndex:1], [[self getUserDetailsStrideInchesOptions] objectAtIndex:4] ];
    
    strideFeet = [[[self getUserDetailsStrideFeetOptions] objectAtIndex:1] floatValue];
    strideInch = [[[self getUserDetailsStrideInchesOptions] objectAtIndex:4] floatValue];
}


- (IBAction)tapSubmitButton:(id)sender
{
    // Set Height, Weight, Stride to pass to next view controller
    
    float weightKg = [self conversionLbsKg:weight];
    
    float heightCm = [self conversionToCm:heightFeet withInch:heightInch] ;
    
    float strideCm = [self conversionToCm:strideFeet withInch:strideInch] ;
    
    // Set User number in model for data transfer in next view controller
    // Set height, weight, stride for pair/ data transfer in next view controller
    NSDictionary *settings = @{@"personalHeight" : [self roundFloatNumber:heightCm exponent:2.0],
                               @"personalWeight" : [self roundFloatNumber:weightKg exponent:2.0],
                               @"personalStride" : [self roundFloatNumber:strideCm exponent:2.0]};
    
    BPViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BPViewController"];
    controller.filterDeviceModel = self.filterDeviceModel;
    controller.settingsModel = [[NSMutableDictionary alloc] initWithDictionary:settings];
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - UIPickerView

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    
    if(pickerView.tag == 1)
        return 2;
    else if(pickerView.tag == 2)
        return 1;
    else
        return 2;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    
    return 40;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    
    if(pickerView.tag == 1) {
        
        if(component == 0){
            return [[self getUserDetailsHeightFeetOptions] count];
        } else {
            return [[self getUserDetailsHeightInchesOptions] count];
        }
        
    }else if(pickerView.tag == 2) {
       
        return [[self getUserDetailsWeightLbsOptions]count];
       
    }else {
        
        if(component == 0){
            return [[self getUserDetailsStrideFeetOptions] count];
        } else {
            return [[self getUserDetailsStrideInchesOptions] count];
        }
        
    }
    
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel* tView = (UILabel*)view;
    if (!tView){
        tView = [[UILabel alloc] init];
        tView.font =  [UIFont fontWithName:@"Courier" size:18];
        tView.textAlignment = NSTextAlignmentCenter;
    }
    
    NSString *textLbl = @"";
    if(pickerView.tag == 1) {
        
        if(component == 0){
            textLbl = [NSString stringWithFormat:@"%@ ft", [[self getUserDetailsHeightFeetOptions] objectAtIndex:row]];
        } else {
            textLbl = [NSString stringWithFormat:@"%@ inch", [[self getUserDetailsHeightInchesOptions] objectAtIndex:row]];
        }
        
    }else if(pickerView.tag == 2) {
        
        textLbl = [NSString stringWithFormat:@"%@ lbs", [[self getUserDetailsWeightLbsOptions] objectAtIndex:row]];
        
    }else {
        
        if(component == 0){
            textLbl = [NSString stringWithFormat:@"%@ ft", [[self getUserDetailsStrideFeetOptions] objectAtIndex:row]];
        } else {
            textLbl = [NSString stringWithFormat:@"%@ inch", [[self getUserDetailsStrideInchesOptions] objectAtIndex:row]];
        }
    }
    
    tView.text = textLbl;
    
    return tView;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    if(pickerView.tag == 1) {
        
       
        if(component == 0) {
            
            self.heightValue.text = [NSString stringWithFormat:@"%@' %@\"", [[self getUserDetailsHeightFeetOptions] objectAtIndex:row], [[self getUserDetailsHeightInchesOptions] objectAtIndex:[self.heightPicker selectedRowInComponent:1]] ];
    
            
            heightFeet = [[[self getUserDetailsHeightFeetOptions] objectAtIndex:row] floatValue];
            
        }else {
            
            
            self.heightValue.text = [NSString stringWithFormat:@"%@' %@\"", [[self getUserDetailsHeightFeetOptions] objectAtIndex:[self.heightPicker selectedRowInComponent:0]], [[self getUserDetailsHeightInchesOptions] objectAtIndex:row] ];
            
            heightInch = [[[self getUserDetailsHeightInchesOptions] objectAtIndex:row] floatValue];
            
        }
        
    }else if(pickerView.tag == 2) {
        
        
        self.weightValue.text = [NSString stringWithFormat:@"%@ lbs", [[self getUserDetailsWeightLbsOptions] objectAtIndex:row]];
        
        weight = [[[self getUserDetailsWeightLbsOptions] objectAtIndex:row] floatValue];
        
    }else {
        
        if(component == 0) {
            
            self.strideValue.text = [NSString stringWithFormat:@"%@' %@\"", [[self getUserDetailsStrideFeetOptions] objectAtIndex:row], [[self getUserDetailsStrideInchesOptions] objectAtIndex:[self.stridePicker selectedRowInComponent:1]] ];
            
            strideFeet = [[[self getUserDetailsStrideFeetOptions] objectAtIndex:row] floatValue];
            
        }else {
            
            
            self.strideValue.text = [NSString stringWithFormat:@"%@' %@\"", [[self getUserDetailsStrideFeetOptions] objectAtIndex:[self.stridePicker selectedRowInComponent:0]], [[self getUserDetailsStrideInchesOptions] objectAtIndex:row] ];
            
            strideInch = [[[self getUserDetailsStrideInchesOptions] objectAtIndex:row] floatValue];
        }
        
    }
}

#pragma mark - Utility

- (NSArray*)getUserDetailsHeightFeetOptions{
    NSMutableArray *feetOptions = [[NSMutableArray alloc]init];
    for (int i = 3; i < 8; i++) {
        [feetOptions addObject:[NSNumber numberWithInt:i]];
    }
    return feetOptions;
}

- (NSArray*)getUserDetailsHeightInchesOptions{
    NSMutableArray *inchesOptions = [[NSMutableArray alloc]init];
    for (int i = 0; i < 12; i++) {
        [inchesOptions addObject:[NSNumber numberWithInt:i]];
    }
    return inchesOptions;
}

- (NSArray*)getUserDetailsWeightLbsOptions{
    NSMutableArray *lbOptions = [[NSMutableArray alloc]init];
    for (int i = 75; i < 401; i++) {
        [lbOptions addObject:[NSNumber numberWithInt:i]];
    }
    return lbOptions;
}

- (NSArray*)getUserDetailsStrideFeetOptions{
    NSMutableArray *feetOptions = [[NSMutableArray alloc]init];
    for (int i = 0; i < 3; i++) {
        [feetOptions addObject:[NSNumber numberWithInt:i]];
    }
    return feetOptions;
}

- (NSArray*)getUserDetailsStrideInchesOptions{
    NSMutableArray *inchesOptions = [[NSMutableArray alloc]init];
    for (int i = 0; i < 12; i++) {
        [inchesOptions addObject:[NSNumber numberWithInt:i]];
    }
    return inchesOptions;
}


- (float)conversionStrideInchToCm:(float)inputValue {
    
    float fltReturnValue = 0.0f;
    
    if (inputValue == 0) {
        return fltReturnValue;
    }
    int32_t inch_wide_value = inputValue *100;
    int32_t cm_wide_value = inch_wide_value *254 *0.01;
    fltReturnValue = cm_wide_value * 0.01;
    return fltReturnValue;
}

- (float)conversionLbsKg:(float)inputValue {
    float fltReturnValue;
    
    inputValue *= 10.0f;
    int32_t disp_value = (int32_t)((inputValue * 453592 + 50000) / 100000);
    fltReturnValue = disp_value / 100.0f;
    
    return fltReturnValue;
}

- (float)conversionToCm:(float)feetValue withInch:(float)inchValue {
    
    uint32_t gss_arg_value;
    uint16_t feet = floorf(feetValue) ;
    uint16_t inch = inchValue;
    uint16_t us_height_inc = 0;
    
    // feetInch -> inch
    if (feet > 0) {
        us_height_inc += feet * 48;
    }
    if (inch > 0) {
        us_height_inc += inch * 4;
    }
    
    gss_arg_value = (int32_t)us_height_inc * 254;
    gss_arg_value = (gss_arg_value + 100) / 200;
    gss_arg_value = gss_arg_value * 5;
    
    return (float)gss_arg_value * 0.1;
}

- (NSNumber *)roundFloatNumber:(float)number
                      exponent:(float)exponent {
    float fractionDigitBase = powf(10.0, exponent);
    float roundValue = (roundf(number * fractionDigitBase) / fractionDigitBase) * 100;
    return [[NSNumber alloc] initWithFloat:roundValue];
}


@end
