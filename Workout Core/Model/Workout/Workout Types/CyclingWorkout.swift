//
//  CyclingWorkout.swift
//  Workout Core
//
//  Created by Marco Boschi on 26/07/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit
import MBLibrary

class CyclingWorkout: Workout {
	
	required init(_ raw: HKWorkout, from healthData: Health, and preferences: Preferences, delegate del: WorkoutDelegate?) {
		super.init(raw, from: healthData, and: preferences, delegate: del)
		self.set(maxPace: HKQuantity(unit: .secondPerKilometer, doubleValue: 30 * 60))
		
		let details = MinuteByMinuteBreakdown(details: [.speed, .heart], with: preferences)
		self.addAdditionalDataProcessorsAndProviders(details)
		
		if let distance = WorkoutDataQuery(typeID: .distanceCycling, withUnit: .meter(), andTimeType: .ranged, searchingBy: .workout(fallbackToTime: true)) {
			self.addQuery(distance)
		}
	}
	
}
