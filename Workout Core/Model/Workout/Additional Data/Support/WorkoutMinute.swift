//
//  WorkoutMinute.swift
//  Workout
//
//  Created by Marco Boschi on 20/07/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import HealthKit
import MBLibrary

///Describe workout data in time range `startTime ..< endTime`.
class WorkoutMinute: CustomStringConvertible {

	private(set) weak var owner: Workout!
	let minute: UInt
	let startTime: TimeInterval
	var endTime: TimeInterval {
		didSet {
			precondition(duration >= 0 && duration <= 60, "Invalid endTime")
		}
	}
	var duration: TimeInterval {
		return endTime - startTime
	}
	var description: String {
		let dur = duration < 60 ? " \(duration.getRawDuration())" : ""
		return "\(minute)m\(dur): "
			+ (distance?.formatAsDistance(withUnit: owner.distanceUnit.default) ?? "- m")
			+ ", " + (heartRate?.formatAsHeartRate(withUnit: WorkoutUnit.heartRate.default) ?? "- bpm")
	}

	private var data = [HKQuantityTypeIdentifier: (unit: HKUnit, values: [HKQuantity])]()

	/// Distance covered in the minute, see `owner.distanceUnit` for the desired unit for presentation.
	var distance: HKQuantity? {
		var res = getTotal(for: .distanceWalkingRunning)
		res = res ?? getTotal(for: .distanceSwimming)

		// Don't expose a 0 distance, give nil instead
		if let dist = res, dist > HKQuantity(unit: .meter(), doubleValue: 0) {
			return dist
		} else {
			return nil
		}
	}
	/// Average pace of the minute in time per unit length, see `owner.paceUnit` for the desired unit for presentation.
	var pace: HKQuantity? {
		guard let dist = distance else {
			return nil
		}

		return HKQuantity(unit: .secondPerMeter, doubleValue: duration / dist.doubleValue(for: .meter()))
			.filterAsPace(withMaximum: owner?.maxPace)
	}
	/// Average speed of the minute in distance per unit time, see `owner.speedUnit` for the desired unit for presentation.
	var speed: HKQuantity? {
		guard let dist = distance, duration > 0 else {
			return nil
		}

		return HKQuantity(unit: .meterPerSecond, doubleValue: dist.doubleValue(for: .meter()) / duration)
	}

	var heartRate: HKQuantity? {
		return getAverage(for: .heartRate)
	}

	/// - parameter minute: The overall number of the minute.
	/// - parameter start: The number of the minute inside the parent segment. This is used to compute the start time of the minute inside the segment as `TimeInterval(start)*60`.
	init(minute: UInt, start: UInt, owner: Workout) {
		self.minute = minute
		self.startTime = TimeInterval(start) * 60
		self.endTime = startTime + 60

		self.owner = owner
	}

	// MARK: - Setter

	func set(unit: HKUnit, for type: HKQuantityTypeIdentifier) {
		DispatchQueue.workout.async {
			guard self.data[type] == nil else {
				return
			}

			self.data[type] = (unit, [])
		}
	}

	private func add(_ v: HKQuantity, to: HKQuantityTypeIdentifier) {
		//Adding data to the dictionary is invoked from HKQuery callback, move to a serial queue to synchonize access
		DispatchQueue.workout.async {
			if self.data[to] == nil {
				preconditionFailure("You must firstly set up the type using set(unit:for:)")
			}

			self.data[to]!.values.append(v)
		}
	}

	///Add the relevant part of the data to the minute.
	///- returns: `true` if some of the data belongs to following minutes, `false` otherwise.
	@discardableResult
	func add(_ data: RangedDataPoint, ofType type: HKQuantityTypeIdentifier) -> Bool {
		guard data.start != data.end else {
			let instant = InstantDataPoint(time: data.start, value: data.value)

			return self.add(instant, ofType: type)
		}

		DispatchQueue.workout.async {
			guard let unit = self.data[type]?.unit else {
				preconditionFailure("You must firstly set up the type using set(unit:for:)")
			}

			let val: Double?
			if data.start >= self.startTime && data.start < self.endTime {
				// Start time is in range
				let frac = (min(self.endTime, data.end) - data.start) / data.duration
				val = data.value.doubleValue(for: unit) * frac
			} else if data.start < self.startTime && data.end >= self.startTime {
				// Point started before the range but ends in or after the range
				let frac = (min(self.endTime, data.end) - self.startTime) / data.duration
				val = data.value.doubleValue(for: unit) * frac
			} else {
				val = nil
			}
			if let val = val {
				self.add(HKQuantity(unit: unit, doubleValue: val), to: type)
			}
		}

		return data.end > endTime
	}

	///Add the data to the minute if it belongs to it.
	///- returns: `true` if the data belongs to following minutes, `false` otherwise.
	@discardableResult
	func add(_ data: InstantDataPoint, ofType type: HKQuantityTypeIdentifier) -> Bool {
		if data.time >= startTime && data.time < endTime {
			add(data.value, to: type)
		}

		return data.time >= endTime
	}

	///Add the data or its relevant part to the minute if it belongs to it.
	///- returns: `true` if the data belongs to following minutes, `false` otherwise.
	@discardableResult func add(_ data: DataPoint, ofType type: HKQuantityTypeIdentifier) -> Bool {
		switch data {
		case let i as InstantDataPoint:
			return add(i, ofType: type)
		case let r as RangedDataPoint:
			return add(r, ofType: type)
		default:
			fatalError("Unknown data point type")
		}
	}

	// MARK: - Getter

	private func getRawTotal(for type: HKQuantityTypeIdentifier) -> Double? {
		guard let (unit, raw) = data[type] else {
			return nil
		}

		return raw.reduce(0) { $0 + $1.doubleValue(for: unit) }
	}

	func getAverage(for type: HKQuantityTypeIdentifier) -> HKQuantity? {
		guard let (unit, raw) = data[type], let total = getRawTotal(for: type) else {
			return nil
		}

		return raw.count > 0 ? HKQuantity(unit: unit, doubleValue: total / Double(raw.count)) : nil
	}

	func getTotal(for type: HKQuantityTypeIdentifier) -> HKQuantity? {
		guard let (unit, _) = data[type], let total = getRawTotal(for: type) else {
			return nil
		}

		return HKQuantity(unit: unit, doubleValue: total)
	}

}
