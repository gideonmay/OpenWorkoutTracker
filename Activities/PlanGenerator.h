// Created by Michael Simms on 6/15/22.
// Copyright (c) 2022 Michael J. Simms. All rights reserved.

#ifndef __PLANGENERATOR__
#define __PLANGENERATOR__

#include <map>
#include <string>
#include <vector>

#include "TrainingPhilosophyType.h"
#include "Workout.h"

class PlanGenerator
{
public:
	PlanGenerator() {};
	virtual ~PlanGenerator() {};

	virtual bool IsWorkoutPlanPossible(std::map<std::string, double>& inputs) = 0;
	virtual std::vector<Workout*> GenerateWorkouts(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy) = 0;
};

#endif