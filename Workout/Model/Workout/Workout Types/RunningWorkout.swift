//
//  RunningWorkout.swift
//  Workout
//
//  Created by Marco Boschi on 04/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit
import MBLibrary
import SwiftUI

class RunninWorkout: Workout {
	
	required init(_ raw: HKWorkout, from healthData: Health) {
		super.init(raw, from: healthData)
		self.set(maxPace: HKQuantity(unit: .secondPerKilometer, doubleValue: 30 * 60))
		
		if raw.workoutActivityType == .running {
			#warning("Add back and actually bind to the preference value")
//			let heartZone = RunningHeartZones()
//			self.addAdditionalDataProcessorsAndProviders(heartZone)
		}
		
		let details = MinuteByMinuteBreakdown(details: [.pace, .heart, .steps])
		self.addAdditionalDataProcessorsAndProviders(details)
		
		if let distance = WorkoutDataQuery(typeID: .distanceWalkingRunning, withUnit: .meter(), andTimeType: .ranged, searchingBy: .workout(fallbackToTime: true)) {
			self.addQuery(distance)
		}
		if let steps = WorkoutDataQuery(typeID: .stepCount, withUnit: WorkoutUnit.steps.default, andTimeType: .ranged, searchingBy: .time) {//, predicate: { p in appData.preferences.stepSourceFilter.getPredicate(for: appData.healthStore, p)
//		}) {
			// TODO: WorkoutDataQuery shoudl have a Publisher<Any,Never>? that when it publish a message triggers Workout.reload(). Workout should bind to it inside `addQuery` iff the query is not base.
			//			preferences.didChange.map { $0.stepSourceFilter }.removeDuplicates().map { s in
//			print("New step source \(s)")
//			return s
//		}
			// Workout should do
//			query.sink {
//				reload(query)
//			}
			// Remember to store the result of sink to keep the subscription
			#warning("Actually bind on the preference value")
			self.addQuery(steps)
		}
	}
	
}
