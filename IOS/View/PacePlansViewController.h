// Created by Michael Simms on 12/28/19.
// Copyright (c) 2019 Michael J. Simms. All rights reserved.

#import <UIKit/UIKit.h>
#import "CommonViewController.h"

@interface PacePlansViewController : CommonViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
	IBOutlet UITableView* planTableView;
	IBOutlet UIBarButtonItem* addPlanButton;
	
	NSString* selectedPlanId;
	NSMutableArray* planNamesAndIds;
}

- (IBAction)onAddPacePlan:(id)sender;

@property (nonatomic, retain) IBOutlet UITableView* planTableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* addPlanButton;

@end
