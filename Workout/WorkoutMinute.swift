//
//  WorkoutMinute.swift
//  Workout
//
//  Created by Marco Boschi on 20/07/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

///Describe workout data in time range `startTime ..< endTime`.
class WorkoutMinute: CustomStringConvertible {
	
	var minute: UInt
	var startTime: TimeInterval {
		return Double(minute) * 60
	}
	var endTime: TimeInterval {
		didSet {
			precondition(duration > 0 && duration <= 60, "Invalid endTime")
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
	
	private(set) var distance: Double?
	var pace: TimeInterval? {
		if let d = distance {
			let p  = duration / d
			return p < 20 * 60 ? p : nil
		} else {
			return nil
		}
	}
	var bpm: Double? {
		return rawBpm.count > 0 ? rawBpm.reduce(0) { $0 + $1 } / Double(rawBpm.count) : nil
	}
	private(set) var steps: Double?
	
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
	
	///Add the relevant part of distance to the minute.
	///- returns: `true` if some of the distance belongs to following minutes, `false` otherwise.
	@discardableResult func add(distance: RangedDataPoint) -> Bool {
		let (val, res) = processRangedData(data: distance)
		self.distance = (self.distance ?? 0) + val
		
		return res
	}
	
	private var rawBpm = [Double]()
	
	///Add the heart rate to the minute if it belongs to it.
	///- returns: `true` if the heart rate belongs to following minutes, `false` otherwise.
	@discardableResult func add(heartRate bpm: DataPoint) -> Bool {
		if bpm.time >= startTime && bpm.time < endTime {
			rawBpm.append(bpm.value)
		}
		
		return bpm.time >= endTime
	}
	
	///Add the relevant part of step count to the minute.
	///- returns: `true` if some of the steps belongs to following minutes, `false` otherwise.
	@discardableResult func add(steps: RangedDataPoint) -> Bool {
		let (val, res) = processRangedData(data: steps)
		self.steps = (self.steps ?? 0) + val
		
		return res
	}

}
