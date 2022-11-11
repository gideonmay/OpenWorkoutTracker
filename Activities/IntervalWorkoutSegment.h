// Created by Michael Simms on 6/16/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __INTERVALSESSIONSEGMENT__
#define __INTERVALSESSIONSEGMENT__

#include <stdint.h>

typedef enum IntervalUnit
{
	INTERVAL_UNIT_NOT_SET = 0,
	INTERVAL_UNIT_SETS,
	INTERVAL_UNIT_REPS,
	INTERVAL_UNIT_SECONDS,
	INTERVAL_UNIT_METERS,
	INTERVAL_UNIT_KILOMETERS,
	INTERVAL_UNIT_FEET,
	INTERVAL_UNIT_YARDS,
	INTERVAL_UNIT_MILES,
	INTERVAL_UNIT_PACE_US_CUSTOMARY,
	INTERVAL_UNIT_PACE_METRIC,
	INTERVAL_UNIT_SPEED_US_CUSTOMARY,
	INTERVAL_UNIT_SPEED_METRIC,
	INTERVAL_UNIT_WATTS
} IntervalUnit;

typedef struct IntervalSessionSegment
{
	uint64_t     segmentId; // Database identifier for this segment
	uint32_t     sets;      // Number of sets
	uint32_t     reps;      // Number of repititions
	uint32_t     duration;  // Duration, if applicable, in seconds
	double       distance;  // Distance, if applicable, in the specified units
	double       pace;      // Pace, if applicable, in meters/second
	double       power;     // Power, if applicable, in percentage of FTP
	IntervalUnit units;     // Informs the consumer of this structure as to which fields are meaningful and how to interpret the distance field
} IntervalSessionSegment;

#endif
