// Created by Michael Simms on 8/29/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "CommonViewController.h"

@interface HistoryViewController : CommonViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate>
{
	IBOutlet UISearchBar* searchBar;
	IBOutlet UITableView* historyTableView;
	IBOutlet UIActivityIndicatorView* spinner;
	IBOutlet UIBarButtonItem* exportButton;

	NSMutableDictionary* historyDictionary;
	NSArray* sortedKeys;

	NSString* exportedFileName;
	NSString* selectedExportActivity;
	NSString* selectedExportService;
	NSString* selectedActivityId;

	bool searching;
}

- (IBAction)onExportSummary:(id)sender;

@property (nonatomic, retain) IBOutlet UISearchBar* searchBar;
@property (nonatomic, retain) IBOutlet UITableView* historyTableView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* spinner;
@property (nonatomic, retain) IBOutlet UIBarButtonItem* exportButton;

@end
