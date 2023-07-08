// Created by Michael Simms on 8/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __CYCLING__
#define __CYCLING__

#include "Bike.h"
#include "MovingActivity.h"
#include "Statistics.h"

typedef enum SpeedDataSource
{
	SPEED_FROM_LOCATION_DATA = 0,
	SPEED_FROM_WHEEL_SPEED
} SpeedDataSource;

class Cycling : public MovingActivity
{
public:
	Cycling();
	virtual ~Cycling();

	static std::string Type(void) { return ACTIVITY_TYPE_CYCLING; };
	virtual std::string GetType(void) const { return Cycling::Type(); };

	virtual void ListUsableSensors(std::vector<SensorType>& sensorTypes) const;

	virtual ActivityAttributeType QueryActivityAttribute(const std::string& attributeName) const;

	virtual void SetBikeProfile(const Bike& bike) { m_bike = bike; };
	virtual Bike GetBikeProfile(void) const { return m_bike; };

	virtual SegmentType CurrentSpeedFromWheelSpeed(void) const;
	virtual double DistanceFromWheelRevsInMeters(void) const;

	virtual double CaloriesBurned(void) const;

	virtual double CurrentCadence(void) const { return m_currentCadence; };
	virtual double AverageCadence(void) const { return m_numCadenceReadings > 0 ? (m_totalCadenceReadings / m_numCadenceReadings) : (double)0.0; };
	virtual double MaximumCadence(void) const { return m_maximumCadence; };

	virtual double CurrentPower(void) const { return m_currentPower; };
	virtual double AveragePower(void) const { return m_numPowerReadings > 0 ? (m_totalPowerReadings / m_numPowerReadings) : (double)0.0; };
	virtual double NormalizedPower(void) const;
	virtual double MaximumPower(void) const { return m_maximumPower; };
	virtual double ThreeSecPower(void) const { return m_3SecPower; };
	virtual double TwentyMinPower(void) const { return m_20MinPower; };
	virtual double OneHourPower(void) const { return m_1HourPower; };
	virtual double HighestThreeSecPower(void) const { return m_highest3SecPower; };
	virtual double HighestTwentyMinPower(void) const { return m_highest20MinPower; };
	virtual double HighestOneHourPower(void) const { return m_highest1HourPower; };
	virtual uint8_t CurrentPowerZone(void) const;

	virtual uint16_t NumWheelRevolutions(void) const { return m_currentWheelSpeedReading - m_firstWheelSpeedReading; };

	virtual void BuildAttributeList(std::vector<std::string>& attributes) const;
	virtual void BuildSummaryAttributeList(std::vector<std::string>& attributes) const;

protected:
	virtual bool ProcessAccelerometerReading(const SensorReading& reading);
	virtual bool ProcessCadenceReading(const SensorReading& reading);
	virtual bool ProcessWheelSpeedReading(const SensorReading& reading);
	virtual bool ProcessPowerMeterReading(const SensorReading& reading);
	
protected:
	Bike            m_bike;
	SpeedDataSource m_speedDataSource;
	
	double          m_distanceAtFirstWheelSpeedReadingM;

	double          m_currentCadence; // The most recent cadence reading
	double          m_maximumCadence; // The highest cadence value seen so far
	double          m_totalCadenceReadings; // Intermediate value for average cadence calculation

	double          m_currentPower; // The most recent power reading
	double          m_totalPowerReadings; // Intermediate value for average power calculation
	double          m_maximumPower; // The highest power value seen so far
	double          m_3SecPower; // The current 3 second average power (average over the last 3 seconds)
	double          m_20MinPower; // The current 20 minute average power (average over the last 20 minutes)
	double          m_1HourPower; // The current 1 hour average power (average over the last hour)
	double          m_highest3SecPower; // The highest 3 second average power seen so far
	double          m_highest20MinPower; // The highest 20 minute average power seen so far
	double          m_highest1HourPower; // The highest 1 hour average power seen so far
	std::vector<double> m_recentPowerReadings3Sec; // Used for 3 second average power
	std::vector<double> m_recentPowerReadings20Min; // Used for 20 minute average power
	std::vector<double> m_recentPowerReadings1Hour; // Used for 1 hour average power
	std::vector<double> m_normalizedPowerBuffer; // Contains 30 second power averages
	std::vector<double> m_current30SecBuffer; // Contains data from the most recent 30 second power block, needed for normalized power calculation
	uint64_t        m_current30SecBufferStartTime; // Used with the normalized power calculation

	uint16_t        m_numCadenceReadings; // Used with the average cadence calculation
	uint16_t        m_numPowerReadings; // Used with the average power calculation

	uint16_t        m_firstWheelSpeedReading;
	uint64_t        m_firstWheelSpeedTime;
	uint16_t        m_currentWheelSpeedReading;
	uint64_t        m_currentWheelSpeedTime;
	uint16_t        m_lastWheelSpeedReading;
	uint64_t        m_lastWheelSpeedTime;

	uint64_t        m_lastCadenceUpdateTimeMs; // time the cadence data was last updated
	uint64_t        m_lastPowerUpdateTimeMs;   // time the power data was last updated
};

#endif
