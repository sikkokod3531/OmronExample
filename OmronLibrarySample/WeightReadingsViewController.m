//
//  WeightReadingsViewController.m
//  OmronLibrarySample
//
//  Created by Hitesh Bhardwaj on 12/04/19.
//  Copyright © 2019 Omron HealthCare Inc. All rights reserved.
//

#import "WeightReadingsViewController.h"
#import "AppDelegate.h"

@interface WeightReadingsViewController () {
    
    NSMutableArray *readingsList;
}

@end

@implementation WeightReadingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadReadings];
    
    // Set navigation bar title
    [self customNavigationBarTitle:[NSString stringWithFormat:@"%@ - Weight Data", [self.selectedDevice valueForKey:@"displayName"]] withFont:[UIFont fontWithName:@"Courier" size:16]];
    
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 200.0f;
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
    
    
    NSString *readingsString = [NSString stringWithFormat:@"Weight(Kg): %@\nBody Fat Percentage: %@\nResting Metabolism: %@\nSkeletal Muscle Percentage: %@\nBMI: %@\nVisceral Fat Level: %@\nUSER : %@\nDATE : %@", [currentItem valueForKey:@"weight"], [currentItem valueForKey:@"bodyFatPercentage"], [currentItem valueForKey:@"restingMetabolism"], [currentItem valueForKey:@"skeletalMusclePercentage"], [currentItem valueForKey:@"bMI"], [currentItem valueForKey:@"visceralFatLevel"], [currentItem valueForKey:@"user"], localDateString];
    
    NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:readingsString];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:10];
    [attrString addAttribute:NSParagraphStyleAttributeName
                       value:style
                       range:NSMakeRange(0, readingsString.length)];
    cell.textLabel.numberOfLines = 15;
    cell.textLabel.attributedText = attrString;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
    
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteReadingAtIndex:indexPath.row];
    }
}

#pragma mark - Utility

- (void)deleteReadingAtIndex:(NSInteger) index {
    AppDelegate *appDel = [AppDelegate sharedAppDelegate];
    NSManagedObjectContext *managedContext = [appDel managedObjectContext];
    
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"WeightData" inManagedObjectContext:managedContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"WeightData"];
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
                                   entityForName:@"WeightData" inManagedObjectContext:managedContext];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"WeightData"];
    
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"localName == %@", [[self.selectedDevice valueForKey:@"localName"] lowercaseString]];
    
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [managedContext executeFetchRequest:fetchRequest error:&error];
    
    NSMutableArray *vitalDataList = [[NSMutableArray alloc] init];
    
    for (NSManagedObject *info in fetchedObjects) {
        
        NSMutableDictionary *vitalData = [[NSMutableDictionary alloc] init];
        [vitalData setValue:[info valueForKey:@"weight"]  forKey:@"weight"];
        [vitalData setValue:[info valueForKey:@"bodyFatPercentage"] forKey:@"bodyFatPercentage"];
        [vitalData setValue:[info valueForKey:@"restingMetabolism"] forKey:@"restingMetabolism"];
        [vitalData setValue:[info valueForKey:@"skeletalMusclePercentage"] forKey:@"skeletalMusclePercentage"];
        [vitalData setValue:[info valueForKey:@"bMI"] forKey:@"bMI"];
        [vitalData setValue:[info valueForKey:@"visceralFatLevel"] forKey:@"visceralFatLevel"];
        [vitalData setValue:[info valueForKey:@"user"] forKey:@"user"];
        [vitalData setValue:[info valueForKey:@"startDate"] forKey:@"startDate"];
        
        [vitalDataList addObject:vitalData];
    }
    
    vitalDataList = [[[vitalDataList reverseObjectEnumerator] allObjects] mutableCopy];
    
    return vitalDataList;
    
}

@end
