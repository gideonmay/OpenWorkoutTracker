// Created by Michael Simms on 9/28/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import <Foundation/Foundation.h>
#import "ActivityAttributeType.h"
#import "ActivityLevel.h"
#import "Gender.h"

#import <time.h>

#define VALUE_NOT_SET_STR "--"

@interface StringUtils : NSObject

+ (NSString*)formatActivityViewType:(ActivityAttributeType)attribute;
+ (NSString*)formatActivityMeasureType:(ActivityAttributeMeasureType)measureType;
+ (NSString*)formatDateAndTime:(NSDate*)date;
+ (NSString*)formatDate:(NSDate*)date;
+ (NSString*)formatDateFromTimeStruct:(const struct tm*)date;
+ (NSString*)activityLevelToStr:(ActivityLevel)level;
+ (NSString*)genderToStr:(Gender)gender;

@end
