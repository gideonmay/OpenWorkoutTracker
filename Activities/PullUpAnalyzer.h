// Created by Michael Simms on 10/18/13.
// Copyright (c) 2012 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __PULLUPANALYZER__
#define __PULLUPANALYZER__

#include "GForceAnalyzer.h"

class PullUpAnalyzer : public GForceAnalyzer
{
public:
	PullUpAnalyzer();
	virtual ~PullUpAnalyzer();

	virtual std::string PrimaryAxis(void) const;
	virtual std::string SecondaryAxis(void) const;
};

#endif
