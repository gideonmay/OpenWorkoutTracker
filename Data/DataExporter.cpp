// Created by Michael Simms on 8/15/12.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#include "DataExporter.h"
#include "ActivityAttribute.h"
#include "AxisName.h"
#include "Defines.h"
#include "FitFileWriter.h"
#include "GpxFileWriter.h"
#include "TcxFileWriter.h"
#include "CsvFileWriter.h"
#include "MovingActivity.h"
#include "TcxTags.h"
#include "ZwoFileWriter.h"

DataExporter::DataExporter()
{
}

DataExporter::~DataExporter()
{
}

bool DataExporter::NearestSensorReading(uint64_t timeMs, const SensorReadingList& list, SensorReadingList::const_iterator& iter)
{
	while ((iter != list.end()) && ((*iter).time < timeMs))
	{
		++iter;
	}
	while ((iter != list.begin()) && ((*iter).time > timeMs))
	{
		--iter;
	}
	
	if (iter == list.begin() || iter == list.end())
	{
		return false;
	}
	
	uint64_t sensorTime = (*iter).time;
	uint64_t timeDiff;
	if (sensorTime > timeMs)
		timeDiff = sensorTime - timeMs;
	else
		timeDiff = timeMs - sensorTime;
	return (timeDiff < 3000);
}

bool DataExporter::ExportToTcxUsingCallbacks(const std::string& fileName, time_t startTime, const std::string& activityId, const std::string& activityType, NextCoordinateCallback nextCoordinateCallback, void* context)
{
	bool result = false;
	FileLib::TcxFileWriter writer;

	if (writer.CreateFile(fileName))
	{
		if (writer.StartActivity(activityType))
		{
			uint64_t lapStartTimeMs = startTime;
			uint64_t lapEndTimeMs = 0;

			bool done = false;

			writer.WriteId((time_t)(lapStartTimeMs / 1000));

			do
			{
				if (writer.StartLap(lapStartTimeMs))
				{
					if (writer.StartTrack())
					{
						Coordinate coordinate;

						while (nextCoordinateCallback(activityId.c_str(), &coordinate, context))
						{
							if ((coordinate.time > lapEndTimeMs) && (lapEndTimeMs != 0))
							{
								break;
							}

							writer.StartTrackpoint();
							writer.StoreTime(coordinate.time);
							writer.StorePosition(coordinate.latitude, coordinate.longitude);
							writer.StoreAltitudeMeters(coordinate.altitude);
							writer.EndTrackpoint();
						}

						result = writer.EndTrack();
					}
					writer.EndLap();
				}

				lapStartTimeMs = lapEndTimeMs;
			} while (!done);

			writer.EndActivity();
		}

		writer.CloseFile();
	}
	return result;
}

bool DataExporter::ExportToGpxUsingCallbacks(const std::string& fileName, time_t startTime, const std::string& activityId, NextCoordinateCallback nextCoordinateCallback, void* context)
{
	bool result = false;
	FileLib::GpxFileWriter writer;

	if (writer.CreateFile(fileName, APP_NAME))
	{
		writer.WriteMetadata((time_t)startTime);

		if (writer.StartTrack())
		{
			writer.WriteName("Untitled");

			if (writer.StartTrackSegment())
			{
				Coordinate coordinate;

				while (nextCoordinateCallback(activityId.c_str(), &coordinate, context))
				{
					writer.StartTrackPoint(coordinate.latitude, coordinate.longitude, coordinate.altitude, coordinate.time);
					writer.EndTrackPoint();
				}
				writer.EndTrackSegment();
			}

			result = writer.EndTrack();
		}

		writer.CloseFile();
	}
	return result;
}

bool DataExporter::ExportActivityFromDatabaseToFit(const std::string& fileName, Database* const pDatabase, const Activity* const pActivity)
{
	const MovingActivity* const pMovingActivity = dynamic_cast<const MovingActivity* const>(pActivity);
	if (!pMovingActivity)
	{
		return false;
	}

	bool result = false;
	FileLib::FitFileWriter writer;

	if (writer.CreateFile(fileName))
	{
		uint8_t fitSportType = FileLib::FitFileWriter::SportTypeToEnum(pActivity->GetType());

		if (writer.StartActivity() && writer.WriteSport(fitSportType))
		{
			std::string activityId = pActivity->GetId();

			const CoordinateList& coordinateList = pMovingActivity->GetCoordinates();

			LapSummaryList lapList;
			SensorReadingList hrList;
			SensorReadingList cadenceList;
			SensorReadingList powerList;

			pDatabase->RetrieveLaps(pActivity->GetId(), lapList);
			pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_HEART_RATE, hrList);
			pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_CADENCE, cadenceList);
			pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_POWER, powerList);

			CoordinateList::const_iterator coordinateIter = coordinateList.begin();
			LapSummaryList::const_iterator lapIter = lapList.begin();
			SensorReadingList::const_iterator hrIter = hrList.begin();
			SensorReadingList::const_iterator cadenceIter = cadenceList.begin();
			SensorReadingList::const_iterator powerIter = powerList.begin();

			uint64_t lapStartTimeMs = pActivity->GetStartTimeMs();
			uint64_t lapEndTimeMs = 0;
			uint16_t lapNum = 1;

			bool done = false;

			//
			// Write the definition message that describes what the records will look like.
			//
			
			do
			{
				//
				// Compute the lap end time.
				//

				if (lapIter == lapList.end())
				{
					lapEndTimeMs = pActivity->GetEndTimeMs();
					done = true;
				}
				else
				{
					lapEndTimeMs = (*lapIter).startTimeMs;
				}

				//
				// Write the lap message.
				//

				uint32_t lapStartTimeFit = FileLib::FitFileWriter::UnixTimestampToFitTimestamp(lapStartTimeMs / 1000);

				if (writer.StartLap(lapStartTimeFit))
				{
					while (coordinateIter != coordinateList.end())
					{
						const Coordinate& coordinate = (*coordinateIter);
						
						if ((coordinate.time > lapEndTimeMs) && (lapEndTimeMs != 0))
						{
							break;
						}
						
						FileLib::FitRecord rec;

						rec.timestamp = FileLib::FitFileWriter::UnixTimestampToFitTimestamp(coordinate.time / 1000);
						rec.positionLong = FileLib::FitFileWriter::DegreesToSemicircles(coordinate.longitude);
						rec.positionLat = FileLib::FitFileWriter::DegreesToSemicircles(coordinate.latitude);
						rec.altitude = (coordinate.altitude + 500) * 5.0;

						bool moreHrData = NearestSensorReading(coordinate.time, hrList, hrIter);
						bool moreCadenceData = NearestSensorReading(coordinate.time, cadenceList, cadenceIter);
						bool morePowerData = NearestSensorReading(coordinate.time, powerList, powerIter);

						if (moreHrData)
						{
							double rate = (*hrIter).reading.at(ACTIVITY_ATTRIBUTE_HEART_RATE);
							rec.heartRate = (uint8_t)rate;
						}
						else
						{
							rec.heartRate = FIT_INVALID_UINT8;
						}
						if (moreCadenceData)
						{
							double cadence = (*cadenceIter).reading.at(ACTIVITY_ATTRIBUTE_CADENCE);
							rec.cadence256 = (uint16_t)cadence;
						}
						else
						{
							rec.cadence256 = FIT_INVALID_UINT16;
						}
						if (morePowerData)
						{
							double power = (*powerIter).reading.at(ACTIVITY_ATTRIBUTE_POWER);
							rec.power = (uint16_t)power;
						}
						else
						{
							rec.power = FIT_INVALID_UINT16;
						}

						result = writer.WriteRecord(rec);
						if (!result)
						{
							break;
						}

						coordinateIter++;
					}
				}

				lapStartTimeMs = lapEndTimeMs;

				if (lapIter != lapList.end())
				{
					lapIter++;
					lapNum++;
				}

			} while (!done);

			lapList.clear();
			hrList.clear();
			cadenceList.clear();
		}

		//
		// Update the header with the number of bytes written.
		//

		writer.CloseFile();
	}

	return result;
}

bool DataExporter::ExportActivityFromDatabaseToTcx(const std::string& fileName, Database* const pDatabase, const Activity* const pActivity)
{
	const MovingActivity* const pMovingActivity = dynamic_cast<const MovingActivity* const>(pActivity);
	if (!pMovingActivity)
	{
		return false;
	}

	bool result = false;
	FileLib::TcxFileWriter writer;

	if (writer.CreateFile(fileName))
	{
		if (writer.StartActivity(pActivity->GetType()))
		{
			std::string activityId = pActivity->GetId();

			const CoordinateList& coordinateList = pMovingActivity->GetCoordinates();
			const TimeDistancePairList& distanceList = pMovingActivity->GetDistances();

			LapSummaryList lapList;
			SensorReadingList hrList;
			SensorReadingList cadenceList;
			SensorReadingList powerList;

			pDatabase->RetrieveLaps(pActivity->GetId(), lapList);
			pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_HEART_RATE, hrList);
			pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_CADENCE, cadenceList);
			pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_POWER, powerList);

			CoordinateList::const_iterator coordinateIter = coordinateList.begin();
			TimeDistancePairList::const_iterator distanceIter = distanceList.begin();
			LapSummaryList::const_iterator lapIter = lapList.begin();
			SensorReadingList::const_iterator hrIter = hrList.begin();
			SensorReadingList::const_iterator cadenceIter = cadenceList.begin();
			SensorReadingList::const_iterator powerIter = powerList.begin();

			uint64_t lapStartTimeMs = pActivity->GetStartTimeMs();
			uint64_t lapEndTimeMs = 0;
			uint16_t lapNum = 1;

			bool done = false;

			writer.WriteId((time_t)(lapStartTimeMs / 1000));

			do
			{
				// Compute the lap end time.
				if (lapIter == lapList.end())
				{
					lapEndTimeMs = pActivity->GetEndTimeMs();
					done = true;
				}
				else
				{
					lapEndTimeMs = (*lapIter).startTimeMs;
				}

				if (writer.StartLap(lapStartTimeMs))
				{
					// The TCX requires TotalTimeSeconds, DistanceMeters, and Calories for each lap.
					std::string attributeName = ACTIVITY_ATTRIBUTE_LAP_TIME + std::to_string(lapNum);
					ActivityAttributeType attr = pActivity->QueryActivityAttribute(attributeName);
					writer.StoreLapSeconds((uint64_t)attr.value.timeVal);
					attributeName = ACTIVITY_ATTRIBUTE_LAP_DISTANCE + std::to_string(lapNum);
					attr = pActivity->QueryActivityAttribute(attributeName);
					writer.StoreLapDistance(attr.value.doubleVal);
					attributeName = ACTIVITY_ATTRIBUTE_LAP_CALORIES + std::to_string(lapNum);
					attr = pActivity->QueryActivityAttribute(attributeName);
					writer.StoreLapCalories((uint16_t)attr.value.doubleVal);					
					
					if (writer.StartTrack())
					{
						while ((coordinateIter != coordinateList.end()) && (distanceIter != distanceList.end()))
						{
							const Coordinate& coordinate = (*coordinateIter);
							const TimeDistancePair& timeDistance = (*distanceIter);
							
							if ((coordinate.time > lapEndTimeMs) && (lapEndTimeMs != 0))
							{
								break;
							}

							writer.StartTrackpoint();
							writer.StoreTime(coordinate.time);
							writer.StorePosition(coordinate.latitude, coordinate.longitude);
							writer.StoreAltitudeMeters(coordinate.altitude);

							if (coordinateIter != coordinateList.begin())
							{
								writer.StoreDistanceMeters(timeDistance.distanceM);
								distanceIter++;
							}
							else
							{
								writer.StoreDistanceMeters((double)0.0);
							}

							bool moreHrData = NearestSensorReading(coordinate.time, hrList, hrIter);
							bool moreCadenceData = NearestSensorReading(coordinate.time, cadenceList, cadenceIter);
							bool morePowerData = NearestSensorReading(coordinate.time, powerList, powerIter);
							
							if (moreHrData)
							{
								double rate = (*hrIter).reading.at(ACTIVITY_ATTRIBUTE_HEART_RATE);
								writer.StoreHeartRateBpm((uint8_t)rate);
							}
							if (moreCadenceData)
							{
								double cadence = (*cadenceIter).reading.at(ACTIVITY_ATTRIBUTE_CADENCE);
								writer.StoreCadenceRpm((uint8_t)cadence);
							}
							if (morePowerData)
							{
								double power = (*powerIter).reading.at(ACTIVITY_ATTRIBUTE_POWER);
								writer.StartTrackpointExtensions();
								writer.StorePowerInWatts(power);
								writer.EndTrackpointExtensions();
							}
							
							writer.EndTrackpoint();

							coordinateIter++;
						}

						result = writer.EndTrack();
					}
					writer.EndLap();
				}

				lapStartTimeMs = lapEndTimeMs;

				if (lapIter != lapList.end())
				{
					lapIter++;
					lapNum++;
				}

			} while (!done);

			writer.EndActivity();

			lapList.clear();
			hrList.clear();
			cadenceList.clear();
		}

		writer.CloseFile();
	}
	return result;
}

bool DataExporter::ExportActivityFromDatabaseToGpx(const std::string& fileName, Database* const pDatabase, const Activity* const pActivity)
{
	bool result = false;
	FileLib::GpxFileWriter writer;

	if (writer.CreateFile(fileName, APP_NAME))
	{
		std::string activityId = pActivity->GetId();

		CoordinateList coordinateList;
		LapSummaryList lapList;
		SensorReadingList hrList;
		SensorReadingList cadenceList;
		SensorReadingList powerList;

		pDatabase->RetrieveActivityCoordinates(activityId, coordinateList);
		pDatabase->RetrieveLaps(activityId, lapList);
		pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_HEART_RATE, hrList);
		pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_CADENCE, cadenceList);
		pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_POWER, powerList);

		CoordinateList::const_iterator coordinateIter = coordinateList.begin();
		LapSummaryList::const_iterator lapIter = lapList.begin();
		SensorReadingList::const_iterator hrIter = hrList.begin();
		SensorReadingList::const_iterator cadenceIter = cadenceList.begin();
		SensorReadingList::const_iterator powerIter = powerList.begin();

		time_t activityStartTimeSec = 0;
		time_t activityEndTimeSec = 0;

		pDatabase->RetrieveActivityStartAndEndTime(activityId, activityStartTimeSec, activityEndTimeSec);

		uint64_t lapStartTimeMs = (uint64_t)activityStartTimeSec * 1000;
		uint64_t lapEndTimeMs = 0;

		bool done = false;

		writer.WriteMetadata((time_t)(lapStartTimeMs / 1000));

		if (writer.StartTrack())
		{
			ActivitySummary summary;

			if (pDatabase->RetrieveActivity(activityId, summary))
			{
				// Write the activity name or Untitled if it isn't set.
				if (summary.name.size() == 0)
				{
					writer.WriteName("Untitled");				
				}
				else
				{
					writer.WriteName(summary.name);
				}

				// Write the activity type.
				if (summary.type.size() > 0)
				{
					writer.WriteType(summary.type);
				}
			}

			do
			{
				// Compute the lap end time.
				if (lapIter == lapList.end())
				{
					lapEndTimeMs = (uint64_t)activityEndTimeSec * 1000;
					done = true;
				}
				else
				{
					lapEndTimeMs = (*lapIter).startTimeMs;
				}

				if (writer.StartTrackSegment())
				{
					while (coordinateIter != coordinateList.end())
					{
						const Coordinate& coordinate = (*coordinateIter);

						if ((coordinate.time > lapEndTimeMs) && (lapEndTimeMs != 0))
						{
							break;
						}

						writer.StartTrackPoint(coordinate.latitude, coordinate.longitude, coordinate.altitude, coordinate.time);

						bool moreHrData = NearestSensorReading(coordinate.time, hrList, hrIter);
						bool moreCadenceData = NearestSensorReading(coordinate.time, cadenceList, cadenceIter);
						bool morePowerData = NearestSensorReading(coordinate.time, powerList, powerIter);

						if (moreHrData || moreCadenceData)
						{
							writer.StartExtensions();
							writer.StartTrackPointExtensions();

							if (moreHrData)
							{
								const SensorReading& reading = (*hrIter);
								double rate = reading.reading.at(ACTIVITY_ATTRIBUTE_HEART_RATE);
								writer.StoreHeartRateBpm((uint8_t)rate);
							}
							if (moreCadenceData)
							{
								const SensorReading& reading = (*cadenceIter);
								double cadence = reading.reading.at(ACTIVITY_ATTRIBUTE_CADENCE);
								writer.StoreCadenceRpm((uint8_t)cadence);
							}
							if (morePowerData)
							{
								const SensorReading& reading = (*powerIter);
								double power = reading.reading.at(ACTIVITY_ATTRIBUTE_POWER);
								writer.StorePowerInWatts((uint32_t)power);
							}

							writer.EndTrackPointExtensions();
							writer.EndExtensions();
						}

						writer.EndTrackPoint();

						coordinateIter++;
					}
					writer.EndTrackSegment();
				}

				if (lapIter != lapList.end())
				{
					lapIter++;
				}

			} while (!done);

			result = writer.EndTrack();
		}

		coordinateList.clear();
		lapList.clear();
		hrList.clear();
		cadenceList.clear();
		
		writer.CloseFile();
	}
	return result;
}

bool DataExporter::ExportPositionDataToCsv(FileLib::CsvFileWriter& writer, const MovingActivity* const pMovingActivity)
{
	bool result = true;

	const CoordinateList& coordinateList = pMovingActivity->GetCoordinates();
	const TimeDistancePairList& distanceList = pMovingActivity->GetDistances();

	if (coordinateList.size() > 0)
	{
		std::vector<std::string> titles;
		titles.push_back(ACTIVITY_ATTRIBUTE_ELAPSED_TIME);
		titles.push_back(ACTIVITY_ATTRIBUTE_LATITUDE);
		titles.push_back(ACTIVITY_ATTRIBUTE_LONGITUDE);
		titles.push_back(ACTIVITY_ATTRIBUTE_ALTITUDE);
		titles.push_back(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED);

		result = writer.WriteValues(titles);

		CoordinateList::const_iterator coordinateIter = coordinateList.begin();
		TimeDistancePairList::const_iterator distanceIter = distanceList.begin();
		
		while ((coordinateIter != coordinateList.end()) && (distanceIter != distanceList.end()) && result)
		{
			const Coordinate& coordinate = (*coordinateIter);
			const TimeDistancePair& timeDistance = (*distanceIter);
			
			std::vector<double> values;
			values.push_back(coordinate.time);
			values.push_back(coordinate.latitude);
			values.push_back(coordinate.longitude);
			values.push_back(coordinate.altitude);
			
			if (coordinateIter != coordinateList.begin())
			{
				values.push_back(timeDistance.distanceM);
				distanceIter++;
			}
			else
			{
				values.push_back((double)0.0);
			}
			coordinateIter++;
			
			result = writer.WriteValues(values);
		}
	}
	return result;
}

bool DataExporter::ExportAccelerometerDataToCsv(FileLib::CsvFileWriter& writer, const std::string& activityId, Database* const pDatabase)
{
	SensorReadingList accelList;
	bool loaded = pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_ACCELEROMETER, accelList);
	bool result = true;

	if (loaded && (accelList.size() > 0))
	{
		std::vector<std::string> titles;
		titles.push_back(ACTIVITY_ATTRIBUTE_ELAPSED_TIME);
		titles.push_back(ACTIVITY_ATTRIBUTE_X);
		titles.push_back(ACTIVITY_ATTRIBUTE_Y);
		titles.push_back(ACTIVITY_ATTRIBUTE_Z);
		
		result = writer.WriteValues(titles);

		SensorReadingList::const_iterator accelIter = accelList.begin();

		while (accelIter != accelList.end() && result)
		{
			const SensorReading& reading = (*accelIter);

			double x = reading.reading.at(AXIS_NAME_X);
			double y = reading.reading.at(AXIS_NAME_Y);
			double z = reading.reading.at(AXIS_NAME_Z);

			std::vector<double> values;
			values.push_back(reading.time);
			values.push_back(x);
			values.push_back(y);
			values.push_back(z);
			
			result = writer.WriteValues(values);
			
			++accelIter;
		}
	}
	return result;
}

bool DataExporter::ExportHeartRateDataToCsv(FileLib::CsvFileWriter& writer, const std::string& activityId, Database* const pDatabase)
{
	SensorReadingList hrList;
	bool loaded = pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_HEART_RATE, hrList);
	bool result = true;

	if (loaded && (hrList.size() > 0))
	{
		std::vector<std::string> titles;
		titles.push_back(ACTIVITY_ATTRIBUTE_ELAPSED_TIME);
		titles.push_back(ACTIVITY_ATTRIBUTE_HEART_RATE);
		
		result = writer.WriteValues(titles);
		
		SensorReadingList::const_iterator hrIter = hrList.begin();
		
		while (hrIter != hrList.end() && result)
		{
			const SensorReading& reading = (*hrIter);
			
			double rate = reading.reading.at(ACTIVITY_ATTRIBUTE_HEART_RATE);
			
			std::vector<double> values;
			values.push_back(reading.time);
			values.push_back(rate);
			
			result = writer.WriteValues(values);
			
			++hrIter;
		}
	}
	return result;
}

bool DataExporter::ExportCadenceDataToCsv(FileLib::CsvFileWriter& writer, const std::string& activityId, Database* const pDatabase)
{
	SensorReadingList cadenceList;
	bool loaded = pDatabase->RetrieveSensorReadingsOfType(activityId, SENSOR_TYPE_CADENCE, cadenceList);
	bool result = true;

	if (loaded && (cadenceList.size() > 0))
	{
		std::vector<std::string> titles;
		titles.push_back(ACTIVITY_ATTRIBUTE_ELAPSED_TIME);
		titles.push_back(ACTIVITY_ATTRIBUTE_CADENCE);
		
		result = writer.WriteValues(titles);
		
		SensorReadingList::const_iterator cadenceIter = cadenceList.begin();
		
		while (cadenceIter != cadenceList.end() && result)
		{
			const SensorReading& reading = (*cadenceIter);
			
			double rate = reading.reading.at(ACTIVITY_ATTRIBUTE_CADENCE);
			
			std::vector<double> values;
			values.push_back(reading.time);
			values.push_back(rate);
			
			result = writer.WriteValues(values);
			
			++cadenceIter;
		}
	}
	return result;
}

bool DataExporter::ExportActivityFromDatabaseToCsv(const std::string& fileName, Database* const pDatabase, const Activity* const pActivity)
{
	bool result = false;
	FileLib::CsvFileWriter writer;

	if (writer.CreateFile(fileName))
	{
		const MovingActivity* const pMovingActivity = dynamic_cast<const MovingActivity* const>(pActivity);
		if (pMovingActivity)
		{
			result = ExportPositionDataToCsv(writer, pMovingActivity);
		}
		else
		{
			result = true;
		}

		result &= ExportAccelerometerDataToCsv(writer, pActivity->GetId(), pDatabase);
		result &= ExportHeartRateDataToCsv(writer, pActivity->GetId(), pDatabase);
		result &= ExportCadenceDataToCsv(writer, pActivity->GetId(), pDatabase);

		writer.CloseFile();
	}
	return result;
}

std::string DataExporter::GenerateFileName(FileFormat format, const std::string& name)
{
	std::string fileName = name;

	switch (format)
	{
		case FILE_UNKNOWN:
			break;
		case FILE_TEXT:
			fileName.append(".txt");
			break;
		case FILE_TCX:
			fileName.append(".tcx");
			break;
		case FILE_GPX:
			fileName.append(".gpx");
			break;
		case FILE_CSV:
			fileName.append(".csv");
			break;
		case FILE_ZWO:
			fileName.append(".zwo");
			break;
		case FILE_FIT:
			fileName.append(".fit");
			break;
		default:
			break;
	}

	return fileName;
}

std::string DataExporter::GenerateFileName(FileFormat format, time_t startTime, const std::string& sportType)
{
	std::string fileName;
	std::string sanitizedSportType = sportType;

	// Remove any characters that might cause problems down the road.
	std::replace_if(sanitizedSportType.begin(), sanitizedSportType.end(), [] (const char& c) { return std::isspace(c); }, '_');

	char buf[32];
	strftime(buf, sizeof(buf) - 1, "%Y-%m-%dT%H-%M-%S", localtime(&startTime));

	fileName.append(buf);
	fileName.append("-");
	fileName.append(sanitizedSportType);

	switch (format)
	{
		case FILE_UNKNOWN:
			break;
		case FILE_TEXT:
			fileName.append(".txt");
			break;
		case FILE_TCX:
			fileName.append(".tcx");
			break;
		case FILE_GPX:
			fileName.append(".gpx");
			break;
		case FILE_CSV:
			fileName.append(".csv");
			break;
		case FILE_ZWO:
			fileName.append(".zwo");
			break;
		case FILE_FIT:
			fileName.append(".fit");
			break;
		default:
			break;
	}

	return fileName;
}

bool DataExporter::ExportActivityFromDatabase(FileFormat format, std::string& fileName, Database* const pDatabase, const Activity* const pActivity)
{
	if (pActivity)
	{
		if (fileName.length() == 0 || fileName.at(fileName.length() - 1) != '/')
			fileName.append("/");
		fileName.append(GenerateFileName(format, pActivity->GetStartTimeSecs(), pActivity->GetType()));

		switch (format)
		{
			case FILE_UNKNOWN:
				return false;
			case FILE_TEXT:
				return false;
			case FILE_TCX:
				return ExportActivityFromDatabaseToTcx(fileName, pDatabase, pActivity);
			case FILE_GPX:
				return ExportActivityFromDatabaseToGpx(fileName, pDatabase, pActivity);
			case FILE_CSV:
				return ExportActivityFromDatabaseToCsv(fileName, pDatabase, pActivity);
			case FILE_ZWO:
				return false;
			case FILE_FIT:
				return ExportActivityFromDatabaseToFit(fileName, pDatabase, pActivity);
			default:
				return false;
		}
	}
	return false;
}

bool DataExporter::ExportActivityUsingCallbackData(FileFormat format, std::string& fileName, time_t startTime, const std::string& sportType, const std::string& activityId, NextCoordinateCallback nextCoordinateCallback, void* context)
{
	if (fileName.length() == 0 || fileName.at(fileName.length() - 1) != '/')
		fileName.append("/");
	fileName.append(GenerateFileName(format, startTime, sportType));

	switch (format)
	{
		case FILE_UNKNOWN:
			return false;
		case FILE_TEXT:
			return false;
		case FILE_TCX:
			return ExportToTcxUsingCallbacks(fileName, startTime, activityId, sportType, nextCoordinateCallback, context);
		case FILE_GPX:
			return ExportToGpxUsingCallbacks(fileName, startTime, activityId, nextCoordinateCallback, context);
		case FILE_CSV:
			return false;
		case FILE_ZWO:
			return false;
		case FILE_FIT:
			return false;
		default:
			return false;
	}
	return false;
}

bool DataExporter::ExportActivitySummary(const ActivitySummaryList& activities, const std::string& activityType, std::string& fileName)
{
	bool result = false;
	FileLib::CsvFileWriter writer;

	time_t startTime = time(NULL);
	
	char buf[32];
	strftime(buf, sizeof(buf) - 1, "%Y-%m-%dT%H-%M-%S", localtime(&startTime));
	
	fileName.append("/");
	fileName.append(buf);
	fileName.append("-");
	fileName.append(activityType);
	fileName.append("-Summary.csv");

	if (writer.CreateFile(fileName))
	{
		std::vector<std::string> attributesNames;

		result = true;

		for (auto activityIter = activities.begin(); activityIter != activities.end(); ++activityIter)
		{
			const ActivitySummary& summary = (*activityIter);

			if (summary.type.compare(activityType) == 0)
			{
				std::vector<std::string> values;

				// The first time we go through here we need to write out the column titles.
				if (attributesNames.size() == 0)
				{
					for (auto attrIter = summary.summaryAttributes.begin(); attrIter != summary.summaryAttributes.end(); ++attrIter)
						attributesNames.push_back(attrIter->first);
					std::sort(attributesNames.begin(), attributesNames.end());
					result &= writer.WriteValues(attributesNames);
				}

				for (auto attrIter = attributesNames.begin(); attrIter != attributesNames.end(); ++attrIter)
				{
					const std::string& attrName = (*attrIter);

					try
					{
						ActivityAttributeType value = summary.summaryAttributes.at(attrName);

						switch (value.valueType)
						{
							case TYPE_NOT_SET:
								values.push_back("-");
								break;
							case TYPE_TIME:
								snprintf(buf, sizeof(buf) - 1, "%ld", value.value.timeVal);
								values.push_back(buf);
								break;
							case TYPE_DOUBLE:
								snprintf(buf, sizeof(buf) - 1, "%.8lf", value.value.doubleVal);
								values.push_back(buf);
								break;
							case TYPE_INTEGER:
								snprintf(buf, sizeof(buf) - 1, "%llu", value.value.intVal);
								values.push_back(buf);
								break;
							default:
								values.push_back("-");
								break;
						}
					}
					catch (...)
					{
						values.push_back("-");
					}
				}

				result &= writer.WriteValues(values);
			}
		}

		writer.CloseFile();
	}

	return result;
}

bool DataExporter::ExportWorkoutFromDatabase(FileFormat format, std::string& fileName, Database* const pDatabase, const std::string& workoutId)
{
	bool result = false;

	std::string rootFileName = "Workout_";
	rootFileName += workoutId;
	
	fileName.append("/");
	fileName.append(GenerateFileName(format, rootFileName));

	if (format == FILE_ZWO)
	{
		Workout workout;

		if (pDatabase->RetrieveWorkout(workoutId, workout))
		{
			FileLib::ZwoFileWriter writer;

			if (writer.CreateFile(fileName, APP_NAME, "", ""))
			{
				std::vector<WorkoutInterval> intervals = workout.GetIntervals();

				result  = writer.StartWorkout();
				if (result)
				{
					for (auto intervalIter = intervals.begin(); intervalIter != intervals.end() && result; ++intervalIter)
					{
						const WorkoutInterval& interval = (*intervalIter);

						result &= writer.StartIntervals(interval.m_repeat, 0.0, 0.0, interval.m_distance * interval.m_pace, interval.m_recoveryDistance * interval.m_recoveryPace, interval.m_pace);
						result &= writer.EndIntervals();
					}

					result &= writer.EndWorkout();
					result &= writer.CloseAllTags();
				}
			}
		}
	}

	return result;
}
