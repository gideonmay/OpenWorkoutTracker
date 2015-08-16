// Created by Michael Simms on 10/8/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "Walking.h"
#include "ActivityAttribute.h"
#include "AxisName.h"
#include "CoordinateCalculator.h"
#include "UnitMgr.h"

Walking::Walking() : MovingActivity()
{
	m_stepsTaken = 0;
	m_lastAvgAltitudeM = (double)0.0;
	m_currentCalories = (double)0.0;
}

Walking::~Walking()
{
}

void Walking::ListUsableSensors(std::vector<SensorType>& sensorTypes) const
{
	sensorTypes.push_back(SENSOR_TYPE_ACCELEROMETER);
	MovingActivity::ListUsableSensors(sensorTypes);
}

bool Walking::ProcessGpsReading(const SensorReading& reading)
{
	bool result = false;

	if (m_previousLocSet)
	{
		Coordinate prevLoc = m_currentLoc;
		result = MovingActivity::ProcessGpsReading(reading);
		if (result)
		{
			m_currentCalories += CaloriesBetweenPoints(m_currentLoc, prevLoc);
		}
	}
	else
	{
		result = MovingActivity::ProcessGpsReading(reading);
	}
	return result;
}

bool Walking::ProcessAccelerometerReading(const SensorReading& reading)
{
	try
	{
		if (reading.reading.count(AXIS_NAME_Y) > 0)
		{
			double value = reading.reading.at(AXIS_NAME_Y);
			value += (double)10.0;	// make positive

			m_graphLine.AppendValue(reading.time, value);
			
			GraphPeakList newPeaks = m_graphLine.FindNewPeaks();
			GraphPeakList::iterator newPeakIter = newPeaks.begin();
			while (newPeakIter != newPeaks.end())
			{
				GraphPeak& curPeak = (*newPeakIter);
				if (curPeak.area > (double)50.0)
				{
					++m_stepsTaken;
				}
				++newPeakIter;
			}
		}
	}
	catch (...)
	{
	}

	return MovingActivity::ProcessAccelerometerReading(reading);
}

ActivityAttributeType Walking::QueryActivityAttribute(const std::string& attributeName) const
{
	ActivityAttributeType result;

	result.startTime = 0;
	result.endTime = 0;
	result.unitSystem = UnitMgr::GetUnitSystem();

	if (attributeName.compare(ACTIVITY_ATTRIBUTE_STEPS_TAKEN) == 0)
	{
		result.value.intVal = StepsTaken();
		result.valueType = TYPE_INTEGER;
		result.measureType = MEASURE_COUNT;
		result.valid = true;
	}
	else
	{
		result = MovingActivity::QueryActivityAttribute(attributeName);
	}
	return result;
}

double Walking::CaloriesBetweenPoints(const Coordinate& pt1, const Coordinate& pt2)
{
	double movingTimeMin = (double)(pt1.time - pt2.time) / (double)60000.0;
	double avgAltitudeM  = RunningAltitudeAverage();
	double grade         = (double)0.0;
	double calories      = (double)0.0;

	// Compute grade.
	if (m_altitudeBuffer.size() > 7) // Don't bother computing the slope until we have reasonabe altitude data.
	{
		double runM = CoordinateCalculator::HaversineDistanceIgnoreAltitude(pt2, pt2);
		if (runM > (double)0.5)
		{
			double riseM = avgAltitudeM - m_lastAvgAltitudeM;
			grade = riseM / runM;
			if (grade < (double)0.0)
			{
				grade = (double)0.0;
			}
		}
	}

	if (movingTimeMin > (double)0.01)
	{
		double speed = (DistanceTraveledInMeters() - PrevDistanceTraveledInMeters()) / movingTimeMin; // m/min
		double VO2 = ((double)0.2 * speed) + ((double)0.9 * speed * grade) + (double)3.5; // mL/kg/min
		VO2 *= m_athlete.GetWeightKg(); // mL/min
		calories = VO2 / (double)200.0; // calories/min
		calories *= movingTimeMin;
	}

	m_lastAvgAltitudeM = avgAltitudeM;

	return calories;
}

double Walking::CaloriesBurned() const
{
	// Sanity check.
	if (m_currentCalories < (double)0.1)
	{
		return (double)0.0;
	}
	return m_currentCalories;
}

void Walking::BuildAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_STEPS_TAKEN);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_MARATHON);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_HALF_MARATHON);
	MovingActivity::BuildAttributeList(attributes);
}

void Walking::BuildSummaryAttributeList(std::vector<std::string>& attributes) const
{
	attributes.push_back(ACTIVITY_ATTRIBUTE_STEPS_TAKEN);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_MARATHON);
	attributes.push_back(ACTIVITY_ATTRIBUTE_FASTEST_HALF_MARATHON);
	MovingActivity::BuildSummaryAttributeList(attributes);
}
