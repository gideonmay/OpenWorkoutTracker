// Created by Michael Simms on 10/5/14.
// Copyright (c) 2014 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#import "HealthManager.h"
#import "ActivityAttribute.h"
#import "ActivityMgr.h"
#import "ActivityType.h"
#import "LeHeartRateMonitor.h"
#import "LeScale.h"
#import "Notifications.h"
#import "Preferences.h"
#import "UserProfile.h"

@interface HKUnit (HKManager)

+ (HKUnit*)heartBeatsPerMinuteUnit;

@end

@implementation HKUnit (HKManager)

+ (HKUnit*)heartBeatsPerMinuteUnit
{
	return [[HKUnit countUnit] unitDividedByUnit:[HKUnit minuteUnit]];
}

@end

@implementation HealthManager

- (id)init
{
	if (self = [super init])
	{
		self.healthStore = [[HKHealthStore alloc] init];
		self->heartRates = [[NSMutableArray alloc] init];
		self->workouts = [[NSMutableDictionary alloc] init];
		self->queryGroup = dispatch_group_create();

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(activityStopped:) name:@NOTIFICATION_NAME_ACTIVITY_STOPPED object:nil];
	}
	return self;
}

- (void)dealloc
{
}

#pragma mark HealthKit permissions

// Returns the types of data that Fit wishes to write to HealthKit.
- (NSSet*)dataTypesToWrite
{
#if TARGET_OS_WATCH
	HKQuantityType* hrType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
	HKQuantityType* activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
	return [NSSet setWithObjects: hrType, activeEnergyBurnType, nil];
#else
	HKQuantityType* heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
	HKQuantityType* weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
	HKQuantityType* hrType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
	HKQuantityType* bikeType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
	HKQuantityType* runType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
	HKQuantityType* activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
	return [NSSet setWithObjects: heightType, weightType, hrType, bikeType, runType, activeEnergyBurnType, nil];
#endif
}

// Returns the types of data that Fit wishes to read from HealthKit.
- (NSSet*)dataTypesToRead
{
#if TARGET_OS_WATCH
	HKQuantityType* heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
	HKQuantityType* weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
	HKCharacteristicType* birthdayType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
	HKCharacteristicType* biologicalSexType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex];
	return [NSSet setWithObjects: heightType, weightType, birthdayType, biologicalSexType, nil];
#else
	HKQuantityType* heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
	HKQuantityType* weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
	HKCharacteristicType* birthdayType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
	HKCharacteristicType* biologicalSexType = [HKObjectType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex];
	HKWorkoutType* workoutType = [HKObjectType workoutType];
	return [NSSet setWithObjects: heightType, weightType, birthdayType, biologicalSexType, workoutType, nil];
#endif
}

#pragma mark methods for managing authorization.

- (void)requestAuthorization
{
	if ([HKHealthStore isHealthDataAvailable])
	{
		NSSet* writeDataTypes = [self dataTypesToWrite];
		NSSet* readDataTypes = [self dataTypesToRead];

		// Request authorization. If granted update the user's metrics.
		[self.healthStore requestAuthorizationToShareTypes:writeDataTypes readTypes:readDataTypes completion:^(BOOL success, NSError* error)
		{
			if (success)
			{
				dispatch_async(dispatch_get_main_queue(), ^{
					[self updateUsersAge];
					[self updateUsersHeight];
					[self updateUsersWeight];
				});
			}
		}];
	}
}

#pragma mark methods for reading HealthKit data pertaining to the user's height, weight, etc.

- (void)mostRecentQuantitySampleOfType:(HKQuantityType*)quantityType predicate:(NSPredicate*)predicate completion:(void (^)(HKQuantity*, NSDate*, NSError*))completion
{
	NSSortDescriptor* timeSortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierEndDate ascending:NO];

	// Since we are interested in retrieving the user's latest sample, we sort the samples in descending
	// order, and set the limit to 1. We are not filtering the data, and so the predicate is set to nil.
	HKSampleQuery* query = [[HKSampleQuery alloc] initWithSampleType:quantityType predicate:nil
															   limit:1
													 sortDescriptors:@[timeSortDescriptor]
													  resultsHandler:^(HKSampleQuery* query, NSArray* results, NSError* error)
	{
		if (!results)
		{
			if (completion)
			{
				completion(nil, nil, error);
			}
			return;
		}

		if (completion)
		{
			// If quantity isn't in the database, return nil in the completion block.
			HKQuantitySample* quantitySample = results.firstObject;
			HKQuantity* quantity = quantitySample.quantity;
			NSDate* startDate = quantitySample.startDate;
			completion(quantity, startDate, error);
		}
	}];
	
	[self.healthStore executeQuery:query];
}

- (void)updateUsersAge
{
	NSError* error;
	NSDateComponents* dateOfBirth = [self.healthStore dateOfBirthComponentsWithError:&error];

	if (dateOfBirth)
	{
		NSCalendar* gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
		NSDate* tempDate = [gregorianCalendar dateFromComponents:dateOfBirth];
		[UserProfile setBirthDate:tempDate];
	}
}

- (void)updateUsersHeight
{
	HKQuantityType* heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
	
	[self mostRecentQuantitySampleOfType:heightType
							   predicate:nil
							  completion:^(HKQuantity* mostRecentQuantity, NSDate* startDate, NSError* error)
	 {
		 if (mostRecentQuantity)
		 {
			 HKUnit* heightUnit = [HKUnit inchUnit];
			 double usersHeight = [mostRecentQuantity doubleValueForUnit:heightUnit];
			 [UserProfile setHeightInInches:usersHeight];
		 }
	 }];
}

- (void)updateUsersWeight
{
	HKQuantityType* weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];

	[self mostRecentQuantitySampleOfType:weightType
							   predicate:nil
							  completion:^(HKQuantity* mostRecentQuantity, NSDate* startDate, NSError* error)
	 {
		if (mostRecentQuantity)
		{
			HKUnit* weightUnit = [HKUnit poundUnit];
			double usersWeight = [mostRecentQuantity doubleValueForUnit:weightUnit];
			[UserProfile setWeightInLbs:usersWeight];

			ActivityAttributeType tempWeight = InitializeActivityAttribute(TYPE_DOUBLE, MEASURE_WEIGHT, UNIT_SYSTEM_US_CUSTOMARY);
			tempWeight.value.doubleVal = usersWeight;
			ConvertToMetric(&tempWeight);

			NSDictionary* weightData = [[NSDictionary alloc] initWithObjectsAndKeys:
										[NSNumber numberWithDouble:usersWeight],@KEY_NAME_WEIGHT_KG,
										[NSNumber numberWithLongLong:time(NULL)],@KEY_NAME_TIME,
										nil];
			[[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_HISTORICAL_WEIGHT_READING object:weightData];
		}
	 }];
}

#pragma mark methods for managing workouts

- (NSInteger)getNumWorkouts
{
	return [self->workouts count];
}

- (void)clearWorkoutsList
{
	[self->workouts removeAllObjects];
}

- (void)readWorkoutsFromHealthStoreOfType:(HKWorkoutActivityType)activityType
{
	NSPredicate* predicate = [HKQuery predicateForWorkoutsWithWorkoutActivityType:activityType];
	NSSortDescriptor* sortDescriptor = [[NSSortDescriptor alloc] initWithKey:HKSampleSortIdentifierStartDate ascending:false];
	HKSampleQuery* sampleQuery = [[HKSampleQuery alloc] initWithSampleType:[HKWorkoutType workoutType]
																 predicate:predicate
																	 limit:HKObjectQueryNoLimit
														   sortDescriptors:@[sortDescriptor]
															resultsHandler:^(HKSampleQuery* query, NSArray* samples, NSError* error)
	{
		if (!error && samples)
		{
			@synchronized(self->workouts)
			{
				for (HKQuantitySample* sample in samples)
				{
					[self->workouts setObject:(HKWorkout*)sample forKey:[[NSUUID UUID] UUIDString]];
				}
			}
		}
		dispatch_group_leave(self->queryGroup);
	}];

	dispatch_group_enter(self->queryGroup);
	[self.healthStore executeQuery:sampleQuery];
}

- (void)readRunningWorkoutsFromHealthStore
{
	[self readWorkoutsFromHealthStoreOfType:HKWorkoutActivityTypeRunning];
}

- (void)readWalkingWorkoutsFromHealthStore
{
	[self readWorkoutsFromHealthStoreOfType:HKWorkoutActivityTypeWalking];
}

- (void)readCyclingWorkoutsFromHealthStore
{
	[self readWorkoutsFromHealthStoreOfType:HKWorkoutActivityTypeCycling];
}

- (void)readLocationPointsFromHealthStoreForWorkoutRoute:(HKWorkoutRoute*)route
{
	HKWorkoutRouteQuery* query = [[HKWorkoutRouteQuery alloc] initWithRoute:route
																dataHandler:^(HKWorkoutRouteQuery* query, NSArray<CLLocation*>* routeData, BOOL done, NSError *error)
	{
		for (CLLocation* location in routeData)
		{
		}
		dispatch_group_leave(self->queryGroup);
	}];

	dispatch_group_enter(self->queryGroup);
	[self.healthStore executeQuery:query];
}

- (void)readLocationPointsFromHealthStoreForWorkout:(HKWorkout*)workout
{
	NSPredicate* workoutPredicate = [HKQuery predicateForObjectsFromWorkout:workout];
	HKSampleType* type = [HKSeriesType workoutRouteType];
	HKQuery* query = [[HKAnchoredObjectQuery alloc] initWithType:type
													   predicate:workoutPredicate
														  anchor:nil
												   limit:HKObjectQueryNoLimit
												  resultsHandler:^(HKAnchoredObjectQuery* query,
																   NSArray<HKSample*>* sampleObjects,
																   NSArray<HKDeletedObject*>* deletedObjects,
																   HKQueryAnchor* newAnchor,
																   NSError* error)
	{
		for (HKWorkoutRoute* route in sampleObjects)
		{
			[self readLocationPointsFromHealthStoreForWorkoutRoute:route];
		}
		dispatch_group_leave(self->queryGroup);
	}];

	dispatch_group_enter(self->queryGroup);
	[self.healthStore executeQuery:query];
}

- (void)readLocationPointsFromHealthStoreForActivityId:(NSString*)activityId
{
	@synchronized(self->workouts)
	{
		HKWorkout* workout = [self->workouts objectForKey:activityId];
		if (workout)
		{
			[self readLocationPointsFromHealthStoreForWorkout:workout];
		}
	}
}

- (void)waitForHealthKitQueries
{
	dispatch_group_wait(self->queryGroup, DISPATCH_TIME_FOREVER);
}

- (void)removeOverlappingActivityWithStartTime:(time_t)startTime withEndTime:(time_t)endTime
{
	NSMutableArray* itemsToRemove = [NSMutableArray array];

	for (NSString* activityId in self->workouts)
	{
		HKWorkout* workout = [self->workouts objectForKey:activityId];

		time_t workoutStartTime = [workout.startDate timeIntervalSince1970];
		time_t workoutEndTime = [workout.endDate timeIntervalSince1970];

		if ((startTime >= workoutStartTime && startTime < workoutEndTime) ||
			(endTime < workoutEndTime && endTime >= workoutStartTime))
		{
			[itemsToRemove addObject:activityId];
		}
	}

	[self->workouts removeObjectsForKeys:itemsToRemove];
}

#pragma mark methods for querying workout data.

- (NSString*)convertIndexToActivityId:(size_t)index
{
	NSArray* keys = [self->workouts allKeys];
	return [keys objectAtIndex:index];
}

- (NSString*)getHistoricalActivityType:(NSString*)activityId
{
	HKWorkout* workout = [self->workouts objectForKey:activityId];
	if (workout)
	{
		HKWorkoutActivityType type = [workout workoutActivityType];
		switch (type)
		{
			case HKWorkoutActivityTypeCycling:
				return @"Cycling";
			case HKWorkoutActivityTypeRunning:
				return @"Running";
			case HKWorkoutActivityTypeWalking:
				return @"Walking";
			default:
				break;
		}
	}
	return nil;
}

- (void)getWorkoutStartAndEndTime:(NSString*)activityId withStartTime:(time_t*)startTime withEndTime:(time_t*)endTime
{
	HKWorkout* workout = [self->workouts objectForKey:activityId];
	if (workout)
	{
		(*startTime) = [workout.startDate timeIntervalSince1970];
		(*endTime) = [workout.endDate timeIntervalSince1970];
	}
}

- (NSInteger)getNumLocationPoints:(NSString*)activityId
{
	return 0;
}

- (double)quantityInUserPreferredUnits:(HKQuantity*)qty
{
	if ([Preferences preferredUnitSystem] == UNIT_SYSTEM_METRIC)
		return [qty doubleValueForUnit:[HKUnit meterUnitWithMetricPrefix:HKMetricPrefixKilo]];
	return [qty doubleValueForUnit:[HKUnit mileUnit]];
}

- (ActivityAttributeType)getWorkoutAttribute:(const char* const)attributeName forActivityId:(NSString*)activityId
{
	ActivityAttributeType attr;
	attr.valid = false;

	HKWorkout* workout = [self->workouts objectForKey:activityId];
	if (workout)
	{
		if (strncmp(attributeName, ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED, strlen(ACTIVITY_ATTRIBUTE_DISTANCE_TRAVELED)) == 0)
		{
			HKQuantity* qty = [workout totalDistance];
			attr.value.doubleVal = [self quantityInUserPreferredUnits:qty];
			attr.valueType = TYPE_DOUBLE;
			attr.measureType = MEASURE_DISTANCE;
			attr.valid = true;
		}
		else if (strncmp(attributeName, ACTIVITY_ATTRIBUTE_ELAPSED_TIME, strlen(ACTIVITY_ATTRIBUTE_ELAPSED_TIME)) == 0)
		{
			NSTimeInterval qty = [workout duration];
			attr.value.timeVal = (time_t)qty;
			attr.valueType = TYPE_TIME;
			attr.measureType = MEASURE_TIME;
			attr.valid = true;
		}
		else if (strncmp(attributeName, ACTIVITY_ATTRIBUTE_MAX_CADENCE, strlen(ACTIVITY_ATTRIBUTE_MAX_CADENCE)) == 0)
		{
			attr.value.doubleVal = (double)0.0;
			attr.valueType = TYPE_DOUBLE;
			attr.measureType = MEASURE_RPM;
			attr.valid = true;
		}
		else if (strncmp(attributeName, ACTIVITY_ATTRIBUTE_HEART_RATE, strlen(ACTIVITY_ATTRIBUTE_HEART_RATE)) == 0)
		{
			attr.value.doubleVal = (double)0.0;
			attr.valueType = TYPE_DOUBLE;
			attr.measureType = MEASURE_BPM;
			attr.valid = true;
		}
		else if (strncmp(attributeName, ACTIVITY_ATTRIBUTE_STARTING_LATITUDE, strlen(ACTIVITY_ATTRIBUTE_STARTING_LATITUDE)) == 0)
		{
			attr.value.doubleVal = (double)0.0;
			attr.valueType = TYPE_DOUBLE;
			attr.measureType = MEASURE_DEGREES;
			attr.valid = true;
		}
		else if (strncmp(attributeName, ACTIVITY_ATTRIBUTE_STARTING_LONGITUDE, strlen(ACTIVITY_ATTRIBUTE_STARTING_LONGITUDE)) == 0)
		{
			attr.value.doubleVal = (double)0.0;
			attr.valueType = TYPE_DOUBLE;
			attr.measureType = MEASURE_DEGREES;
			attr.valid = true;
		}
		else if (strncmp(attributeName, ACTIVITY_ATTRIBUTE_CALORIES_BURNED, strlen(ACTIVITY_ATTRIBUTE_CALORIES_BURNED)) == 0)
		{
			HKQuantity* qty = [workout totalEnergyBurned];
			attr.value.doubleVal = [self quantityInUserPreferredUnits:qty];
			attr.valueType = TYPE_DOUBLE;
			attr.measureType = MEASURE_CALORIES;
			attr.valid = true;
		}
	}
	return attr;
}

#pragma mark methods for writing HealthKit data

- (void)saveHeightIntoHealthStore:(double)heightInInches
{
	HKUnit* inchUnit = [HKUnit inchUnit];
	HKQuantity* heightQuantity = [HKQuantity quantityWithUnit:inchUnit doubleValue:heightInInches];
	HKQuantityType* heightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
	NSDate* now = [NSDate date];
	HKQuantitySample* heightSample = [HKQuantitySample quantitySampleWithType:heightType quantity:heightQuantity startDate:now endDate:now];
	[self.healthStore saveObject:heightSample withCompletion:^(BOOL success, NSError *error) {}];
}

- (void)saveWeightIntoHealthStore:(double)weightInPounds
{
	HKUnit* poundUnit = [HKUnit poundUnit];
	HKQuantity* weightQuantity = [HKQuantity quantityWithUnit:poundUnit doubleValue:weightInPounds];
	HKQuantityType* weightType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
	NSDate* now = [NSDate date];
	HKQuantitySample* weightSample = [HKQuantitySample quantitySampleWithType:weightType quantity:weightQuantity startDate:now endDate:now];
	[self.healthStore saveObject:weightSample withCompletion:^(BOOL success, NSError *error) {}];
}

- (void)saveHeartRateIntoHealthStore:(double)beats
{
	if (self->firstHeartRateSample)
	{
		self->lastHeartRateSample = [NSDate date];
	}
	else
	{
		self->firstHeartRateSample = self->lastHeartRateSample = [NSDate date];
	}

	[self->heartRates addObject:[[NSNumber alloc] initWithDouble:beats]];

	if ([self->lastHeartRateSample timeIntervalSinceDate:self->firstHeartRateSample] > 60)
	{
		double averageRate = (double)0.0;

		for (NSNumber* sample in self->heartRates)
		{
			averageRate += [sample doubleValue];
		}
		averageRate /= [self->heartRates count];

		HKQuantityType* rateType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
		HKQuantity* rateQuantity = [HKQuantity quantityWithUnit:[HKUnit heartBeatsPerMinuteUnit] doubleValue:averageRate];
		HKQuantitySample* rateSample = [HKQuantitySample quantitySampleWithType:rateType
																	   quantity:rateQuantity
																	  startDate:self->firstHeartRateSample
																		endDate:self->lastHeartRateSample];

		[self->heartRates removeAllObjects];

		self->firstHeartRateSample = NULL;
		self->lastHeartRateSample = NULL;

		[self.healthStore saveObject:rateSample withCompletion:^(BOOL success, NSError *error) {}];
	}
}

- (void)saveRunningWorkoutIntoHealthStore:(double)miles withStartDate:(NSDate*)startDate withEndDate:(NSDate*)endDate;
{
	HKUnit* mileUnit = [HKUnit mileUnit];
	HKQuantity* distanceQuantity = [HKQuantity quantityWithUnit:mileUnit doubleValue:miles];
	HKQuantityType* distanceType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
	HKQuantitySample* distanceSample = [HKQuantitySample quantitySampleWithType:distanceType quantity:distanceQuantity startDate:startDate endDate:endDate];
	[self.healthStore saveObject:distanceSample withCompletion:^(BOOL success, NSError *error) {}];
}

- (void)saveCyclingWorkoutIntoHealthStore:(double)miles withStartDate:(NSDate*)startDate withEndDate:(NSDate*)endDate;
{
	HKUnit* mileUnit = [HKUnit mileUnit];
	HKQuantity* distanceQuantity = [HKQuantity quantityWithUnit:mileUnit doubleValue:miles];
	HKQuantityType* distanceType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
	HKQuantitySample* distanceSample = [HKQuantitySample quantitySampleWithType:distanceType quantity:distanceQuantity startDate:startDate endDate:endDate];
	[self.healthStore saveObject:distanceSample withCompletion:^(BOOL success, NSError *error) {}];
}

- (void)saveCaloriesBurnedIntoHealthStore:(double)calories withStartDate:(NSDate*)startDate withEndDate:(NSDate*)endDate;
{
	HKUnit* calorieUnit = [HKUnit largeCalorieUnit];
	HKQuantity* calorieQuantity = [HKQuantity quantityWithUnit:calorieUnit doubleValue:calories * (double)1000.0];
	HKQuantityType* calorieType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
	HKQuantitySample* calorieSample = [HKQuantitySample quantitySampleWithType:calorieType quantity:calorieQuantity startDate:startDate endDate:endDate];
	[self.healthStore saveObject:calorieSample withCompletion:^(BOOL success, NSError *error) {}];
}

#pragma mark for getting heart rate updates from the watch

- (void)subscribeToHeartRateUpdates
{
	HKSampleType* sampleType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
	HKObserverQuery* query = [[HKObserverQuery alloc] initWithSampleType:sampleType
															   predicate:nil
														   updateHandler:^(HKObserverQuery* query, HKObserverQueryCompletionHandler completionHandler, NSError* error)
	{
		 if (!error)
		 {
			 HKQuantityType* hrType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];

			 [self mostRecentQuantitySampleOfType:hrType
										predicate:nil
									   completion:^(HKQuantity* mostRecentQuantity, NSDate* startDate, NSError* error)
			  {
				  if (mostRecentQuantity)
				  {
					  double hr = [mostRecentQuantity doubleValueForUnit:[HKUnit heartBeatsPerMinuteUnit]];
					  time_t unixTime = (time_t) [startDate timeIntervalSince1970];
					  NSDictionary* heartRateData = [[NSDictionary alloc] initWithObjectsAndKeys:
													 [NSNumber numberWithLong:(long)hr], @KEY_NAME_HEART_RATE,
													 [NSNumber numberWithLongLong:unixTime], @KEY_NAME_HRM_TIMESTAMP_MS,
													nil];
					  if (heartRateData)
					  {
						  [[NSNotificationCenter defaultCenter] postNotificationName:@NOTIFICATION_NAME_HRM object:heartRateData];
					  }
				  }
			  }];
		 }
	}];

	[self.healthStore executeQuery:query];
}

#pragma mark notifications

- (void)activityStopped:(NSNotification*)notification
{
	NSDictionary* activityData = [notification object];
	if (activityData)
	{
		NSString* activityType = [activityData objectForKey:@KEY_NAME_ACTIVITY_TYPE];
		NSNumber* startTime = [activityData objectForKey:@KEY_NAME_START_TIME];
		NSNumber* endTime = [activityData objectForKey:@KEY_NAME_END_TIME];
		NSNumber* distance = [activityData objectForKey:@KEY_NAME_DISTANCE];
		NSNumber* calories = [activityData objectForKey:@KEY_NAME_CALORIES];
		NSDate* startDate = [NSDate dateWithTimeIntervalSince1970:[startTime longLongValue]];
		NSDate* endDate = [NSDate dateWithTimeIntervalSince1970:[endTime longLongValue]];

		if ([activityType isEqualToString:@ACTIVITY_TYPE_CYCLING] ||
			[activityType isEqualToString:@ACTIVITY_TYPE_MOUNTAIN_BIKING])
		{
			[self saveCyclingWorkoutIntoHealthStore:[distance doubleValue] withStartDate:startDate withEndDate:endDate];
		}
		else if ([activityType isEqualToString:@ACTIVITY_TYPE_RUNNING] ||
				 [activityType isEqualToString:@ACTIVITY_TYPE_WALKING])
		{
			[self saveRunningWorkoutIntoHealthStore:[distance doubleValue] withStartDate:startDate withEndDate:endDate];
		}
		
		[self saveCaloriesBurnedIntoHealthStore:[calories doubleValue] withStartDate:startDate withEndDate:endDate];
	}
}

@end
