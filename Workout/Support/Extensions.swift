//
//  Extensions.swift
//  Workout
//
//  Created by Marco Boschi on 08/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit

extension DispatchQueue {

	/// Serial queue to synchronize access to counters and data when loading and exporting workouts.
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
		if let mp = maxPace {
			return self <= mp ? self : nil
		} else {
			return self
		}
	}

	/// Considers the receiver a distance and formats it accordingly.
	/// - parameter unit: The length unit to use in formatting.
	/// - returns: The formatted value.
	func formatAsDistance(withUnit unit: HKUnit) -> String {
		return distanceF.string(from: NSNumber(value: self.doubleValue(for: unit)))! + " \(unit.description)"
	}

	/// Considers the receiver a pace and formats it accordingly.
	/// - parameter unit: The reference length unit to use in formatting.
	/// - returns: The formatted value.
	func formatAsPace(withReferenceLength lUnit: HKUnit) -> String {
		let unit = HKUnit.second().unitDivided(by: lUnit)
		return self.doubleValue(for: unit).getLocalizedDuration() + "/\(lUnit.description)"
	}

	/// Considers the receiver a heart rate and formats it accordingly.
	/// - parameter unit: The heart rate unit to use in formatting.
	/// - returns: The formatted value.
	func formatAsHeartRate(withUnit unit: HKUnit) -> String {
		return integerF.string(from: NSNumber(value: self.doubleValue(for: unit)))! + " bpm"
	}

	/// Considers the receiver a speed and formats it accordingly.
	/// - parameter unit: The speed unit to use in formatting.
	/// - returns: The formatted value.
	func formatAsSpeed(withUnit unit: HKUnit) -> String {
		return speedF.string(from: NSNumber(value: self.doubleValue(for: unit)))! + " \(unit.description)"
	}

	/// Considers the receiver an energy and formats it accordingly.
	/// - parameter unit: The energy unit to use in formatting.
	/// - returns: The formatted value.
	func formatAsEnergy(withUnit unit: HKUnit) -> String {
		return integerF.string(from: NSNumber(value: self.doubleValue(for: unit)))! + " \(unit.description)"
	}

}

extension HKUnit {

	static let meterPerSecond = HKUnit.meter().unitDivided(by: .second())
	static let secondPerMeter = HKUnit.second().unitDivided(by: .meter())

}
