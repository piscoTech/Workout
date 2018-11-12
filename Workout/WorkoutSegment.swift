//
//  WorkoutSegment.swift
//  Workout
//
//  Created by Marco Boschi on 12/11/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit

class WorkoutSegment {

	/// Minute-by-minute details for the segment.
	private(set) var details: [WorkoutMinute]
	/// The amount of time the workout was paused _after_ this segment or `nil` if this is the last segment.
	let pauseTime: TimeInterval?
	
	init(start: Date, end: Date, pauseTime: TimeInterval?, withStartingMinuteCount minuteStart: UInt = 0) {
		let start = raw.startDate.timeIntervalSince1970
		let end = Int(floor( (raw.endDate.timeIntervalSince1970 - start) / 60 ))
		
		details = (0 ... end).map { WorkoutMinute(minute: UInt($0), owner: self) }
		details?.last?.endTime = endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970
		if let d = details?.last?.duration, d == 0 {
			_ = details!.popLast()
		}
	}
	
	/// Process the samples, assumed to be sorted by time, by adding them to the appropriate minutes.
	/// - returns: Samples with parts belonging to minutes _after_ this segment.
	func process(data res: [HKQuantitySample], for request: WorkoutDataQuery) -> [HKQuantitySample] {
		var searchDetail = self.details
		for s in res {
			guard s.quantity.is(compatibleWith: request.unit) else {
				continue
			}
			
			let val = s.quantity.doubleValue(for: request.unit)
			
			let start = s.startDate.timeIntervalSince1970 - self.rawStart
			let data: DataPoint
			switch request.timeType {
			case .instant:
				data = InstantDataPoint(time: start, value: val)
			case .ranged:
				let end = s.endDate.timeIntervalSince1970 - self.rawStart
				data = RangedDataPoint(start: start, end: end, value: val)
			}
			
			var hasPartsToBeAdded = true
			while let d = searchDetail.first {
				hasPartsToBeAdded = d.add(data, ofType: request.typeID)
				if hasPartsToBeAdded {
					searchDetail.remove(at: 0)
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
	
}
