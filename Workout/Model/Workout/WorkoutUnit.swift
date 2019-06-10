//
//  WorkoutUnit.swift
//  Workout
//
//  Created by Marco Boschi on 24/03/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import HealthKit

class WorkoutUnit {

	/// The unit for the default system of units, i.e. `Units.default`.
	let `default`: HKUnit
	/// The units for other system of units.
	let unitsLUT: [SystemOfUnits: HKUnit]

	/// Create a set of units using the provided ones, system of units with no specified unit default to the one provided for  the default system of units i.e. `Units.default`.
	init(units: [SystemOfUnits: HKUnit]) {
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

	func `is`(compatibleWith unit: HKUnit) -> Bool {
		return HKQuantity(unit: self.default, doubleValue: 1).is(compatibleWith: unit)
	}

	func `is`(compatibleWith unit: WorkoutUnit) -> Bool {
		return self.is(compatibleWith: unit.default)
	}

	/// The unit (metric or imperial) preferred by the user.
	func unit(for systemOfUnits: SystemOfUnits) -> HKUnit {
		return unitsLUT[systemOfUnits] ?? self.default
	}

	func description(for systemOfUnits: SystemOfUnits) -> String {
		return unit(for: systemOfUnits).description
	}

	//MARK: - Unit Combination

	private func combine(with unit: WorkoutUnit, using combinator: (HKUnit, HKUnit) -> HKUnit) -> WorkoutUnit {
		return WorkoutUnit(units: Dictionary(uniqueKeysWithValues: zip(SystemOfUnits.allCases, SystemOfUnits.allCases.map {
			combinator(self.unitsLUT[$0] ?? self.default, unit.unitsLUT[$0] ?? unit.default)
		})))
	}

	func divided(by unit: HKUnit) -> WorkoutUnit {
		return divided(by: WorkoutUnit(unit))
	}
	func divided(by unit: WorkoutUnit) -> WorkoutUnit {
		return combine(with: unit) { $0.unitDivided(by: $1) }
	}

	//MARK: - Predefined Units

	static let meter = WorkoutUnit(.meter())
	static let meterAndYard = WorkoutUnit(units: [.metric: .meter(), .imperial: .yard()])
	static let kilometerAndMile = WorkoutUnit(units: [.metric: .meterUnit(with: .kilo), .imperial: .mile()])

	static let kilometerAndMilePerHour = kilometerAndMile.divided(by: HKUnit.hour())

	static let calories = WorkoutUnit(.kilocalorie())

	static let heartRate = WorkoutUnit(HKUnit.count().unitDivided(by: HKUnit.minute()))

	static let steps = WorkoutUnit(HKUnit.count())
	static let strokes = WorkoutUnit(HKUnit.count())

}
