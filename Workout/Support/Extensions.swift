//
//  Extensions.swift
//  Workout
//
//  Created by Marco Boschi on 08/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit

extension TimeInterval {

	///- parameter forLengthUnit: The unit to use to represent the distance component
	///- returns: The formatted value, considered in time per `forLengthUnit`.
	func getFormattedPace(forLengthUnit unit: HKUnit) -> String {
		return getDuration() + "/\(unit.description)"
	}

	///- parameter withLengthUnit: The unit used to express the pace.
	///- parameter andMaxPace: The max acceptable pace, if any, in time per kilometer.
	func filterAsPace(withLengthUnit unit: HKUnit, andMaxPace: TimeInterval?) -> Double? {
		guard let maxPace = andMaxPace else {
			return self
		}

		let timeKm = HKUnit.second().unitDivided(by: .meterUnit(with: .kilo))
		let timeUnit = HKUnit.second().unitDivided(by: unit)

		return self.convertFrom(timeUnit, to: timeKm) > maxPace ? nil : self
	}

}

extension Double {

	///- returns: The formatted value, considered in the passed unit.
	func getFormattedDistance(withUnit unit: HKUnit) -> String {
		return distanceF.string(from: NSNumber(value: self))! + " \(unit.description)"
	}

	///- parameter forLengthUnit: The unit to use to represent the distance component
	///- returns: The formatted value, considered in `forLengthUnit` per hour.
	func getFormattedSpeed(forLengthUnit unit: HKUnit) -> String {
		return speedF.string(from: NSNumber(value: self))! + " \(unit.description)/h"
	}

	///- returns: The formatted value, considered in kilocalories.
	func getFormattedCalories() -> String {
		return integerF.string(from: NSNumber(value: self))! + " kcal"
	}

	func getFormattedHeartRate() -> String {
		return integerF.string(from: NSNumber(value: self))! + " bpm"
	}

	func convertFrom(_ un1: HKUnit, to un2: HKUnit) -> Double {
		let quant = HKQuantity(unit: un1, doubleValue: self)
		precondition(quant.is(compatibleWith: un2), "Units are not compatible")

		return quant.doubleValue(for: un2)
	}

}

extension DispatchQueue {

	///Serial queue to synchronize access to counters and data when loading and exporting workouts.
	static let workout = DispatchQueue(label: "Marco-Boschi.ios.Workout.loadExport")

}

extension HKQuantityTypeIdentifier {

	func getType() -> HKQuantityType? {
		return HKObjectType.quantityType(forIdentifier: self)
	}

}

extension HKQuantity {

	func `is`(compatibleWith unit: WorkoutUnit) -> Bool {
		return self.is(compatibleWith: unit.default)
	}

}
