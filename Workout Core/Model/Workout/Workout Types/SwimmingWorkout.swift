//
//  SwimmingWorkout.swift
//  Workout
//
//  Created by Marco Boschi on 04/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit
import MBLibrary

class SwimmingWorkout: Workout {
	
	required init(_ raw: HKWorkout, from healthData: Health, and preferences: Preferences, delegate del: WorkoutDelegate?) {
		super.init(raw, from: healthData, and: preferences, delegate: del)
		self.setUnitsFor(distance: .meterAndYard, speed: .kilometerAndMilePerHour, andPace: .kilometerAndMile)
		self.set(maxPace: HKQuantity(unit: .secondPerKilometer, doubleValue: 90 * 60))

		let details = MinuteByMinuteBreakdown(details: [.pace, .heart, .strokes], with: preferences)
		self.addAdditionalProcessorsAndProviders(details)

		if let distance = WorkoutDataQuery(typeID: .distanceSwimming, withUnit: .meter(), andTimeType: .ranged, searchingBy: .workout(fallbackToTime: true)) {
			self.addQuery(distance)
		}
		if let strokes = WorkoutDataQuery(typeID: .swimmingStrokeCount, withUnit: WorkoutUnit.strokes.default, andTimeType: .ranged, searchingBy: .time) {
			self.addQuery(strokes)
		}
	}
	
}
