//
//  WorkoutSegment.swift
//  Workout
//
//  Created by Marco Boschi on 12/11/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit
import MBLibrary

class WorkoutSegment {

	/// Start date of the segment.
	let start: Date
	/// End date of the segment.
	let end: Date
	private(set) weak var owner: Workout!
	/// Minute-by-minute details for the segment.
	private(set) var minutes: [WorkoutMinute]
	/// The amount of time the workout was paused _after_ this segment or `nil` if this is the last segment.
	let pauseTime: TimeInterval?
	
	var partCount: Int {
		return minutes.count + (pauseTime != nil ? 1 : 0)
	}
	
	init(start: Date, end: Date, pauseTime: TimeInterval?, owner: Workout, withStartingMinuteCount minuteStart: UInt = 0) {
		self.start = start
		self.end = end
		self.pauseTime = pauseTime
		self.owner = owner
		
		let s = start.timeIntervalSince1970
		let e = Int(floor( (end.timeIntervalSince1970 - s) / 60 ))
		
		minutes = (0 ... e).map { WorkoutMinute(minute: UInt($0) + minuteStart, owner: owner) }
		minutes.last?.endTime = end.timeIntervalSince1970 - s
		if let d = minutes.last?.duration, d == 0 {
			_ = minutes.popLast()
		}
	}
	
	/// Process the samples, assumed to be sorted by time, by adding them to the appropriate minutes.
	/// - returns: Samples with parts belonging to minutes _after_ this segment.
	func process(data res: [HKQuantitySample], for request: WorkoutDataQuery) -> [HKQuantitySample] {
		var searchDetail = self.minutes
		let rawStart = start.timeIntervalSince1970
		
		for s in res {
			guard s.quantity.is(compatibleWith: request.unit) else {
				continue
			}
			
			let val = s.quantity.doubleValue(for: request.unit)
			
			let start = s.startDate.timeIntervalSince1970 - rawStart
			let data: DataPoint
			switch request.timeType {
			case .instant:
				data = InstantDataPoint(time: start, value: val)
			case .ranged:
				let end = s.endDate.timeIntervalSince1970 - rawStart
				data = RangedDataPoint(start: start, end: end, value: val)
			}
			
			var hasPartsToBeAdded = true
			while let d = searchDetail.first {
				hasPartsToBeAdded = d.add(data, ofType: request.typeID)
				if hasPartsToBeAdded {
					searchDetail.remove(at: 0)
				} else {
					break
				}
			}
			
			if hasPartsToBeAdded {
				// The sample has not been fully processed but no more minutes are available, stop
				guard let sIndex = res.index(of: s) else {
					fatalError("The sample seems to not belong to the given array")
				}
				
				return Array(res[sIndex...])
			}
		}
		
		return []
	}
	
	/// Exports the minutes to CSV format.
	/// - parameter details: The details to export for each minute, non-empty with at least two details.
	/// - returns: A CSV string containing a row for each minute, each line is `\n`-terminated.
	func export(details: [WorkoutDetail]) -> String {
		precondition(details.count >= 2, "Details for the workout don't make any sense")
		
		let sep = CSVSeparator
		var res = minutes.map { d in details.map { $0.export(val: d) }.joined(separator: sep) }.joined(separator: "\n") + "\n"
		
		if let pause = pauseTime {
			res += "\(pause.getDuration().toCSV())\(sep)Pause" + [String](repeating: sep, count: details.count - 2).joined() + "\n"
		}
		
		return res
	}
	
}
