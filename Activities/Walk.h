// Created by Michael Simms on 10/8/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __WALK__
#define __WALK__

#include "ActivityType.h"
#include "MovingActivity.h"
#include "GForceAnalyzer.h"

class Walk : public MovingActivity
{
public:
	Walk();
	virtual ~Walk();

	static std::string Type() { return ACTIVITY_TYPE_WALKING; };
	virtual std::string GetType() const { return Walk::Type(); };

	virtual void ListUsableSensors(std::vector<SensorType>& sensorTypes) const;

	virtual bool Stop();
	virtual void Pause();

	virtual void OnFinishedLoadingSensorData();

	virtual ActivityAttributeType QueryActivityAttribute(const std::string& attributeName) const;

	virtual double CaloriesBurned() const;

	virtual uint16_t StepsTaken() const { return m_stepsTaken; };

	virtual void BuildAttributeList(std::vector<std::string>& attributes) const;
	virtual void BuildSummaryAttributeList(std::vector<std::string>& attributes) const;

protected:
	virtual bool ProcessAccelerometerReading(const SensorReading& reading);

protected:
	LibMath::GraphLine m_graphLine;
	LibMath::Peaks     m_peakFinder;
	uint64_t           m_lastPeakCalculationTime; // timestamp of when we last ran the peak calculation, so we're not calling it for every accelerometer reading
	uint16_t           m_stepsTaken;

protected:
	void CalculateStepsTaken();
};

#endif
