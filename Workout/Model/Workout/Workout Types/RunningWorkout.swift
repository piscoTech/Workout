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

class RunningWorkout: Workout {
	
	required init(_ raw: HKWorkout, from healthData: Health, and preferences: Preferences) {
		super.init(raw, from: healthData, and: preferences)
		self.set(maxPace: HKQuantity(unit: .secondPerKilometer, doubleValue: 30 * 60))
		
		if raw.workoutActivityType == .running {
			let heartZone = RunningHeartZones(with: preferences)
			self.addAdditionalDataProcessorsAndProviders(heartZone)
		}
		
		let details = MinuteByMinuteBreakdown(details: [.pace, .heart, .steps])
		self.addAdditionalDataProcessorsAndProviders(details)
		
		if let distance = WorkoutDataQuery(typeID: .distanceWalkingRunning, withUnit: .meter(), andTimeType: .ranged, searchingBy: .workout(fallbackToTime: true)) {
			self.addQuery(distance)
		}
		if let steps = WorkoutDataQuery(typeID: .stepCount, withUnit: WorkoutUnit.steps.default,
										andTimeType: .ranged, searchingBy: .time,
										dataChanged: preferences.didChange.map { $0.stepSourceFilter }.removeDuplicates(),
										predicate: { p in preferences.stepSourceFilter.getPredicate(for: healthData.store, p)
		}) {
			self.addQuery(steps)
		}
	}
	
}
