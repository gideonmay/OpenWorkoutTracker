// Created by Michael Simms on 9/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#include "BikePlanGenerator.h"
#include "ActivityType.h"
#include "Goal.h"
#include "GoalType.h"
#include "WorkoutFactory.h"
#include "WorkoutPlanInputs.h"

#include <algorithm>
#include <math.h>
#include <numeric>
#include <random>

BikePlanGenerator::BikePlanGenerator()
{
}

BikePlanGenerator::~BikePlanGenerator()
{
}

uint8_t BikePlanGenerator::RoundDistance(uint8_t number, uint8_t nearest)
{
	return nearest * round(number / nearest);
}

/// @brief Returns TRUE if we can actually generate a plan with the given contraints.
bool BikePlanGenerator::IsWorkoutPlanPossible(std::map<std::string, double>& inputs)
{
	// If we're not planning to do any cycling then of course it's possible.
	double goalDistance = inputs.at(WORKOUT_INPUT_GOAL_BIKE_DISTANCE);
	if (goalDistance < 0.1)
		return true;

	bool hasBicycle = inputs.at(WORKOUT_INPUT_HAS_BICYCLE);
	return hasBicycle;
}

/// @brief Utility function for creating an interval workout.
Workout* BikePlanGenerator::GenerateHillRide(void)
{
	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_HILL_RIDE, ACTIVITY_TYPE_CYCLING);
	return workout;
}

/// @brief Utility function for creating an interval workout.
Workout* BikePlanGenerator::GenerateIntervalSession(double goalDistance)
{
	// Constants.
	const uint8_t NUM_REPS_INDEX = 0;
	const uint8_t SECONDS_HARD_INDEX = 1;
	const uint8_t PERCENTAGE_FTP_INDEX = 2;
	const uint8_t NUM_POSSIBLE_WORKOUTS = 5;
	
	// Tabata Intervals
	// 10x30 seconds hard / 20 seconds easy
	
	// V02 Max Intervals
	// 8x2 minutes hard / 2 min easy
	// 6x3 minutes hard / 2-3 min easy
	// 5x4 minutes hard / 2-3 min easy
	
	// Longer intervals for sustained power
	// 4x8 minutes hard / 2-4 min easy

	// Build a collection of possible bike interval sessions, sorted by target time. Order is { num reps, seconds hard, percentage of threshold power }.
	uint16_t POSSIBLE_WORKOUTS[NUM_POSSIBLE_WORKOUTS][3] = { { 10, 30, 170 }, { 8, 120, 140 }, { 6, 180, 130 }, { 5, 240, 120 }, { 4, 480, 120 } };

	// Warmup and cooldown duration.
	uint64_t warmupDuration = 10 * 60; // Ten minute warmup
	uint64_t cooldownDuration = 10 * 60; // Ten minute cooldown

	// Select the workout.
	std::default_random_engine generator(std::random_device{}());
	std::uniform_int_distribution<size_t> workoutDistribution(0, NUM_POSSIBLE_WORKOUTS - 1);
	size_t selectedIntervalWorkoutIndex = workoutDistribution(generator);
	uint16_t* selectedIntervalWorkout = POSSIBLE_WORKOUTS[selectedIntervalWorkoutIndex];

	// Fetch the details for this workout.
	uint16_t intervalReps = selectedIntervalWorkout[NUM_REPS_INDEX];
	uint16_t intervalSeconds = selectedIntervalWorkout[SECONDS_HARD_INDEX];
	double intervalPower = (double)selectedIntervalWorkout[PERCENTAGE_FTP_INDEX] / 100.0;
	uint16_t restSeconds = intervalSeconds / 2;
	double restPower = (double)0.4;

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_SPEED_INTERVAL_RIDE, ACTIVITY_TYPE_CYCLING);
	if (workout)
	{
		workout->AddWarmup(warmupDuration);
		workout->AddTimeAndPowerInterval(intervalReps, intervalSeconds, intervalPower, restSeconds, restPower);
		workout->AddCooldown(cooldownDuration);
	}

	return workout;
}

/// @brief Utility function for creating an easy ride.
/// Aerobic rides are typically around 55-75% FTP.
Workout* BikePlanGenerator::GenerateEasyAerobicRide(double goalDistance, double longestRideInFourWeeks, double avgRideDuration)
{
	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_EASY_RIDE, ACTIVITY_TYPE_CYCLING);
	if (workout)
	{
		// Select the power (% of FTP). Round to the nearest 5 watts
		std::default_random_engine generator(std::random_device{}());
		std::uniform_int_distribution<uint8_t> powerDistribution(55, 75);
		uint8_t intervalPower = powerDistribution(generator);
		intervalPower = RoundDistance(intervalPower, 5);

		workout->AddTimeAndPowerInterval(1, avgRideDuration, intervalPower, 0, 0);
	}
	return workout;
}

/// @brief Utility function for creating a tempo ride.
/// Tempo rides are typically around 75-85% FTP.
Workout* BikePlanGenerator::GenerateTempoRide(void)
{
	// Warmup and cooldown duration.
	uint64_t warmupDuration = 10 * 60; // Ten minute warmup
	uint64_t cooldownDuration = 10 * 60; // Ten minute cooldown

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_TEMPO_RIDE, ACTIVITY_TYPE_CYCLING);
	if (workout)
	{
		// Select the power (% of FTP). Round to the nearest 5 watts
		std::default_random_engine generator(std::random_device{}());
		std::uniform_int_distribution<uint8_t> powerDistribution(75, 85);
		uint8_t intervalPower = powerDistribution(generator);
		intervalPower = RoundDistance(intervalPower, 5);

		// Interval duration.
		std::uniform_int_distribution<uint64_t> intervalDistribution(2, 4);
		uint64_t numIntervalSeconds = intervalDistribution(generator) * 5 * 60;

		workout->AddWarmup(warmupDuration);
		workout->AddTimeAndPowerInterval(1, numIntervalSeconds, intervalPower, 0, 0);
		workout->AddCooldown(cooldownDuration);
	}
	return workout;
}

/// @brief Utility function for creating a sweet spot ride.
/// Sweet spot rides are typically around 85-95% FTP.
Workout* BikePlanGenerator::GenerateSweetSpotRide(void)
{
	// Warmup and cooldown duration.
	uint64_t warmupDuration = 10 * 60; // Ten minute warmup
	uint64_t cooldownDuration = 10 * 60; // Ten minute cooldown

	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_SWEET_SPOT_RIDE, ACTIVITY_TYPE_CYCLING);
	if (workout)
	{
		// Select the power (% of FTP). Round to the nearest 5 watts
		std::default_random_engine generator(std::random_device{}());
		std::uniform_int_distribution<uint8_t> powerDistribution(85, 95);
		uint8_t intervalPower = powerDistribution(generator);
		intervalPower = RoundDistance(intervalPower, 5);

		// Interval duration.
		std::uniform_int_distribution<uint64_t> intervalDistribution(2, 4);
		uint64_t numIntervalSeconds = intervalDistribution(generator) * 5 * 60;

		workout->AddWarmup(warmupDuration);
		workout->AddTimeAndPowerInterval(1, numIntervalSeconds, intervalPower, 0, 0);
		workout->AddCooldown(cooldownDuration);
	}
	return workout;
}

/// @brief Utility function for creating the goal workout/race.
Workout* BikePlanGenerator::GenerateGoalWorkout(double goalDistanceMeters, time_t goalDate)
{
	// Create the workout object.
	Workout* workout = WorkoutFactory::Create(WORKOUT_TYPE_EVENT, ACTIVITY_TYPE_CYCLING);
	if (workout)
	{
		workout->AddDistanceInterval(1, goalDistanceMeters, 0, 0, 0);
		workout->SetScheduledTime(goalDate);
	}
	
	return workout;
}

/// @brief Generates the workouts for the next week, but doesn't schedule them.
std::vector<Workout*> BikePlanGenerator::GenerateWorkouts(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy)
{
	std::vector<Workout*> workouts;

	// Extract the necessary inputs.
	Goal goal = (Goal)inputs.at(WORKOUT_INPUT_GOAL);
	GoalType goalType = (GoalType)inputs.at(WORKOUT_INPUT_GOAL_TYPE);
	time_t goalDate = (time_t)inputs.at(WORKOUT_INPUT_GOAL_DATE);
	double goalDistance = inputs.at(WORKOUT_INPUT_GOAL_BIKE_DISTANCE);
	double weeksUntilGoal = inputs.at(WORKOUT_INPUT_WEEKS_UNTIL_GOAL);
	double longestRideWeek1 = inputs.at(WORKOUT_INPUT_LONGEST_RIDE_WEEK_1); // Most recent week
	double longestRideWeek2 = inputs.at(WORKOUT_INPUT_LONGEST_RIDE_WEEK_2);
	double longestRideWeek3 = inputs.at(WORKOUT_INPUT_LONGEST_RIDE_WEEK_3);
	double longestRideWeek4 = inputs.at(WORKOUT_INPUT_LONGEST_RIDE_WEEK_4);
	double avgRideDuration = inputs.at(WORKOUT_INPUT_AVG_CYCLING_DURATION_IN_FOUR_WEEKS);
	bool hasBicycle = inputs.at(WORKOUT_INPUT_HAS_BICYCLE);

	// The user doesn't have a bicycle, so return.
	if (!hasBicycle)
	{
		return workouts;
	}

	// Longest run in four weeks.
	double longestRideInFourWeeks = std::max(std::max(longestRideWeek1, longestRideWeek2), std::max(longestRideWeek3, longestRideWeek4));

	// Are we in a taper?
	bool inTaper = this->IsInTaper(weeksUntilGoal, goal);

	if (goal == GOAL_FITNESS)
	{
		workouts.push_back(GenerateEasyAerobicRide(goalDistance, longestRideInFourWeeks, avgRideDuration));
		workouts.push_back(GenerateIntervalSession(goalDistance));
	}
	else
	{
		// Is this the goal week? If so, add that event.
		if ((goal != GOAL_FITNESS) && (weeksUntilGoal < (double)1.0) && PlanGenerator::ValidFloat(goalDistance, 0.1))
		{
			workouts.push_back(GenerateGoalWorkout(goalDistance, goalDate));
		}

		switch (goal)
		{
		// General fitness
		case GOAL_FITNESS:
			break;

		// Cross training to support medium distance running
		case GOAL_5K_RUN:
		case GOAL_10K_RUN:
		case GOAL_15K_RUN:
			workouts.push_back(GenerateEasyAerobicRide(goalDistance, longestRideInFourWeeks, avgRideDuration));
			workouts.push_back(GenerateEasyAerobicRide(goalDistance, longestRideInFourWeeks, avgRideDuration));
			break;

		// Cross training to support long distance running
		case GOAL_HALF_MARATHON_RUN:
		case GOAL_MARATHON_RUN:
			workouts.push_back(GenerateEasyAerobicRide(goalDistance, longestRideInFourWeeks, avgRideDuration));
			break;

		// Cross training to support ultra distance running
		case GOAL_50K_RUN:
		case GOAL_50_MILE_RUN:
			workouts.push_back(GenerateEasyAerobicRide(goalDistance, longestRideInFourWeeks, avgRideDuration));
			break;

		// Short distance triathlons
		case GOAL_SPRINT_TRIATHLON:
		case GOAL_OLYMPIC_TRIATHLON:
			workouts.push_back(GenerateEasyAerobicRide(goalDistance, longestRideInFourWeeks, avgRideDuration));
			if (inTaper || goalType == GOAL_TYPE_COMPLETION)
				workouts.push_back(GenerateEasyAerobicRide(goalDistance, longestRideInFourWeeks, avgRideDuration));
			else
				workouts.push_back(GenerateIntervalSession(goalDistance));
			break;

		// Long distance triathlons
		case GOAL_HALF_IRON_DISTANCE_TRIATHLON:
		case GOAL_IRON_DISTANCE_TRIATHLON:
			workouts.push_back(GenerateEasyAerobicRide(goalDistance, longestRideInFourWeeks, avgRideDuration));
			if (inTaper || goalType == GOAL_TYPE_COMPLETION)
				workouts.push_back(GenerateEasyAerobicRide(goalDistance, longestRideInFourWeeks, avgRideDuration));
			else
				workouts.push_back(GenerateIntervalSession(goalDistance));
			break;
		}
	}

	return workouts;
}
