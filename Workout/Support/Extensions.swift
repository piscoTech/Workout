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

	///- returns: The formatted value.
	func getFormattedPace(withUnit unit: HKUnit) -> String {
		let sep = "/"
		return getLocalizedDuration() + "\(sep)\(unit.description.components(separatedBy: sep)[1])"
	}

}

extension Double {

	///- returns: The formatted value.
	func getFormattedDistance(withUnit unit: HKUnit) -> String {
		return distanceF.string(from: NSNumber(value: self))! + " \(unit.description)"
	}

	///- returns: The formatted value.
	func getFormattedSpeed(withUnit unit: HKUnit) -> String {
		return speedF.string(from: NSNumber(value: self))! + " \(unit.description)"
	}

	///- returns: The formatted value.
	func getFormattedEnergy(withUnit unit: HKUnit) -> String {
		return integerF.string(from: NSNumber(value: self))! + " \(unit.description)"
	}

	func getFormattedHeartRate() -> String {
		return integerF.string(from: NSNumber(value: self))! + " bpm"
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
