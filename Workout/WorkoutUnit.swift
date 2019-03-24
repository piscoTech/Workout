//
//  WorkoutUnit.swift
//  Workout
//
//  Created by Marco Boschi on 24/03/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import HealthKit

class WorkoutUnit: CustomStringConvertible {

	let metric: HKUnit
	let imperial: HKUnit

	init(metric: HKUnit, imperial: HKUnit) {
		precondition(HKQuantity(unit: metric, doubleValue: 1).is(compatibleWith: imperial), "Given units are not comaptible with each other")

		self.metric = metric
		self.imperial = imperial
	}

	convenience init(metricAndImperial: HKUnit) {
		self.init(metric: metricAndImperial, imperial: metricAndImperial)
	}

	/// The unit (metric or imperial) preferred by the user.
	var unit: HKUnit {
		return Preferences.useImperialUnits ? imperial : metric
	}

	var description: String {
		return unit.description
	}

	//MARK: - Predefined Units

	static let meter = WorkoutUnit(metricAndImperial: .meter())
	static let meterAndYard = WorkoutUnit(metric: .meter(), imperial: .yard())
	static let kilometerAndMile = WorkoutUnit(metric: .meterUnit(with: .kilo), imperial: .mile())

	static let calories = WorkoutUnit(metricAndImperial: .kilocalorie())

	static let heartRate = WorkoutUnit(metricAndImperial: HKUnit.count().unitDivided(by: HKUnit.minute()))

	static let steps = WorkoutUnit(metricAndImperial: HKUnit.count())
	static let strokes = WorkoutUnit(metricAndImperial: HKUnit.count())

}
