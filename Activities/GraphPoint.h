// Created by Michael Simms on 4/20/13.
// Copyright (c) 2013 Michael J. Simms. All rights reserved.

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

#ifndef __GRAPH_POINT__
#define __GRAPH_POINT__

#include <stdint.h>

class GraphPoint
{
public:
	size_t   index;
	uint64_t x;
	double   y;
	
	GraphPoint()
	{
		index = 0;
		x = 0;
		y = (double)0.0;
	}

	GraphPoint(const GraphPoint& rhs)
	{
		index = rhs.index;
		x = rhs.x;
		y = rhs.y;
	}

	GraphPoint& operator=(const GraphPoint& rhs)
	{
		index = rhs.index;
		x = rhs.x;
		y = rhs.y;
		return *this;
	}
};

#endif
