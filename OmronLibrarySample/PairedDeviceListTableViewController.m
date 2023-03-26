//
//  PairedDeviceListTableViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/20/17.
//  Copyright © 2017 Omron HealthCare Inc. All rights reserved.
//

#import "PairedDeviceListTableViewController.h"
#import "AppDelegate.h"
#import "BPViewController.h"
#import "PulseOxymeterReadingsViewController.h"
#import "BPReadingsViewController.h"
#import "VitalOptionsTableViewController.h"

@interface PairedDeviceListTableViewController () {
    
    NSMutableArray *devicesList;
}

@end

@implementation PairedDeviceListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    devicesList = [self retrieveDevicesFromDB];
    
    // Customize Navigation Bar
    [self customNavigationBarTitle:@"Paired Devices" withFont:[UIFont fontWithName:@"Courier" size:16]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return devicesList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"devicesCell" forIndexPath:indexPath];
    
    NSMutableDictionary *item = [devicesList objectAtIndex:indexPath.row];
    
    cell.textLabel.font = [UIFont fontWithName:@"Courier" size:18];
    cell.textLabel.text = [item valueForKey:@"displayName"];
    
    cell.detailTextLabel.font = [UIFont fontWithName:@"Courier" size:12];
    cell.detailTextLabel.text = [[item valueForKey:@"localName"] uppercaseString];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSMutableDictionary *currentDevice = [devicesList objectAtIndex:indexPath.row];
        
        if([[currentDevice valueForKey:@"category"] intValue] == OMRONBLEDeviceCategoryBloodPressure) {
            
            // Blood Pressure Device
            BPReadingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"BPReadingsViewController"];
            controller.selectedDevice = currentDevice;
            
            [self.navigationController pushViewController:controller animated:YES];
            
        }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryActivity) {
            
            // Blood Pressure Device
            VitalOptionsTableViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"VitalOptionsTableViewController"];
            controller.selectedDevice = currentDevice;
            
            [self.navigationController pushViewController:controller animated:YES];
        }else if([[currentDevice valueForKey:OMRONBLEConfigDeviceCategoryKey] intValue] == OMRONBLEDeviceCategoryPulseOximeter) {
            
            // Pulse Oxymeter Device
            PulseOxymeterReadingsViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"PulseOxymeterReadingsViewController"];
            controller.selectedDevice = currentDevice;
            
            [self.navigationController pushViewController:controller animated:YES];
        }
        
    });
    
}

- (NSMutableArray *)retrieveDevicesFromDB {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"BPData" inManagedObjectContext:managedContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"BPData"];
    
    fetchRequest.propertiesToFetch = [NSArray arrayWithObjects:[[entity propertiesByName] objectForKey:@"localName"], [[entity propertiesByName] objectForKey:@"displayName"], [[entity propertiesByName] objectForKey:@"category"], nil];
    fetchRequest.returnsDistinctResults = YES;
    fetchRequest.resultType = NSDictionaryResultType;
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    
    NSMutableArray *deviceDataList = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *info in fetchedObjects) {
        
        NSMutableDictionary *deviceData = [[NSMutableDictionary alloc] init];
        [deviceData setValue:[[info valueForKey:@"localName"] lowercaseString] forKey:@"localName"];
        [deviceData setValue:[info valueForKey:@"displayName"] forKey:@"displayName"];
        [deviceData setValue:[info valueForKey:@"category"] forKey:@"category"];
        
        if(![deviceDataList containsObject:deviceData])
            [deviceDataList addObject:deviceData];
    }
    
    deviceDataList = [[[deviceDataList reverseObjectEnumerator] allObjects] mutableCopy];
    
    entity = [NSEntityDescription
              entityForName:@"ActivityData" inManagedObjectContext:managedContext];
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"ActivityData"];
    fetchRequest.propertiesToFetch = [NSArray arrayWithObjects:[[entity propertiesByName] objectForKey:@"localName"],[[entity propertiesByName] objectForKey:@"displayName"], [[entity propertiesByName] objectForKey:@"category"],  nil];
    fetchRequest.returnsDistinctResults = YES;
    fetchRequest.resultType = NSDictionaryResultType;
    //
    [fetchRequest setEntity:entity];
    
    error = nil;
    fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *info in fetchedObjects) {
        
        
        NSMutableDictionary *deviceData = [[NSMutableDictionary alloc] init];
        [deviceData setValue:[[info valueForKey:@"localName"] lowercaseString] forKey:@"localName"];
        [deviceData setValue:[info valueForKey:@"displayName"] forKey:@"displayName"];
        [deviceData setValue:[info valueForKey:@"category"] forKey:@"category"];
        
        if(![deviceDataList containsObject:deviceData])
            [deviceDataList addObject:deviceData];
    }
    
    entity = [NSEntityDescription
              entityForName:@"PulseOxymeterData" inManagedObjectContext:managedContext];
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PulseOxymeterData"];
    fetchRequest.propertiesToFetch = [NSArray arrayWithObjects:[[entity propertiesByName] objectForKey:@"localName"],[[entity propertiesByName] objectForKey:@"displayName"], [[entity propertiesByName] objectForKey:@"category"],  nil];
    fetchRequest.returnsDistinctResults = YES;
    fetchRequest.resultType = NSDictionaryResultType;
    //
    [fetchRequest setEntity:entity];
    
    error = nil;
    fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *info in fetchedObjects) {
        
        
        NSMutableDictionary *deviceData = [[NSMutableDictionary alloc] init];
        [deviceData setValue:[[info valueForKey:@"localName"] lowercaseString] forKey:@"localName"];
        [deviceData setValue:[info valueForKey:@"displayName"] forKey:@"displayName"];
        [deviceData setValue:[info valueForKey:@"category"] forKey:@"category"];
        
        if(![deviceDataList containsObject:deviceData])
            [deviceDataList addObject:deviceData];
    }
    
    NSLog(@"Device list - %@", deviceDataList);
    
    return deviceDataList;
    
}

@end
