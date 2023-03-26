//
//  PulseOxymeterReadingsViewController.m
//  OmronLibrarySample
//
//  Created by Shohei Tomoe on 2022/10/27.
//  Copyright © 2022 Omron HealthCare Inc. All rights reserved.

#import "PulseOxymeterReadingsViewController.h"
#import "AppDelegate.h"

@interface PulseOxymeterReadingsViewController () {
    
    NSMutableArray *readingsList;
}

@end

@implementation PulseOxymeterReadingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadReadings];
    
    
    [self customNavigationBarTitle:[NSString stringWithFormat:@"%@ - Pulse Oxymeter Data", [self.selectedDevice valueForKey:@"displayName"]] withFont:[UIFont fontWithName:@"Courier" size:16]];
}

- (void)loadReadings {
    
    readingsList = [[NSMutableArray alloc] init];
    readingsList = [self retrieveReadingsFromDB];
    
    [self.tableView reloadData];
    
    [self.tableView setRowHeight:130.0f];
}

#pragma mark - Table view data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [readingsList count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 300.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *currentItem = [readingsList objectAtIndex:indexPath.row];
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    cell.textLabel.font = [UIFont fontWithName:@"Courier" size:14];
    
    
    NSDate *measurementDate = [NSDate dateWithTimeIntervalSince1970:[[currentItem valueForKey:@"startDate"] doubleValue]];
    NSTimeZone *timeZone = [NSTimeZone defaultTimeZone];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss a"];
    NSString *localDateString = [dateFormatter stringFromDate:measurementDate];
    
    NSString *readingsString = [NSString stringWithFormat:@"SpO2(%%): %@\nPULSE(bpm): %@\nDATE : %@\nDEVICE: %@", [currentItem valueForKey:@"spO2"], [currentItem valueForKey:@"pulse"], localDateString, [currentItem valueForKey:@"deviceIdentity"]];
    
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:readingsString];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:10];
    [attrString addAttribute:NSParagraphStyleAttributeName
                       value:style
                       range:NSMakeRange(0, readingsString.length)];
    cell.textLabel.numberOfLines = 30;
    cell.textLabel.attributedText = attrString;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
    
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete
        [self deleteReadingAtIndex:indexPath.row];
    }
}

#pragma mark - Utility

- (void)deleteReadingAtIndex:(NSInteger) index {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"PulseOxymeterData" inManagedObjectContext:managedContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PulseOxymeterData"];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *info in fetchedObjects) {
        NSDictionary *currentItem = [readingsList objectAtIndex:index];
        if([currentItem[@"startDate"] isEqualToString:[info valueForKey:@"startDate"]]) {
            [managedContext deleteObject:info];
            [self loadReadings];
            break;
        }
    }
}

- (NSMutableArray *)retrieveReadingsFromDB {
    
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"PulseOxymeterData" inManagedObjectContext:managedContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"PulseOxymeterData"];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"localName == %@", [[self.selectedDevice valueForKey:@"localName"] lowercaseString]];
    
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    
    NSMutableArray *vitalDataList = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *info in fetchedObjects) {
        
        NSMutableDictionary *vitalData = [[NSMutableDictionary alloc] init];
        [vitalData setValue:[info valueForKey:@"spO2"] forKey:@"spO2"];
        [vitalData setValue:[info valueForKey:@"pulse"] forKey:@"pulse"];
        [vitalData setValue:[info valueForKey:@"startDate"] forKey:@"startDate"];
        [vitalData setValue:[info valueForKey:@"localName"] forKey:@"localName"];
        [vitalData setValue:[info valueForKey:@"displayName"] forKey:@"displayName"];
        [vitalData setValue:[info valueForKey:@"category"] forKey:@"category"];
        [vitalData setValue:[info valueForKey:@"deviceIdentity"] forKey:@"deviceIdentity"];
        [vitalDataList addObject:vitalData];
    }
    
    vitalDataList = [[[vitalDataList reverseObjectEnumerator] allObjects] mutableCopy];
    
    return vitalDataList;
    
}

@end
