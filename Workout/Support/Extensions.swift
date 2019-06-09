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

extension HKQuantity: Comparable {

	public static func < (lhs: HKQuantity, rhs: HKQuantity) -> Bool {
		return lhs.compare(rhs) == .orderedAscending
	}

	func `is`(compatibleWith unit: WorkoutUnit) -> Bool {
		return self.is(compatibleWith: unit.default)
	}

	///- parameter withMaximum: The max acceptable pace, if any, in time per unit length..
	func filterAsPace(withMaximum maxPace: HKQuantity?) -> HKQuantity? {
		if let mp = maxPace, self <= mp {
			return self
		} else {
			return nil
		}
	}

}

extension HKUnit {

	static let meterPerSecond = HKUnit.meter().unitDivided(by: .second())
	static let secondPerMeter = HKUnit.second().unitDivided(by: .meter())

}
