//
//  Workout.swift
//  Workout
//
//  Created by Marco Boschi on 20/07/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit
import MBLibrary

protocol WorkoutDelegate {
	
	func dataIsReady()
	
}

class Workout {
	
	private var raw: HKWorkout
	var delegate: WorkoutDelegate?
	
	private let requestToDo = 3
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
	var avgHeart: Double? {
		return heartData.count > 0 ? heartData.reduce(0) { $0 + $1 } / Double(heartData.count) : nil
	}
	var pace: TimeInterval {
		return duration / totalDistance
	}
	
	private var heartData = [Double]()
	
	init(_ raw: HKWorkout, delegate del: WorkoutDelegate? = nil) {
		self.raw = raw
		self.delegate = del
		details = []
		
		guard HKHealthStore.isHealthDataAvailable() else {
			hasError = true
			delegate?.dataIsReady()
			
			return
		}
		
		let start = raw.startDate.timeIntervalSince1970
		let end = Int(floor( (raw.endDate.timeIntervalSince1970 - start) / 60 ))
		
		for m in 0 ... end {
			details.append(WorkoutMinute(minute: UInt(m)))
		}
		details.last?.endTime = endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970
		if let d = details.last?.duration, d == 0 {
			_ = details.popLast()
		}
		
		let workoutPredicate = HKQuery.predicateForObjects(from: raw)
		let timePredicate = NSPredicate(format: "%K >= %@ AND %K < %@", HKPredicateKeyPathEndDate, raw.startDate as NSDate, HKPredicateKeyPathStartDate, raw.endDate as NSDate)
		let startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
		let noLimit = Int(HKObjectQueryNoLimit)
		
		//Heart data per minute
		let heartType = HKObjectType.quantityType(forIdentifier: .heartRate)!
		
		let hearthQuery = HKSampleQuery(sampleType: heartType, predicate: timePredicate, limit: noLimit, sortDescriptors: [startDateSort]) { (_, r, err) -> Void in
			if err != nil {
				self.hasError = true
			} else {
				var searchDetail = self.details
				
				for bpm in r as! [HKQuantitySample] {
					let val = bpm.quantity.doubleValue(for: .heartRate())
					self.maxHeart = max(self.maxHeart ?? 0, val)
					self.heartData.append(val)
					let data = DataPoint(time: bpm.startDate.timeIntervalSince1970 - start, value: val)
					
					while let d = searchDetail.first, d.add(heartRate: data) {
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
					
					while let d = searchDetail.first, d.add(distance: data) {
						searchDetail.remove(at: 0)
					}
				}
			}

			self.requestDone += 1
		}
		
		//Step data
		let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
		
		let stepQuery = HKSampleQuery(sampleType: stepType, predicate: timePredicate, limit: noLimit, sortDescriptors: [startDateSort]) { (_, r, err) in
			if err != nil {
				self.hasError = true
			} else {
				var searchDetail = self.details
				
				for step in r as! [HKQuantitySample] {
					if step.sourceRevision.source.name.range(of: stepSourceFilter) == nil {
						continue
					}
					
					let val = step.quantity.doubleValue(for: .steps())
					let data = RangedDataPoint(start: step.startDate.timeIntervalSince1970 - start, end: step.endDate.timeIntervalSince1970 - start, value: val)
					
					while let d = searchDetail.first, d.add(steps: data) {
						searchDetail.remove(at: 0)
					}
				}
			}
			
			self.requestDone += 1
		}
		
		healthStore.execute(hearthQuery)
		healthStore.execute(distanceQuery)
		healthStore.execute(stepQuery)
	}
	
	private var generalData: [String] {
		return [startDate.getUNIXDateTime().toCSV(), endDate.getUNIXDateTime().toCSV(), duration.getDuration().toCSV(), totalDistance.toCSV(), avgHeart?.toCSV() ?? "", maxHeart?.toCSV() ?? "", pace.getDuration().toCSV()]
	}
	
	func exportGeneralData() -> String {
		return generalData.joined(separator: CSVSeparator)
	}
	
	func export() -> [URL]? {
		var filePath = NSString(string: NSTemporaryDirectory()).appendingPathComponent("generalData.csv")
		let generalDataPath = URL(fileURLWithPath: filePath)
		filePath = NSString(string: NSTemporaryDirectory()).appendingPathComponent("details.csv")
		let detailsPath = URL(fileURLWithPath: filePath)
		
		let genData = generalData
		var gen = "Field\(CSVSeparator)Value\n"
		gen += "Start\(CSVSeparator)" + genData[0] + "\n"
		gen += "End\(CSVSeparator)" + genData[1] + "\n"
		gen += "Duration\(CSVSeparator)" + genData[2] + "\n"
		gen += "Distance\(CSVSeparator)" + genData[3] + "\n"
		gen += "\("Average Heart Rate".toCSV())\(CSVSeparator)" + genData[4] + "\n"
		gen += "\("Max Heart Rate".toCSV())\(CSVSeparator)" + genData[5] + "\n"
		gen += "\("Average Pace".toCSV())\(CSVSeparator)" + genData[6] + "\n"
		
		var det = "Time\(CSVSeparator)Pace\(CSVSeparator)\("Heart Rate".toCSV())\(CSVSeparator)Steps\n"
		for d in details {
			det += d.startTime.getDuration().toCSV() + CSVSeparator
			det += (d.pace?.getDuration().toCSV() ?? "") + CSVSeparator
			det += (d.bpm?.toCSV() ?? "") + CSVSeparator
			det += d.steps?.toCSV() ?? ""
			det += "\n"
		}
		
		do {
			try gen.write(to: generalDataPath, atomically: true, encoding: .utf8)
			try det.write(to: detailsPath, atomically: true, encoding: .utf8)
		} catch _ {
			return nil
		}
		
		return [generalDataPath, detailsPath]
	}
	
}
