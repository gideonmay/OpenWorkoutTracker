//  Created by Michael Simms on 7/15/19.
//  Copyright © 2019 Michael J Simms Software. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "WatchSettingsViewController.h"
#import "AppStrings.h"
#import "ExtensionDelegate.h"
#import "Preferences.h"

#define ALERT_MSG_STOP NSLocalizedString(@"Are you sure you want to do this? This cannot be undone.", nil)

@interface WatchSettingsViewController ()

@end


@implementation WatchSettingsViewController

@synthesize broadcast;
@synthesize metric;
@synthesize resetButton;

- (instancetype)init
{
	self = [super init];
	return self;
}

- (void)willActivate
{
	[super willActivate];
}

- (void)didDeactivate
{
	[super didDeactivate];
}

- (void)didAppear
{
}

- (void)awakeWithContext:(id)context
{
	[broadcast setOn:[Preferences shouldBroadcastGlobally]];
	[metric setOn:[Preferences preferredUnitSystem] == UNIT_SYSTEM_METRIC];
}

#pragma mark switch methods

- (IBAction)switchBroadcastAction:(BOOL)on
{
	[Preferences setBroadcastGlobally:on];
}

- (IBAction)switchMetricAction:(BOOL)on
{
	if (on)
		[Preferences setPreferredUnitSystem:UNIT_SYSTEM_METRIC];
	else
		[Preferences setPreferredUnitSystem:UNIT_SYSTEM_US_CUSTOMARY];
}

#pragma mark button handlers

- (IBAction)onReset
{
	WKAlertAction* yesAction = [WKAlertAction actionWithTitle:STR_YES style:WKAlertActionStyleDefault handler:^(void){
		ExtensionDelegate* extDelegate = (ExtensionDelegate*)[WKExtension sharedExtension].delegate;
		[extDelegate resetDatabase];
	}];
	WKAlertAction* noAction = [WKAlertAction actionWithTitle:STR_NO style:WKAlertActionStyleDefault handler:^(void){
	}];

	NSArray* actions = [NSArray new];
	actions = @[yesAction, noAction];
	[self presentAlertControllerWithTitle:STR_STOP message:ALERT_MSG_STOP preferredStyle:WKAlertControllerStyleAlert actions:actions];
}

@end
