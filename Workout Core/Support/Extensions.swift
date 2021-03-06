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

	private static let workoutIdentifier = DispatchSpecificKey<String>()
	/// Serial queue to synchronize access to counters and data when loading or exporting workouts.
	static let workout: DispatchQueue = {
		let queueName = "Marco-Boschi.ios.Workout.loadExport"
		let q = DispatchQueue(label: queueName)
		q.setSpecific(key: workoutIdentifier, value: queueName)

		return q
	}()

	/// Whether the current queue is `DispatchQueue.workout` or not.
	static var isOnWorkout: Bool {
		return DispatchQueue.getSpecific(key: workoutIdentifier) == workout.label
	}


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
			return distanceF.string(from: NSNumber(value: value))! + " \(unit.symbol)"
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
			return integerF.string(from: NSNumber(value: value))! + " \(unit.symbol)"
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
			return "\(value.formattedDuration)/\(lUnit.symbol)"
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
			return speedF.string(from: NSNumber(value: value))! + " \(unit.symbol)"
		}
	}

	/// Considers the receiver a cadence and formats it accordingly.
	/// - parameter unit: The cadence unit to use in formatting.
	/// - returns: The formatted value.
	public func formatAsCadence(withUnit unit: HKUnit, rawFormat: Bool = false) -> String {
		let value = self.doubleValue(for: unit)
		if rawFormat {
			return value.toString()
		} else {
			let intSteps = Int(ceil(value))
			let str = String(format: NSLocalizedString("%lld_STEPS", comment: "%d step(s)"), intSteps)
			var unitStr = unit.symbol.description
			unitStr = String(unitStr[unitStr.range(of: "/")!.lowerBound...])
			if let stepNum = str.range(of: "\(intSteps)") {
				let steps = speedF.string(from: NSNumber(value: value))!
				return str.replacingCharacters(in: stepNum, with: steps) + unitStr
			} else {
				return "\(str)\(unitStr)"
			}
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
			return integerF.string(from: NSNumber(value: value))! + " \(unit.symbol)"
		}
	}

	/// Considers the receiver a temperature and formats it accordingly.
	/// - parameter unit: The temperature unit to use in formatting.
	/// - returns: The formatted value.
	public func formatAsTemperature(withUnit unit: HKUnit, rawFormat: Bool = false) -> String {
		let value = self.doubleValue(for: unit)
		if rawFormat {
			return value.toString()
		} else {
			return integerF.string(from: NSNumber(value: value))! + " \(unit.symbol)"
		}
	}

	/// Considers the receiver a percentage and formats it accordingly.
	/// - parameter unit: The percentage unit to use in formatting.
	/// - returns: The formatted value.
	public func formatAsPercentage(withUnit unit: HKUnit, rawFormat: Bool = false) -> String {
		let value = self.doubleValue(for: unit)
		if rawFormat {
			return value.toString()
		} else {
			return integerF.string(from: NSNumber(value: value))! + "\(unit.symbol)"
		}
	}

}

extension HKUnit {

	func `is`(compatibleWith unit: HKUnit) -> Bool {
		return HKQuantity(unit: self, doubleValue: 1).is(compatibleWith: unit)
	}

	/// A human readable symbol representing the unit.
	public var symbol: String {
		var symbol = self.description
		if self.is(compatibleWith: .degreeCelsius()) && symbol.starts(with: "deg") {
			// Simplify temperature symbols
			symbol = "°\(symbol[3...])"
		}

		return symbol
	}

	static let meterPerSecond = HKUnit.meter().unitDivided(by: .second())

	static let secondPerMeter = HKUnit.second().unitDivided(by: .meter())
	static let secondPerKilometer = HKUnit.second().unitDivided(by: .meterUnit(with: .kilo))

}
