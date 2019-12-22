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

	/// Serial queue to synchronize access to counters and data when loading or exporting workouts.
	static let workout = DispatchQueue(label: "Marco-Boschi.ios.Workout.loadExport")

}

extension HKObject: MetadataHolder {}
extension MetadataHolder {
	
	var elevationChange: (ascended: HKQuantity?, descended: HKQuantity?) {
		guard #available(iOS 11.2, *) else {
			return (nil, nil)
		}
		
		return (
			(self.metadata?[HKMetadataKeyElevationAscended] as? HKQuantity)?.filter(as: .meter()),
			(self.metadata?[HKMetadataKeyElevationDescended] as? HKQuantity)?.filter(as: .meter())
		)
	}
	
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
	
	/// Ensures that the receiver is a quanity compatible with the given unit.
	/// - returns: The receiver if compatible with the given unit, `nil` otherwise.
	func filter(as unit: HKUnit) -> HKQuantity? {
		guard self.is(compatibleWith: unit) else {
			return nil
		}
		
		return self
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
	public func formatAsDistance(withUnit unit: HKUnit, rawFormat: Bool = false) -> String {
		let value = self.doubleValue(for: unit)
		if rawFormat {
			return value.toString()
		} else {
			return distanceF.string(from: NSNumber(value: value))! + " \(unit.description)"
		}
	}
	
	/// Considers the receiver an elevation change and formats it accordingly.
	/// - parameter unit: The length unit to use in formatting.
	/// - returns: The formatted value.
	public func formatAsElevationChange(withUnit unit: HKUnit, rawFormat: Bool = false) -> String {
		let value = self.doubleValue(for: unit)
		if rawFormat {
			return value.toString()
		} else {
			return integerF.string(from: NSNumber(value: value))! + " \(unit.description)"
		}
	}

	/// Considers the receiver a pace and formats it accordingly.
	/// - parameter unit: The reference length unit to use in formatting.
	/// - returns: The formatted value.
	public func formatAsPace(withReferenceLength lUnit: HKUnit, rawFormat: Bool = false) -> String {
		let value = self.doubleValue(for: HKUnit.second().unitDivided(by: lUnit))
		if rawFormat {
			return value.rawDuration()
		} else {
			return "\(value.formattedDuration)/\(lUnit.description)"
		}
	}

	/// Considers the receiver a heart rate and formats it accordingly.
	/// - parameter unit: The heart rate unit to use in formatting.
	/// - returns: The formatted value.
	public func formatAsHeartRate(withUnit unit: HKUnit, rawFormat: Bool = false) -> String {
		let value = self.doubleValue(for: unit)
		if rawFormat {
			return value.toString()
		} else {
			return integerF.string(from: NSNumber(value: value))! + " bpm"
		}
	}

	/// Considers the receiver a speed and formats it accordingly.
	/// - parameter unit: The speed unit to use in formatting.
	/// - returns: The formatted value.
	public func formatAsSpeed(withUnit unit: HKUnit, rawFormat: Bool = false) -> String {
		let value = self.doubleValue(for: unit)
		if rawFormat {
			return value.toString()
		} else {
			return speedF.string(from: NSNumber(value: value))! + " \(unit.description)"
		}
	}

	/// Considers the receiver an energy and formats it accordingly.
	/// - parameter unit: The energy unit to use in formatting.
	/// - returns: The formatted value.
	public func formatAsEnergy(withUnit unit: HKUnit, rawFormat: Bool = false) -> String {
		let value = self.doubleValue(for: unit)
		if rawFormat {
			return value.toString()
		} else {
			return integerF.string(from: NSNumber(value: value))! + " \(unit.description)"
		}
	}

}

extension HKUnit {

	static let meterPerSecond = HKUnit.meter().unitDivided(by: .second())

	static let secondPerMeter = HKUnit.second().unitDivided(by: .meter())
	static let secondPerKilometer = HKUnit.second().unitDivided(by: .meterUnit(with: .kilo))

}
