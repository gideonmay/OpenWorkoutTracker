//
//  HistoryVM.swift
//  Created by Michael Simms on 9/23/22.
//

import Foundation

extension RandomAccessCollection where Element : Comparable {
	func insertionIndex(of value: Element) -> Index {
		var slice : SubSequence = self[...]
		
		while !slice.isEmpty {
			let middle = slice.index(slice.startIndex, offsetBy: slice.count / 2)
			if value < slice[middle] {
				slice = slice[..<middle]
			} else {
				slice = slice[index(after: middle)...]
			}
		}
		return slice.startIndex
	}
}

class HistoryVM : ObservableObject {
	enum State {
		case empty
		case loaded
	}
	
	@Published private(set) var state = State.empty
	var historicalActivities: Array<ActivitySummary> = []

	init() {
		self.state = State.empty
	}

	/// @brief Loads the activity list from HealthKit (if enabled).
	private func loadActivitiesFromHealthKit() {
		if Preferences.willIntegrateHealthKitActivities() {

			// Read all relevant activities from HealthKit.
			HealthManager.shared.readAllActivitiesFromHealthStore()

			// De-duplicate the list against itself as well as the activities in our database.
			if Preferences.hideHealthKitDuplicates() {

				// Remove duplicate activities from within the HealthKit list.
				HealthManager.shared.removeDuplicateActivities()

				// Remove activities that overlap with ones in our database.
				let numDbActivities = GetNumHistoricalActivities()
				for activityIndex in 0..<numDbActivities {
					var startTime: time_t = 0
					var endTime: time_t = 0
					
					if GetHistoricalActivityStartAndEndTime(activityIndex, &startTime, &endTime) {
						HealthManager.shared.removeActivitiesThatOverlapWithStartTime(startTime: startTime, endTime:endTime)
					}
				}
			}

			// Incorporate HealthKit's list into the master list of activities.
			for workout in HealthManager.shared.workouts {
				let summary = ActivitySummary()
				summary.id = workout.key
				summary.name = ""
				summary.type = HealthManager.healthKitWorkoutToActivityType(workout: workout.value)
				summary.index = ACTIVITY_INDEX_UNKNOWN
				summary.startTime = workout.value.startDate
				summary.endTime = workout.value.endDate
				summary.source = ActivitySummary.Source.healthkit

				let index = self.historicalActivities.insertionIndex(of: summary)
				self.historicalActivities.insert(summary, at: index)
			}
		}
	}

	/// @brief Loads the activity list from our database.
	private func loadActivitiesFromDatabase() {
		InitializeHistoricalActivityList()

		if LoadAllHistoricalActivitySummaryData() {

			var activityIndex = 0
			var done = false

			// Minor performance optimization, since we know how many items will be in the list.
			self.historicalActivities.reserveCapacity(GetNumHistoricalActivities())

			while !done {

				var startTime: time_t = 0
				var endTime: time_t = 0

				// Load all data.
				if GetHistoricalActivityStartAndEndTime(activityIndex, &startTime, &endTime) {

					if endTime == 0 {
						FixHistoricalActivityEndTime(activityIndex)
					}

					let activityIdPtr = UnsafeRawPointer(ConvertActivityIndexToActivityId(activityIndex)) // this one is a const char*, so don't dealloc it

					let activityTypePtr = UnsafeRawPointer(GetHistoricalActivityType(activityIndex))
					let activityNamePtr = UnsafeRawPointer(GetHistoricalActivityName(activityIndex))
					let activityDescPtr = UnsafeRawPointer(GetHistoricalActivityDescription(activityIndex))

					defer {
						activityTypePtr!.deallocate()
						activityNamePtr!.deallocate()
						activityDescPtr!.deallocate()
					}

					if activityTypePtr == nil || activityNamePtr == nil || activityDescPtr == nil {
						done = true
					}
					else {
						let summary = ActivitySummary()

						let activityId = String(cString: activityIdPtr!.assumingMemoryBound(to: CChar.self))
						let activityName = String(cString: activityNamePtr!.assumingMemoryBound(to: CChar.self))
						let activityType = String(cString: activityTypePtr!.assumingMemoryBound(to: CChar.self))
						let activityDesc = String(cString: activityDescPtr!.assumingMemoryBound(to: CChar.self))

						summary.id = activityId
						summary.name = activityName
						summary.type = activityType
						summary.description = activityDesc
						summary.index = activityIndex
						summary.startTime = Date(timeIntervalSince1970: TimeInterval(startTime))
						summary.endTime = Date(timeIntervalSince1970: TimeInterval(endTime))
						summary.source = ActivitySummary.Source.database

						self.historicalActivities.insert(summary, at: 0)

						activityIndex += 1
					}
				}
				else {
					done = true
				}
			}
		}
	}

	/// @brief Loads the activity list from our database as well as HealthKit (if enabled).
	func buildHistoricalActivitiesList(createAllObjects: Bool) {
		self.loadActivitiesFromDatabase()
		self.loadActivitiesFromHealthKit()
		if createAllObjects {
			CreateAllHistoricalActivityObjects()
		}
		self.state = State.loaded
	}

	func getFormattedTotalActivityAttribute(activityType: String, attributeName: String) -> String {
		let attr = QueryActivityAttributeTotalByActivityType(attributeName, activityType)
		return LiveActivityVM.formatActivityValue(attribute: attr)
	}

	func getFormattedBestActivityAttribute(activityType: String, attributeName: String, smallestIsBest: Bool) -> String {
		let attr = QueryBestActivityAttributeByActivityType(attributeName, activityType, smallestIsBest, nil)
		return LiveActivityVM.formatActivityValue(attribute: attr)
	}

	/// @brief Utility function for getting the image name that corresponds to an activity, such as running, cycling, etc.
	static func imageNameForActivityType(activityType: String) -> String {
		if activityType == ACTIVITY_TYPE_BENCH_PRESS {
			return "scalemass"
		}
		if activityType == ACTIVITY_TYPE_CHINUP {
			return "scalemass"
		}
		if activityType == ACTIVITY_TYPE_CYCLING {
			return "bicycle"
		}
		if activityType == ACTIVITY_TYPE_HIKING {
			return "figure.walk"
		}
		if activityType == ACTIVITY_TYPE_MOUNTAIN_BIKING {
			return "bicycle"
		}
		if activityType == ACTIVITY_TYPE_RUNNING {
			return "figure.walk"
		}
		if activityType == ACTIVITY_TYPE_SQUAT {
			return "scalemass"
		}
		if activityType == ACTIVITY_TYPE_STATIONARY_BIKE {
			return "bicycle"
		}
		if activityType == ACTIVITY_TYPE_TREADMILL {
			return "figure.walk"
		}
		if activityType == ACTIVITY_TYPE_PULLUP {
			return "scalemass"
		}
		if activityType == ACTIVITY_TYPE_PUSHUP {
			return "scalemass"
		}
		if activityType == ACTIVITY_TYPE_WALKING {
			return "figure.walk"
		}
		if activityType == ACTIVITY_TYPE_OPEN_WATER_SWIMMING {
			return "stopwatch"
		}
		if activityType == ACTIVITY_TYPE_POOL_SWIMMING {
			return "stopwatch"
		}
		if activityType == ACTIVITY_TYPE_DUATHLON {
			return "2.circle"
		}
		if activityType == ACTIVITY_TYPE_TRIATHLON {
			return "3.circle"
		}
		return "stopwatch"
	}
}
