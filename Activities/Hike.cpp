// Created by Michael Simms on 9/9/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "Hike.h"
#include "ActivityAttribute.h"

Hike::Hike() : Walking()
{
	m_stepsTaken = 0;
}

Hike::~Hike()
{
}

bool Hike::ProcessAccelerometerReading(const SensorReading& reading)
{
	return false;
}

double Hike::CaloriesBurned() const
{
	double avgHeartRate = AverageHeartRate();

	if (avgHeartRate < (double)1.0)	// data not available, estimate 50% of Max. Heart Rate
	{
		avgHeartRate = (double)0.50 * m_athlete.EstimateMaxHeartRate();
	}
	
	// Source: http://www.livestrong.com/article/202403-calories-burned-running-speed/
	switch (m_athlete.GetGender())
	{
		case GENDER_MALE:
			return ((0.634 * avgHeartRate) + (0.271 * m_athlete.GetAgeInYears()) + (0.179 * m_athlete.GetLeanBodyMassLbs()) +
					(0.404 * m_athlete.EstimateVO2Max()) - 95.7735) * MovingTimeInMinutes() / 4.184;
			break;
		case GENDER_FEMALE:
			return ((0.450 * avgHeartRate) + (0.274 * m_athlete.GetAgeInYears()) + (0.0468 * m_athlete.GetLeanBodyMassLbs()) +
					(0.380 * m_athlete.EstimateVO2Max()) - 59.3954) * MovingTimeInMinutes() / 4.184;
			break;
	}
	return (double)0.0;
}

void Hike::BuildAttributeList(std::vector<std::string>& attributes)
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_STEPS_TAKEN);
	MovingActivity::BuildAttributeList(attributes);
}

void Hike::BuildSummaryAttributeList(std::vector<std::string>& attributes)
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_STEPS_TAKEN);
	MovingActivity::BuildSummaryAttributeList(attributes);
}
