// Created by Michael Simms on 2/11/13.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "GarminConnect.h"

@implementation GarminConnect

- (id)init
{
	self = [super init];
	if (self != nil)
	{
	}
	return self;
}

- (BOOL)isLinked
{
	BOOL result = FALSE;
	return result;
}

- (NSString*)name
{
	return @"Garmin Connect";
}

- (BOOL)uploadActivity:(NSString*)name
{
	return FALSE;
}

@end
