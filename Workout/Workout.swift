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
	
	private var requests = [HKQuery]()
	private var requestToDo: Int {
		return requests.count
	}
	private var requestDone = 0 {
		didSet {
			if requestDone == requestToDo {
				loading = false
				loaded = true
				delegate?.dataIsReady()
			}
		}
	}
	
	private var loading = false
	private(set) var loaded = false
	private(set) var hasError = false
	private(set) var details: [WorkoutMinute]?
	
	var startDate: Date {
		return raw.startDate
	}
	var endDate: Date {
		return raw.endDate
	}
	var duration: TimeInterval {
		return raw.duration
	}
	var totalDistance: Double? {
		return raw.totalDistance?.doubleValue(for: .kilometer())
	}
	var maxHeart: Double? = nil
	var avgHeart: Double? {
		return heartData.count > 0 ? heartData.reduce(0) { $0 + $1 } / Double(heartData.count) : nil
	}
	///Avarage pace of the workout in seconds per kilometer.
	var pace: TimeInterval? {
		guard let dist = totalDistance else {
			return nil
		}
		
		return duration / dist
	}
	///Avarage speed of the workout in kilometer per hour.
	var speed: Double? {
		guard let dist = totalDistance else {
			return nil
		}
		
		return dist / (duration / 3600)
	}
	
	private var heartData = [Double]()
	
	private let heartType = HKQuantityTypeIdentifier.heartRate.getType()!
	private let stepType = HKQuantityTypeIdentifier.stepCount.getType()!
	private var rawStart: TimeInterval {
		return raw.startDate.timeIntervalSince1970
	}
	private let workoutPredicate: NSPredicate
	private let timePredicate: NSPredicate
	private let startDateSort: NSSortDescriptor
	private let queryNoLimit = Int(HKObjectQueryNoLimit)
	
	enum SearchType {
		case time, workout
	}
	
	class func workoutFor(raw: HKWorkout, delegate: WorkoutDelegate? = nil) -> Workout {
		switch raw.workoutActivityType {
		case .running:
			return RunninWorkout(raw, delegate: delegate)
		case .swimming:
			return SwimmingWorkout(raw, delegate: delegate)
		default:
			return Workout(raw, delegate: delegate)
		}
	}
	
	init(_ raw: HKWorkout, delegate del: WorkoutDelegate? = nil) {
		self.raw = raw
		self.delegate = del
		details = []
		
		guard HKHealthStore.isHealthDataAvailable() else {
			hasError = true
			delegate?.dataIsReady()
			
			return
		}
		
		workoutPredicate = HKQuery.predicateForObjects(from: raw)
		timePredicate = NSPredicate(format: "%K >= %@ AND %K < %@", HKPredicateKeyPathEndDate, raw.startDate as NSDate, HKPredicateKeyPathStartDate, raw.endDate as NSDate)
		startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
		
		addRequest(for: heartType, withUnit: .heartRate(), andTimeType: .instant, searchingBy: .time)
	}
	
	func addDetails() {
		guard details == nil && !loading && !loaded else {
			return
		}
		
		details = []
		
		let start = raw.startDate.timeIntervalSince1970
		let end = Int(floor( (raw.endDate.timeIntervalSince1970 - start) / 60 ))
		
		for m in 0 ... end {
			details!.append(WorkoutMinute(minute: UInt(m)))
		}
		details!.last?.endTime = endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970
		if let d = details!.last?.duration, d == 0 {
			_ = details!.popLast()
		}
	}
	
	func addRequest(for type: HKQuantityType, withUnit unit: HKUnit, andTimeType tType: DataPointType, searchingBy pred: SearchType) {
		guard !loading && !loaded else {
			return
		}
		
		let rawStart = self.rawStart
		let predicate = pred == .time ? timePredicate : workoutPredicate
		let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: queryNoLimit, sortDescriptors: [startDateSort]) { (_, r, err) -> Void in
			if err != nil {
				self.hasError = true
			} else {
				var searchDetail = self.details
				
				for s in r as! [HKQuantitySample] {
					guard s.quantity.is(compatibleWith: unit) else {
						continue
					}
					
					if type == self.stepType && s.sourceRevision.source.name.range(of: stepSourceFilter) == nil {
						continue
					}
					
					let val = s.quantity.doubleValue(for: unit)
					
					if type == self.heartType {
						self.maxHeart = max(self.maxHeart ?? 0, val)
						self.heartData.append(val)
					}
					
					let start = s.startDate.timeIntervalSince1970 - rawStart
					let data: DataPoint
					switch tType {
					case .instant:
						data = InstantDataPoint(time: start, value: val)
					case .ranged:
						let end = s.endDate.timeIntervalSince1970 - rawStart
						data = RangedDataPoint(start: start, end: end, value: val)
					}
					
					while let d = searchDetail?.first, d.add(data, ofType: type) {
						searchDetail?.remove(at: 0)
					}
				}
			}
			
			self.requestDone += 1
		}
		
		requests.append(query)
	}
	
	func load() {
		guard !loading && !loaded else {
			return
		}
		
		loading = true
		for r in requests {
			healthStore.execute(r)
		}
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
