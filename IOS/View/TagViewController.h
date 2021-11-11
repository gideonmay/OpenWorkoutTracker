// Created by Michael Simms on 10/27/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import "CommonViewController.h"

@interface TagViewController : CommonViewController <UITableViewDataSource, UITableViewDelegate>
{
	IBOutlet UITableView* tagTableView;
	IBOutlet UIBarButtonItem* tagButton;
	
	NSMutableArray* tags;
	NSString* activityId;
}

- (IBAction)onNewTag:(id)sender;
- (void)setActivityId:(NSString*)activityIdent;

@property (nonatomic, retain) IBOutlet UITableView* tagTableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* tagButton;

@end
