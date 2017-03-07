//
//  WorkoutMinute.swift
//  Workout
//
//  Created by Marco Boschi on 20/07/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary
import HealthKit

///Describe workout data in time range `startTime ..< endTime`.
class WorkoutMinute: CustomStringConvertible {
	
	private(set) weak var owner: Workout!
	var minute: UInt
	var startTime: TimeInterval {
		return Double(minute) * 60
	}
	var endTime: TimeInterval {
		didSet {
			precondition(duration >= 0 && duration <= 60, "Invalid endTime")
		}
	}
	var duration: TimeInterval {
		return endTime - startTime
	}
	var description: String {
		get {
			let dur = duration < 60 ? " \(duration.getDuration())" : ""
			return "\(minute)m\(dur): " + (distance?.getFormattedDistance(withUnit: owner.distanceUnit) ?? "- m") + ", " + (bpm?.getFormattedHeartRate() ?? "- bpm")
		}
	}
	
	private var data = [HKQuantityTypeIdentifier: [Double]]()
	
	private var rawDistance: Double? {
		var res = getTotal(for: .distanceWalkingRunning)
		
		if #available(iOS 10, *) {
			res = res ?? getTotal(for: .distanceSwimming)
		}
		
		return res
	}
	///Distance in `distanceUnit` as specified by `owner`.
	var distance: Double? {
		return rawDistance?.convertFrom(.meter(), to: owner.distanceUnit)
	}
	///Avarage pace of the minute in seconds per `paceUnit` specified by `owner`.
	var pace: TimeInterval? {
		if let d = rawDistance?.convertFrom(.meter(), to: owner.paceUnit) {
			return duration / d
		} else {
			return nil
		}
	}
	///Avarage speed of the minute in `speedUnit`, specified by `owner`, per hour.
	var speed: Double? {
		guard let dist = rawDistance?.convertFrom(.meter(), to: owner.speedUnit) else {
			return nil
		}
		
		return dist / (duration / 3600)
	}
	
	var bpm: Double? {
		return getAverage(for: .heartRate)
	}
	
	init(minute: UInt, owner: Workout) {
		self.minute = minute
		self.endTime = Double(minute + 1) * 60
		
		self.owner = owner
	}
	
	private func add(_ v: Double, to: HKQuantityTypeIdentifier) {
		//Adding data to the dictionary is invoked from HKQuery callback, move to a serial queue to synchonize access
		DispatchQueue.workout.async {
			if self.data[to] == nil {
				self.data[to] = []
			}
			
			self.data[to]!.append(v)
		}
	}
	
	///Add the relevant part of the data to the minute.
	///- returns: `true` if some of the data belongs to following minutes, `false` otherwise.
	@discardableResult func add(_ data: RangedDataPoint, ofType type: HKQuantityTypeIdentifier) -> Bool {
		let val: Double?
		guard data.start != data.end else {
			let instant = InstantDataPoint(time: data.start, value: data.value)
			
			return self.add(instant, ofType: type)
		}
		
		if data.start >= startTime && data.start < endTime {
			// Start time is in range
			let frac = (min(endTime, data.end) - data.start) / data.duration
			val = data.value * frac
		} else if data.start < startTime && data.end >= startTime {
			// Point started before the range but ends in or after the range
			let frac = (min(endTime, data.end) - startTime) / data.duration
			val = data.value * frac
		} else {
			val = nil
		}
		if let val = val {
			add(val, to: type)
		}

		return data.end > endTime
	}
	
	///Add the data to the minute if it belongs to it.
	///- returns: `true` if the data belongs to following minutes, `false` otherwise.
	@discardableResult func add(_ data: InstantDataPoint, ofType type: HKQuantityTypeIdentifier) -> Bool {
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
	
	func getAverage(for type: HKQuantityTypeIdentifier) -> Double? {
		guard let raw = data[type] else {
			return nil
		}
		
		return raw.count > 0 ? raw.reduce(0) { $0 + $1 } / Double(raw.count) : nil
	}
	
	func getTotal(for type: HKQuantityTypeIdentifier) -> Double? {
		guard let raw = data[type] else {
			return nil
		}
		
		return raw.reduce(0) { $0 + $1 }
	}

}
