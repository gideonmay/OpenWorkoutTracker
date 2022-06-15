// Created by Michael Simms on 9/5/20.
// Copyright (c) 2020 Michael J. Simms. All rights reserved.

#ifndef __BIKEPLANGENERATOR__
#define __BIKEPLANGENERATOR__

#include "PlanGenerator.h"

class BikePlanGenerator : PlanGenerator
{
public:
	BikePlanGenerator();
	virtual ~BikePlanGenerator();

	virtual bool IsWorkoutPlanPossible(std::map<std::string, double>& inputs);
	virtual std::vector<Workout*> GenerateWorkouts(std::map<std::string, double>& inputs, TrainingPhilosophyType trainingPhilosophy);
};

#endif
