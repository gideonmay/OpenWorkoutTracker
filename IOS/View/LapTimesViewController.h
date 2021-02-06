// Created by Michael Simms on 3/8/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>

@interface LapTimesViewController : UIViewController
{
	IBOutlet UITableView*      lapTimesTableView;
	IBOutlet UIBarButtonItem*  homeButton;

	NSString*       activityId;
	NSMutableArray* lapTimes;
}

- (IBAction)onHome:(id)sender;

- (void)setActivityId:(NSString*)newId;

@property (nonatomic, retain) IBOutlet UITableView* lapTimesTableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* homeButton;

@end
