//
//  IntervalSessionsVM.swift
//  Created by Michael Simms on 9/29/22.
//

import Foundation
import SwiftUI

let NO_INTERVAL_SESSION_INDEX: Int = -1

let MODIFIER_ADD_SETS = "Add Sets"
let MODIFIER_EDIT_SETS = "Edit Sets"

let MODIFIER_ADD_REPS = "Add Reps"
let MODIFIER_EDIT_REPS = "Edit Reps"

let MODIFIER_ADD_DURATION = "Add Duration (seconds)"
let MODIFIER_EDIT_DURATION = "Edit Duration (seconds)"

let MODIFIER_ADD_DISTANCE_METERS = "Add Distance (meters)"
let MODIFIER_EDIT_DISTANCE_METERS = "Edit Distance (meters)"

let MODIFIER_ADD_DISTANCE_KILOMETERS = "Add Distance (kilometers)"
let MODIFIER_EDIT_DISTANCE_KILOMETERS = "Edit Distance (kilometers)"

let MODIFIER_ADD_DISTANCE_FEET = "Add Distance (feet)"
let MODIFIER_EDIT_DISTANCE_FEET = "Edit Distance (feet)"

let MODIFIER_ADD_DISTANCE_YARDS = "Add Distance (yards)"
let MODIFIER_EDIT_DISTANCE_YARDS = "Edit Distance (yards)"

let MODIFIER_ADD_DISTANCE_MILES = "Add Distance (miles)"
let MODIFIER_EDIT_DISTANCE_MILES = "Edit Distance (miles)"

let MODIFIER_ADD_PACE_US_CUSTOMARY = "Add Pace (mins/mile)"
let MODIFIER_EDIT_PACE_US_CUSTOMARY = "Edit Pace (mins/mile)"

let MODIFIER_ADD_PACE_METRIC = "Add Pace (mins/km)"
let MODIFIER_EDIT_PACE_METRIC = "Edit Pace (mins/km)"

let MODIFIER_ADD_SPEED_US_CUSTOMARY = "Add Speed (mph)"
let MODIFIER_EDIT_SPEED_US_CUSTOMARY = "Edit Speed (mph)"

let MODIFIER_ADD_SPEED_METRIC = "Add Speed (kph)"
let MODIFIER_EDIT_SPEED_METRIC = "Edit Speed (kph)"

let MODIFIER_ADD_POWER = "Add Power (watts)"
let MODIFIER_EDIT_POWER = "Edit Power (watts)"

class IntervalSegment : Identifiable, Hashable, Equatable {
	var id: UUID = UUID()
	var firstValue: Double = 0.0
	var secondValue: Double = 0.0
	var firstUnits: IntervalUnit = INTERVAL_UNIT_NOT_SET  // Units for the first part of the description (ex: X secs at Y pace or X sets of Y reps)
	var secondUnits: IntervalUnit = INTERVAL_UNIT_NOT_SET // Units for the first second of the description (ex: X secs at Y pace or X sets of Y reps)

	/// Constructor
	init() {
	}
	init(json: Decodable) {
	}
	
	/// Hashable overrides
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}
	
	/// Equatable overrides
	static func == (lhs: IntervalSegment, rhs: IntervalSegment) -> Bool {
		return lhs.id == rhs.id
	}
	
	func validModifiers(activityType: String) -> Array<String> {
		var modifiers: Array<String> = []

		switch self.firstUnits {
		case INTERVAL_UNIT_NOT_SET:
			modifiers.append(MODIFIER_ADD_DURATION)
			modifiers.append(MODIFIER_ADD_DISTANCE_METERS)
			modifiers.append(MODIFIER_ADD_DISTANCE_KILOMETERS)
			modifiers.append(MODIFIER_ADD_DISTANCE_FEET)
			modifiers.append(MODIFIER_ADD_DISTANCE_YARDS)
			modifiers.append(MODIFIER_ADD_DISTANCE_MILES)
			modifiers.append(MODIFIER_ADD_SETS)
			break
		case INTERVAL_UNIT_SETS:
			modifiers.append(MODIFIER_EDIT_SETS)
			if self.secondUnits == INTERVAL_UNIT_NOT_SET {
				modifiers.append(MODIFIER_ADD_REPS)
			}
			break;
		case INTERVAL_UNIT_REPS:
			modifiers.append(MODIFIER_EDIT_REPS)
			break
		case INTERVAL_UNIT_SECONDS:
			modifiers.append(MODIFIER_EDIT_DURATION)
			if self.secondUnits == INTERVAL_UNIT_NOT_SET {
				modifiers.append(MODIFIER_ADD_PACE_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_PACE_METRIC)
				modifiers.append(MODIFIER_ADD_SPEED_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_SPEED_METRIC)
				modifiers.append(MODIFIER_ADD_POWER)
			}
			break
		case INTERVAL_UNIT_METERS:
			modifiers.append(MODIFIER_EDIT_DISTANCE_METERS)
			if self.secondUnits == INTERVAL_UNIT_NOT_SET {
				modifiers.append(MODIFIER_ADD_PACE_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_PACE_METRIC)
				modifiers.append(MODIFIER_ADD_SPEED_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_SPEED_METRIC)
				modifiers.append(MODIFIER_ADD_POWER)
			}
			break
		case INTERVAL_UNIT_KILOMETERS:
			modifiers.append(MODIFIER_EDIT_DISTANCE_KILOMETERS)
			if self.secondUnits == INTERVAL_UNIT_NOT_SET {
				modifiers.append(MODIFIER_ADD_PACE_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_PACE_METRIC)
				modifiers.append(MODIFIER_ADD_SPEED_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_SPEED_METRIC)
				modifiers.append(MODIFIER_ADD_POWER)
			}
			break
		case INTERVAL_UNIT_FEET:
			modifiers.append(MODIFIER_EDIT_DISTANCE_FEET)
			if self.secondUnits == INTERVAL_UNIT_NOT_SET {
				modifiers.append(MODIFIER_ADD_PACE_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_PACE_METRIC)
				modifiers.append(MODIFIER_ADD_SPEED_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_SPEED_METRIC)
				modifiers.append(MODIFIER_ADD_POWER)
			}
			break
		case INTERVAL_UNIT_YARDS:
			modifiers.append(MODIFIER_EDIT_DISTANCE_YARDS)
			if self.secondUnits == INTERVAL_UNIT_NOT_SET {
				modifiers.append(MODIFIER_ADD_PACE_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_PACE_METRIC)
				modifiers.append(MODIFIER_ADD_SPEED_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_SPEED_METRIC)
				modifiers.append(MODIFIER_ADD_POWER)
			}
			break
		case INTERVAL_UNIT_MILES:
			modifiers.append(MODIFIER_EDIT_DISTANCE_MILES)
			if self.secondUnits == INTERVAL_UNIT_NOT_SET {
				modifiers.append(MODIFIER_ADD_PACE_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_PACE_METRIC)
				modifiers.append(MODIFIER_ADD_SPEED_US_CUSTOMARY)
				modifiers.append(MODIFIER_ADD_SPEED_METRIC)
				modifiers.append(MODIFIER_ADD_POWER)
			}
			break
		case INTERVAL_UNIT_PACE_US_CUSTOMARY:
			modifiers.append(MODIFIER_EDIT_PACE_US_CUSTOMARY)
			break
		case INTERVAL_UNIT_PACE_METRIC:
			modifiers.append(MODIFIER_EDIT_PACE_METRIC)
			break
		case INTERVAL_UNIT_SPEED_US_CUSTOMARY:
			modifiers.append(MODIFIER_EDIT_SPEED_US_CUSTOMARY)
			break
		case INTERVAL_UNIT_SPEED_METRIC:
			modifiers.append(MODIFIER_EDIT_SPEED_METRIC)
			break
		case INTERVAL_UNIT_WATTS:
			modifiers.append(MODIFIER_EDIT_POWER)
			break
		default:
			break
		}
		return modifiers
	}
	
	func applyModifier(key: String, value: Double) {

		if key.contains(MODIFIER_ADD_SETS) {
			self.secondValue = value
			self.secondUnits = INTERVAL_UNIT_SETS
		}
		else if key.contains(MODIFIER_EDIT_SETS) {
			if self.firstUnits == INTERVAL_UNIT_SETS {
				self.firstValue = value
			}
			else {
				self.secondValue = value
			}
		}
		else if key.contains(MODIFIER_ADD_REPS) {
			self.secondValue = value
			self.secondUnits = INTERVAL_UNIT_REPS
		}
		else if key.contains(MODIFIER_EDIT_REPS) {
			if self.firstUnits == INTERVAL_UNIT_REPS {
				self.firstValue = value
			}
			else {
				self.secondValue = value
			}
		}
		else if key.contains(MODIFIER_ADD_DURATION) {
			self.secondValue = value
			self.secondUnits = INTERVAL_UNIT_SECONDS
		}
		else if key.contains(MODIFIER_EDIT_DURATION) {
			if self.firstUnits == INTERVAL_UNIT_SECONDS {
				self.firstValue = value
			}
			else {
				self.secondValue = value
			}
		}
		else if key.contains(MODIFIER_ADD_DISTANCE_METERS) {
			self.secondValue = value
			self.secondUnits = INTERVAL_UNIT_METERS
		}
		else if key.contains(MODIFIER_ADD_DISTANCE_KILOMETERS) {
			self.secondValue = value
			self.secondUnits = INTERVAL_UNIT_KILOMETERS
		}
		else if key.contains(MODIFIER_ADD_DISTANCE_FEET) {
			self.secondValue = value
			self.secondUnits = INTERVAL_UNIT_FEET
		}
		else if key.contains(MODIFIER_ADD_DISTANCE_YARDS) {
			self.secondValue = value
			self.secondUnits = INTERVAL_UNIT_YARDS
		}
		else if key.contains(MODIFIER_ADD_DISTANCE_MILES) {
			self.secondValue = value
			self.secondUnits = INTERVAL_UNIT_MILES
		}
		else if key.contains(MODIFIER_ADD_PACE_US_CUSTOMARY) {
			self.secondValue = value
			self.secondUnits = INTERVAL_UNIT_PACE_US_CUSTOMARY
		}
		else if key.contains(MODIFIER_ADD_PACE_METRIC) {
			self.secondValue = value
			self.secondUnits = INTERVAL_UNIT_PACE_METRIC
		}
		else if key.contains(MODIFIER_ADD_SPEED_US_CUSTOMARY) {
			self.secondValue = value
			self.secondUnits = INTERVAL_UNIT_SPEED_US_CUSTOMARY
		}
		else if key.contains(MODIFIER_ADD_SPEED_METRIC) {
			self.secondValue = value
			self.secondUnits = INTERVAL_UNIT_PACE_METRIC
		}
		else if key.contains(MODIFIER_ADD_POWER) {
			self.secondValue = value
			self.secondUnits = INTERVAL_UNIT_WATTS
		}
	}

	private func unitsStr(units: IntervalUnit) -> String {
		switch units {
		case INTERVAL_UNIT_NOT_SET:
			return ""
		case INTERVAL_UNIT_SETS:
			return "sets"
		case INTERVAL_UNIT_REPS:
			return "repititions"
		case INTERVAL_UNIT_SECONDS:
			return "seconds"
		case INTERVAL_UNIT_METERS:
			return "meters"
		case INTERVAL_UNIT_KILOMETERS:
			return "kms"
		case INTERVAL_UNIT_FEET:
			return "feet"
		case INTERVAL_UNIT_YARDS:
			return "yards"
		case INTERVAL_UNIT_MILES:
			return "miles"
		case INTERVAL_UNIT_PACE_US_CUSTOMARY:
			return "min/mile"
		case INTERVAL_UNIT_PACE_METRIC:
			return "km/mile"
		case INTERVAL_UNIT_SPEED_US_CUSTOMARY:
			return "mph"
		case INTERVAL_UNIT_SPEED_METRIC:
			return "kph"
		case INTERVAL_UNIT_WATTS:
			return "watts"
		default:
			break
		}
		return ""
	}

	private func formatDescriptionFragment(value: Double, units: IntervalUnit) -> String {
		return String(format: "%0.1lf %@", value, self.unitsStr(units: units))
	}

	func description() -> String {
		var description: String = ""

		if self.firstUnits != INTERVAL_UNIT_NOT_SET {
			description = self.formatDescriptionFragment(value: self.firstValue, units: self.firstUnits)

			if self.secondUnits != INTERVAL_UNIT_NOT_SET {
				if  self.secondUnits == INTERVAL_UNIT_PACE_US_CUSTOMARY ||
					self.secondUnits == INTERVAL_UNIT_PACE_METRIC ||
					self.secondUnits == INTERVAL_UNIT_SPEED_US_CUSTOMARY ||
					self.secondUnits == INTERVAL_UNIT_SPEED_METRIC ||
					self.secondUnits == INTERVAL_UNIT_WATTS {
					description += " at "
				}
				else if self.secondUnits == INTERVAL_UNIT_REPS {
					description += " of "
				}
				description += self.formatDescriptionFragment(value: self.secondValue, units: self.secondUnits)
			}
		}
		return description
	}
	
	func color() -> Color {
		switch self.firstUnits {
		case INTERVAL_UNIT_NOT_SET:
			break
		case INTERVAL_UNIT_SECONDS:
			return .red
		case INTERVAL_UNIT_SETS:
			return .white
		case INTERVAL_UNIT_REPS:
			return .white
		case INTERVAL_UNIT_METERS:
			return .blue
		case INTERVAL_UNIT_KILOMETERS:
			return .blue
		case INTERVAL_UNIT_FEET:
			return .blue
		case INTERVAL_UNIT_YARDS:
			return .blue
		case INTERVAL_UNIT_MILES:
			return .blue
		case INTERVAL_UNIT_PACE_US_CUSTOMARY:
			return .green
		case INTERVAL_UNIT_PACE_METRIC:
			return .green
		case INTERVAL_UNIT_SPEED_US_CUSTOMARY:
			return .cyan
		case INTERVAL_UNIT_SPEED_METRIC:
			return .cyan
		case INTERVAL_UNIT_WATTS:
			return .blue
		default:
			break
		}
		return .white
	}
}

class IntervalSession : Identifiable, Hashable, Equatable {
	var id: UUID = UUID()
	var name: String = "Untitled"
	var sport: String = ACTIVITY_TYPE_RUNNING
	var segments: Array<IntervalSegment> = []
	var lastUpdatedTime: Date = Date()

	/// Constructor
	init() {
	}
	init(json: Decodable) {
	}
	
	/// Hashable overrides
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}
	
	/// Equatable overrides
	static func == (lhs: IntervalSession, rhs: IntervalSession) -> Bool {
		return lhs.id == rhs.id
	}
}

class IntervalSessionsVM : ObservableObject {
	static let shared = IntervalSessionsVM()
	@Published var intervalSessions: Array<IntervalSession> = []

	/// Singleton Constructor
	private init() {
		buildIntervalSessionList()
	}

	func buildIntervalSessionList() -> Bool {
		var result = false

		// Remove any old ones.
		self.intervalSessions = []
		
		// Query the backend for the latest interval sessions.
		if InitializeIntervalWorkoutList() {
			var workoutIndex = 0
			var done = false
			
			while !done {
				let workoutDesc = RetrieveIntervalWorkoutAsJSON(workoutIndex)
				
				if workoutDesc == nil {
					done = true
				}
				else {
					let ptr = UnsafeRawPointer(workoutDesc)
					let tempWorkoutDesc = String(cString: ptr!.assumingMemoryBound(to: CChar.self))
					
					defer {
						ptr!.deallocate()
					}

					workoutIndex += 1
				}
			}
			
			result = true
		}
		
		return result
	}

	func createIntervalSession(session: IntervalSession) -> Bool {
		if CreateNewIntervalWorkout(session.id.uuidString, session.name, session.sport) {
			return buildIntervalSessionList()
		}
		return false
	}

	func deleteIntervalSession(intervalSessionId: UUID) -> Bool {
		if DeleteIntervalWorkout(intervalSessionId.uuidString) {
			return buildIntervalSessionList()
		}
		return false
	}
}
