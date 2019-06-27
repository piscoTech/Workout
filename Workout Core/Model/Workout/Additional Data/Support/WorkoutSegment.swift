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
		let e = UInt(floor( (end.timeIntervalSince1970 - s) / 60 ))

		minutes = (0 ... e).map { WorkoutMinute(minute: $0 + minuteStart, start: $0, owner: owner) }
		minutes.last?.endTime = end.timeIntervalSince1970 - s
		if let d = minutes.last?.duration, d <= 0 {
			_ = minutes.popLast()
		}
	}

	/// Process the samples, assumed to be sorted by time, by adding them to the appropriate minutes.
	/// - returns: Samples with parts belonging to minutes _after_ this segment.
	func process(data res: [HKQuantitySample], for request: WorkoutDataQuery) -> [HKQuantitySample] {
		let rawStart = start.timeIntervalSince1970

		var processFurther: [HKQuantitySample] = []
		var searchDetail = self.minutes.map { m -> WorkoutMinute in
			m.set(unit: request.unit, for: request.typeID)
			return m
		}
		var previous: HKQuantitySample?
		for s in res {
			guard s.quantity.is(compatibleWith: request.unit) else {
				continue
			}

			defer {
				previous = s
			}
			// If the previosly processed sample had an end date after the start of the current one we must start searching again
			if let prev = previous, prev.endDate > s.startDate {
				searchDetail = self.minutes
			}

			let start = s.startDate.timeIntervalSince1970 - rawStart
			let data: DataPoint
			switch request.timeType {
			case .instant:
				data = InstantDataPoint(time: start, value: s.quantity)
			case .ranged:
				let end = s.endDate.timeIntervalSince1970 == TimeInterval.infinity ? start : s.endDate.timeIntervalSince1970 - rawStart
				data = RangedDataPoint(start: start, end: end, value: s.quantity)
			}

			// Add the sample to as many minutes as needed
			while let d = searchDetail.first, d.add(data, ofType: request.typeID) {
				searchDetail.remove(at: 0)
			}

			if searchDetail.isEmpty {
				// The sample has not been fully processed but no more minutes are available
				processFurther.append(s)
			}
		}
		
		return processFurther
	}

	/// Exports the minutes to CSV format.
	/// - parameter details: The details to export for each minute, non-empty with at least two details.
	/// - returns: A CSV string containing a row for each minute, each line is `\n`-terminated.
	func export(details: [WorkoutDetail]) -> String {
		#warning("Add back")
		return ""
		//		precondition(details.count >= 2, "Details for the workout don't make any sense")
		//
		//		let sep = CSVSeparator
		//		var res = minutes.map { d in details.map { $0.export(val: d) }.joined(separator: sep) }.joined(separator: "\n") + "\n"
		//
		//		if let pause = pauseTime {
		//			res += "\(pause.getDuration().toCSV())\(sep)Pause" + [String](repeating: sep, count: details.count - 2).joined() + "\n"
		//		}
		//
		//		return res
	}

}
