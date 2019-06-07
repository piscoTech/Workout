//
//  WorkoutUnit.swift
//  Workout
//
//  Created by Marco Boschi on 24/03/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import HealthKit

class WorkoutUnit: CustomStringConvertible {

	/// The unit for the default system of units, i.e. `Units.default`.
	let `default`: HKUnit
	/// The units for other system of units.
	let unitsLUT: [Units: HKUnit]

	/// Create a set of units using the provided ones, system of units with no specified unit default to the one provided for  the default system of units i.e. `Units.default`.
	init(units: [Units: HKUnit]) {
		guard let def = units[.default] else {
			preconditionFailure("Unit for the default system of units not provided")
		}
		self.default = def
		
		precondition(units.values.reduce(true, { $0 && HKQuantity(unit: $1, doubleValue: 1).is(compatibleWith: def) }), "Given units are not comaptible with each other")

		self.unitsLUT = units
	}

	/// Create a set of units using the provided one for all system of units.
	convenience init(_ unit: HKUnit) {
		self.init(units: [.default: unit])
	}

	/// The unit (metric or imperial) preferred by the user.
	var unit: HKUnit {
		return unitsLUT[Preferences.systemOfUnits] ?? self.default
	}

	var description: String {
		return unit.description
	}

	//MARK: - Predefined Units

	static let meter = WorkoutUnit(.meter())
	static let meterAndYard = WorkoutUnit(units: [.metric: .meter(), .imperial: .yard()])
	static let kilometerAndMile = WorkoutUnit(units: [.metric: .meterUnit(with: .kilo), .imperial: .mile()])

	static let calories = WorkoutUnit(.kilocalorie())

	static let heartRate = WorkoutUnit(HKUnit.count().unitDivided(by: HKUnit.minute()))

	static let steps = WorkoutUnit(HKUnit.count())
	static let strokes = WorkoutUnit(HKUnit.count())

}
