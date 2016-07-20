//
//  Workout.swift
//  Workout
//
//  Created by Marco Boschi on 20/07/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit

protocol WorkoutDelegate {
	
	func dataIsReady()
	
}

class Workout {
	
	private var raw: HKWorkout
	var delegate: WorkoutDelegate?
	
	private let requestToDo = 2
	private var requestDone = 0 {
		didSet {
			if requestDone == requestToDo {
				delegate?.dataIsReady()
			}
		}
	}
	
	private(set) var hasError = false
	private(set) var details: [WorkoutMinute]
	
	var startDate: Date {
		return raw.startDate
	}
	var endDate: Date {
		return raw.endDate
	}
	var duration: TimeInterval {
		return raw.duration
	}
	var totalDistance: Double {
		return raw.totalDistance!.doubleValue(for: .meter()) / 1000
	}
	var maxHeart: Double? = nil
	
	init(_ raw: HKWorkout, delegate del: WorkoutDelegate? = nil) {
		self.raw = raw
		self.delegate = del
		
		let start = raw.startDate.timeIntervalSince1970
		let end = Int(floor( (raw.endDate.timeIntervalSince1970 - start) / 60 ))
		
		details = []
		for m in 0 ... end {
			details.append(WorkoutMinute(minute: UInt(m)))
		}
		
		let workoutPredicate = HKQuery.predicateForObjects(from: raw)
		let timePredicate = HKQuery.predicateForSamples(withStart: raw.startDate, end: raw.endDate, options: [])
		let startDateSort = SortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
		let noLimit = Int(HKObjectQueryNoLimit)
		
		//Heart data
		let heartType = HKObjectType.quantityType(forIdentifier: .heartRate)!
		
		let hearthQuery = HKSampleQuery(sampleType: heartType, predicate: timePredicate, limit: noLimit, sortDescriptors: [startDateSort]) { (_, r, err) -> Void in
			if err != nil {
				self.hasError = true
			} else {
				var searchDetail = self.details
				
				for bpm in r as! [HKQuantitySample] {
					let val = bpm.quantity.doubleValue(for: .heartRateUnit())
					self.maxHeart = max(self.maxHeart ?? 0, val)
					let data = DataPoint(time: bpm.startDate.timeIntervalSince1970 - start, value: val)
					
					while let d = searchDetail.first where d.add(heartRate: data) {
						searchDetail.remove(at: 0)
					}
				}
			}
			
			self.requestDone += 1
		}
		
		//Distance data
		let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
		
		let distanceQuery = HKSampleQuery(sampleType: distanceType, predicate: workoutPredicate, limit: noLimit, sortDescriptors: [startDateSort]) { (_, r, err) in
			if err != nil {
				self.hasError = true
			} else {
				var searchDetail = self.details
				
				for dist in r as! [HKQuantitySample] {
					let val = dist.quantity.doubleValue(for: .meter()) / 1000
					let data = RangedDataPoint(start: dist.startDate.timeIntervalSince1970 - start, end: dist.endDate.timeIntervalSince1970 - start, value: val)
					
					while let d = searchDetail.first where d.add(distance: data) {
						searchDetail.remove(at: 0)
					}
				}
			}

			self.requestDone += 1
		}
		
		healthStore.execute(hearthQuery)
		healthStore.execute(distanceQuery)
	}
	
}
