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
			return "\(minute)m\(dur): " + (distance?.getFormattedDistance() ?? "- km") + ", " + (bpm?.getFormattedHeartRate() ?? "- bpm")
		}
	}
	
	private var data = [HKQuantityType: [Double]]()
	
	var distance: Double? {
		var res = getTotal(for: HKQuantityTypeIdentifier.distanceWalkingRunning.getType()!)
		
		if #available(iOS 10, *) {
			res = res ?? getTotal(for: HKQuantityTypeIdentifier.distanceSwimming.getType()!)
		}
		
		return res
	}
	///Avarage pace of the minute in seconds per kilometer.
	var pace: TimeInterval? {
		if let d = distance {
			let p  = duration / d
			return p < 20 * 60 ? p : nil
		} else {
			return nil
		}
	}
	///Avarage speed of the minute in kilometer per hour.
	var speed: Double? {
		guard let dist = distance else {
			return nil
		}
		
		return dist / (duration / 3600)
	}
	
	var bpm: Double? {
		return getAverage(for: HKQuantityTypeIdentifier.heartRate.getType()!)
	}
	
	init(minute: UInt) {
		self.minute = minute
		self.endTime = Double(minute + 1) * 60
	}
	
	private func processRangedData(data: RangedDataPoint) -> (valFrac: Double, res: Bool) {
		let val: Double
		if data.start >= startTime && data.start < endTime {
			// Start time is in range
			let frac = (min(endTime, data.end) - data.start) / data.duration
			val = data.value * frac
		} else if data.start < startTime && data.end >= startTime {
			// Point started before the range but ends in or after the range
			let frac = (min(endTime, data.end) - startTime) / data.duration
			val = data.value * frac
		} else {
			val = 0
		}
		
		return (val, data.end > endTime)
	}
	
	private func add(_ v: Double, to: HKQuantityType) {
		if data[to] == nil {
			data[to] = []
		}
		
		data[to]!.append(v)
	}
	
	///Add the relevant part of the data to the minute.
	///- returns: `true` if some of the data belongs to following minutes, `false` otherwise.
	@discardableResult func add(_ data: RangedDataPoint, ofType type: HKQuantityType) -> Bool {
		let (val, res) = processRangedData(data: data)
		add(val, to: type)

		return res
	}
	
	///Add the data to the minute if it belongs to it.
	///- returns: `true` if the data belongs to following minutes, `false` otherwise.
	@discardableResult func add(_ data: InstantDataPoint, ofType type: HKQuantityType) -> Bool {
		if data.time >= startTime && data.time < endTime {
			add(data.value, to: type)
		}
		
		return data.time >= endTime
	}
	
	///Add the data or its relevant part to the minute if it belongs to it.
	///- returns: `true` if the data belongs to following minutes, `false` otherwise.
	@discardableResult func add(_ data: DataPoint, ofType type: HKQuantityType) -> Bool {
		switch data {
		case let i as InstantDataPoint:
			return add(i, ofType: type)
		case let r as RangedDataPoint:
			return add(r, ofType: type)
		default:
			fatalError("Unknown data point type")
		}
	}
	
	func getAverage(for type: HKQuantityType) -> Double? {
		guard let raw = data[type] else {
			return nil
		}
		
		return raw.count > 0 ? raw.reduce(0) { $0 + $1 } / Double(raw.count) : nil
	}
	
	func getTotal(for type: HKQuantityType) -> Double? {
		guard let raw = data[type] else {
			return nil
		}
		
		return raw.reduce(0) { $0 + $1 }
	}

}
