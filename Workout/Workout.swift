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
	
	///Minute-by-minute details for the workout.
	private(set) var details: [WorkoutMinute]?
	///Specify how details should be displayed and in which order, time detail will be automaticall prepended.
	private(set) var displayDetail: [WorkoutDetail]?
	
	var type: HKWorkoutActivityType {
		return raw.workoutActivityType
	}
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
	
	private var rawStart: TimeInterval {
		return raw.startDate.timeIntervalSince1970
	}
	private let workoutPredicate: NSPredicate!
	private let timePredicate: NSPredicate!
	private let startDateSort: NSSortDescriptor!
	private let queryNoLimit = HKObjectQueryNoLimit
	
	enum SearchType {
		case time, workout
	}
	
	class func workoutFor(raw: HKWorkout, delegate: WorkoutDelegate? = nil) -> Workout {
		let wClass: Workout.Type
		
		switch raw.workoutActivityType {
		case .running:
			wClass = RunninWorkout.self
		case .swimming:
			wClass = SwimmingWorkout.self
		default:
			wClass = Workout.self
		}
		
		return wClass.init(raw, delegate: delegate)
	}
	
	required init(_ raw: HKWorkout, delegate del: WorkoutDelegate? = nil) {
		self.raw = raw
		self.delegate = del
		
		guard HKHealthStore.isHealthDataAvailable() else {
			hasError = true
			workoutPredicate = nil
			timePredicate = nil
			startDateSort = nil
			delegate?.dataIsReady()
			
			return
		}
		
		workoutPredicate = HKQuery.predicateForObjects(from: raw)
		timePredicate = NSPredicate(format: "%K >= %@ AND %K < %@", HKPredicateKeyPathEndDate, raw.startDate as NSDate, HKPredicateKeyPathStartDate, raw.endDate as NSDate)
		startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
		
		addRequest(for: .heartRate, withUnit: .heartRate(), andTimeType: .instant, searchingBy: .time)
	}
	
	func addDetails(_ display: [WorkoutDetail]) {
		guard details == nil && !loading && !loaded else {
			return
		}
		
		details = []
		displayDetail = display
		
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
	
	func addRequest(for typeID: HKQuantityTypeIdentifier, withUnit unit: HKUnit, andTimeType tType: DataPointType, searchingBy pred: SearchType) {
		guard !loading && !loaded else {
			return
		}
		
		guard let type = typeID.getType() else {
			return
		}
		
		let rawStart = self.rawStart
		let predicate = pred == .time ? timePredicate : workoutPredicate
		let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: queryNoLimit, sortDescriptors: [startDateSort]) { (_, r, err) -> Void in
			if err != nil {
				self.hasError = true
			} else {
				var searchDetail = self.details
			
				let stepSource = stepSourceFilter
				for s in r as! [HKQuantitySample] {
					guard s.quantity.is(compatibleWith: unit) else {
						continue
					}
					
					if typeID == .stepCount && !stepSource.sourceMatch(s) {
						continue
					}
					
					let val = s.quantity.doubleValue(for: unit)
					
					if typeID == .heartRate {
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
					
					while let d = searchDetail?.first, d.add(data, ofType: typeID) {
						searchDetail?.remove(at: 0)
					}
				}
			}
			
			//Move to a serial queue to synchronize access to counter
			DispatchQueue.workout.async {
				self.requestDone += 1
			}
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
		return [type.name.toCSV(), startDate.getUNIXDateTime().toCSV(), endDate.getUNIXDateTime().toCSV(), duration.getDuration().toCSV(), totalDistance?.toCSV() ?? "", avgHeart?.toCSV() ?? "", maxHeart?.toCSV() ?? "", pace?.getDuration().toCSV() ?? "", speed?.toCSV() ?? ""]
	}
	
	func exportGeneralData() -> String {
		return generalData.joined(separator: CSVSeparator)
	}
	
	func export() -> [URL]? {
		var res = [URL]()
		var data = [String]()
		
		var filePath = NSString(string: NSTemporaryDirectory()).appendingPathComponent("generalData.csv")
		res.append(URL(fileURLWithPath: filePath))
		
		let genData = generalData
		let sep = CSVSeparator
		var gen = "Field\(sep)Value\n"
		gen += "Type\(sep)" + genData[0] + "\n"
		gen += "Start\(sep)" + genData[1] + "\n"
		gen += "End\(sep)" + genData[2] + "\n"
		gen += "Duration\(sep)" + genData[3] + "\n"
		gen += "Distance\(sep)" + genData[4] + "\n"
		gen += "\("Average Heart Rate".toCSV())\(sep)" + genData[5] + "\n"
		gen += "\("Max Heart Rate".toCSV())\(sep)" + genData[6] + "\n"
		gen += "\("Average Pace".toCSV())\(sep)" + genData[7] + "\n"
		gen += "\("Average Speed".toCSV())\(sep)" + genData[8] + "\n"
		data.append(gen)
		
		if let details = self.details {
			filePath = NSString(string: NSTemporaryDirectory()).appendingPathComponent("details.csv")
			res.append(URL(fileURLWithPath: filePath))
			
			let export = [WorkoutDetail.time] + self.displayDetail!
			var det = export.map { $0.name.toCSV() }.joined(separator: sep) + "\n"
			for d in details {
				det += export.map { $0.export(val: d) }.joined(separator: sep) + "\n"
			}
			
			data.append(det)
		}
		
		do {
			for (f, d) in zip(res, data) {
				try d.write(to: f, atomically: true, encoding: .utf8)
			}
		} catch _ {
			return nil
		}
		
		return res
	}
	
}
