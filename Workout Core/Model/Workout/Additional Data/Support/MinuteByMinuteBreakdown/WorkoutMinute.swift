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
		let dur = duration < 60 ? " \(duration.rawDuration())" : ""
		return "\(minute)m\(dur): "
			+ (distance?.formatAsDistance(withUnit: owner.distanceUnit.default) ?? "- m")
			+ ", " + (heartRate?.formatAsHeartRate(withUnit: WorkoutUnit.heartRate.default) ?? "- bpm")
	}

	private var data = [HKQuantityTypeIdentifier: (unit: HKUnit, values: [HKQuantity])]()
	/// The totale elevation ascended during the minute, in meters.
	private(set) var elevationAscended: Double = 0
	/// The totale elevation descended during the minute, in meters.
	private(set) var elevationDescended: Double = 0

	/// Distance covered in the minute, see `owner.distanceUnit` for the desired unit for presentation.
	var distance: HKQuantity? {
		let distances = [HKQuantityTypeIdentifier.distanceWalkingRunning, .distanceSwimming, .distanceCycling]

		// Don't expose a 0 distance, give nil instead
		if let dist = distances.lazy.compactMap({ self.getTotal(for: $0) }).first, dist > HKQuantity(unit: .meter(), doubleValue: 0) {
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
	
	private func addElevationChange(from data: DataPoint, ofType type: HKQuantityTypeIdentifier, percentage: Double = 1) {
		precondition(percentage >= 0 && percentage <= 1, "Percentage must be in the range [0,1]")
		
		let distances: Set<HKQuantityTypeIdentifier>
		do {
			let oth: Set<HKQuantityTypeIdentifier>
			if #available(iOS 11.2, *) {
				oth = [.distanceDownhillSnowSports]
			} else {
				oth = []
			}
			distances = oth.union([.distanceCycling, .distanceWheelchair, .distanceWalkingRunning])
		}
		guard distances.contains(type) else {
			// It doesn't make sense to record elevation change for the given data type
			return
		}
		
		let (asc, desc) = data.elevationChange
		for (val, saveTo) in [(asc, \WorkoutMinute.elevationAscended), (desc, \.elevationDescended)] {
			guard let raw = val?.doubleValue(for: .meter()) else {
				// No data to save
				continue
			}
			
			self[keyPath: saveTo] += abs(raw)
		}
	}

	///Add the relevant part of the data to the minute.
	///- returns: `true` if some of the data belongs to following minutes, `false` otherwise.
	@discardableResult
	func add(_ data: RangedDataPoint, ofType type: HKQuantityTypeIdentifier) -> Bool {
		guard data.start != data.end else {
			let instant = InstantDataPoint(time: data.start, value: data.value, metadata: data.metadata)

			return self.add(instant, ofType: type)
		}

		DispatchQueue.workout.async {
			guard let unit = self.data[type]?.unit else {
				preconditionFailure("You must firstly set up the type using set(unit:for:)")
			}

			let frac: Double?
			if data.start >= self.startTime && data.start < self.endTime {
				// Start time is in range
				frac = (min(self.endTime, data.end) - data.start) / data.duration
			} else if data.start < self.startTime && data.end >= self.startTime {
				// Point started before the range but ends in or after the range
				frac = (min(self.endTime, data.end) - self.startTime) / data.duration
			} else {
				frac = nil
			}
			if let frac = frac {
				let val = data.value.doubleValue(for: unit) * frac
				self.add(HKQuantity(unit: unit, doubleValue: val), to: type)
				self.addElevationChange(from: data, ofType: type, percentage: frac)
			}
		}

		return data.end > endTime
	}

	///Add the data to the minute if it belongs to it.
	///- returns: `true` if the data belongs to following minutes, `false` otherwise.
	@discardableResult
	func add(_ data: InstantDataPoint, ofType type: HKQuantityTypeIdentifier) -> Bool {
		if data.time >= startTime && data.time < endTime {
			self.add(data.value, to: type)
			self.addElevationChange(from: data, ofType: type)
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

	private func getRawTotal(for type: HKQuantityTypeIdentifier) -> (unit: HKUnit, sum: Double, count: Int)? {
		let fetcher = { () -> (HKUnit, Double, Int)? in
			guard let (unit, raw) = self.data[type] else {
				return nil
			}

			return (unit, raw.reduce(0) { $0 + $1.doubleValue(for: unit) }, raw.count)
		}

		if DispatchQueue.isOnWorkout {
			return fetcher()
		} else {
			var result: (HKUnit, Double, Int)?
			DispatchQueue.workout.sync {
				result = fetcher()
			}

			return result
		}
	}

	/// Fetch the average for the given data type.
	func getAverage(for type: HKQuantityTypeIdentifier) -> HKQuantity? {
		guard let (unit, total, count) = getRawTotal(for: type) else {
			return nil
		}

		return count > 0 ? HKQuantity(unit: unit, doubleValue: total / Double(count)) : nil
	}

	/// Fetch the total for the given data type.
	func getTotal(for type: HKQuantityTypeIdentifier) -> HKQuantity? {
		guard let (unit, total, _) = getRawTotal(for: type) else {
			return nil
		}

		return HKQuantity(unit: unit, doubleValue: total)
	}

}
