//
//  BPReadingsViewController.m
//  OmronLibrarySample
//
//  Created by Praveen Rajan on 6/1/16.
//  Copyright (c) 2016 Omron HealthCare Inc. All rights reserved.
//

#import "BPReadingsViewController.h"
#import "AppDelegate.h"

@interface BPReadingsViewController () {
    
    NSMutableArray *readingsList;
}

@end

@implementation BPReadingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadReadings];
    
    
    [self customNavigationBarTitle:[NSString stringWithFormat:@"%@ - BP Data", [self.selectedDevice valueForKey:@"displayName"]] withFont:[UIFont fontWithName:@"Courier" size:16]];
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
    
    
    NSString *readingsString = [NSString stringWithFormat:@"SYS(mmHg): %@\nDIA(mmHg): %@\nPULSE(bpm): %@\nUSER : %@\nDATE : %@", [currentItem valueForKey:@"systolic"], [currentItem valueForKey:@"diastolic"], [currentItem valueForKey:@"pulse"], [currentItem valueForKey:@"user"], localDateString];
    // Flags
    readingsString = [NSString stringWithFormat:@"%@\nMovement Flag: %@\nIrregular HeartBeat: %@", readingsString, [currentItem valueForKey:@"movementFlag"], [currentItem valueForKey:@"irregularHBDisplay"]];
    if([currentItem valueForKey:@"irregularHBCount"] != nil) {
        readingsString = [NSString stringWithFormat:@"%@\nIrregular HeartBeat Count: %@", readingsString, [currentItem valueForKey:@"irregularHBCount"]];
    }
    if([currentItem valueForKey:@"afib"] != nil) {
        readingsString = [NSString stringWithFormat:@"%@\nAFiB Flag: %@", readingsString, [currentItem valueForKey:@"afib"]];
    }
    if([currentItem valueForKey:@"measurementMode"] != nil) {
        readingsString = [NSString stringWithFormat:@"%@\nMeasurement Mode: %@", readingsString, [currentItem valueForKey:@"measurementMode"]];
    }
    if([currentItem valueForKey:@"errorCode"] != nil) {
        readingsString = [NSString stringWithFormat:@"%@\nError Code: %@", readingsString, [currentItem valueForKey:@"errorCode"]];
    }
    if([currentItem valueForKey:@"nightModeErrorCode"] != nil) {
        readingsString = [NSString stringWithFormat:@"%@\nNightmode Error: %@", readingsString, [currentItem valueForKey:@"nightModeErrorCode"]];
    }
    
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
                                   entityForName:@"BPData" inManagedObjectContext:managedContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"BPData"];
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
                                   entityForName:@"BPData" inManagedObjectContext:managedContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"BPData"];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"localName == %@", [[self.selectedDevice valueForKey:@"localName"] lowercaseString]];
    
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    
    NSMutableArray *vitalDataList = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *info in fetchedObjects) {
        
        NSMutableDictionary *vitalData = [[NSMutableDictionary alloc] init];
        [vitalData setValue:[info valueForKey:@"systolic"]  forKey:@"systolic"];
        [vitalData setValue:[info valueForKey:@"diastolic"] forKey:@"diastolic"];
        [vitalData setValue:[info valueForKey:@"pulse"] forKey:@"pulse"];
        [vitalData setValue:[info valueForKey:@"afib"] forKey:@"afib"];
        [vitalData setValue:[info valueForKey:@"irregularHBCount"] forKey:@"irregularHBCount"];
        [vitalData setValue:[info valueForKey:@"irregularHBDisplay"] forKey:@"irregularHBDisplay"];
        [vitalData setValue:[info valueForKey:@"movementFlag"] forKey:@"movementFlag"];
        [vitalData setValue:[info valueForKey:@"measurementMode"] forKey:@"measurementMode"];
        [vitalData setValue:[info valueForKey:@"errorCode"] forKey:@"errorCode"];
        [vitalData setValue:[info valueForKey:@"nightModeErrorCode"] forKey:@"nightModeErrorCode"];
        [vitalData setValue:[info valueForKey:@"startDate"] forKey:@"startDate"];
        [vitalData setValue:[info valueForKey:@"localName"] forKey:@"localName"];
        [vitalData setValue:[info valueForKey:@"displayName"] forKey:@"displayName"];
        [vitalData setValue:[info valueForKey:@"user"] forKey:@"user"];
        [vitalDataList addObject:vitalData];
    }
    
    vitalDataList = [[[vitalDataList reverseObjectEnumerator] allObjects] mutableCopy];
    
    return vitalDataList;
    
}

@end
