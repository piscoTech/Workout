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
	
	private(set) var raw: HKWorkout
	var delegate: WorkoutDelegate?
	
	/// Request required for base data for a quick load.
	private var baseReq = [WorkoutDataQuery]()
	/// Request for additional details and a full load.
	private var requests = [WorkoutDataQuery]()
	//Set when .load() is called
	private var requestToDo = 0
	private var requestDone = 0 {
		didSet {
			if requestDone == requestToDo {
				loading = false
				loaded = true
				delegate?.dataIsReady()
			}
		}
	}
	
	private var additionalProcessors = [AdditionalDataProcessor]()
	private(set) var additionalProviders = [AdditionalDataProvider]()
	
	private var loading = false
	private(set) var loaded = false
	private(set) var hasError = false

	/// The length unit to represent the distance.
	private(set) var distanceUnit = WorkoutUnit.kilometerAndMile
	/// The length unit to use in calculating pace.
	private(set) var paceUnit = WorkoutUnit.kilometerAndMile
	/// The length unit to use in calculating speed.
	private(set) var speedUnit = WorkoutUnit.kilometerAndMile

	/// Max acceptable pace, if any, in time per kilometer.
	private(set) var maxPace: TimeInterval?
	
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
		let distance = raw.totalDistance?.doubleValue(for: distanceUnit.unit)
		
		// Don't expose a 0 distance, give nil instead
		return distance ?? 0 > 0 ? distance : nil
	}
	var maxHeart: Double? = nil
	var avgHeart: Double? {
		return heartData.count > 0 ? heartData.reduce(0) { $0 + $1 } / Double(heartData.count) : nil
	}
	///Average pace of the workout in seconds per `paceUnit`.
	var pace: TimeInterval? {
		let pUnit = paceUnit.unit
		guard let dist = raw.totalDistance?.doubleValue(for: pUnit), dist > 0 else {
			return nil
		}
		
		return (duration / dist).filterAsPace(withLengthUnit: pUnit, andMaxPace: maxPace)
	}
	///Average speed of the workout in `speedUnit` per hour.
	var speed: Double? {
		guard let dist = raw.totalDistance?.doubleValue(for: speedUnit.unit), dist > 0 else {
			return nil
		}
		
		return dist / (duration / 3600)
	}
	///Total energy burned in kilocalories.
	var totalCalories: Double? {
		return rawTotalCalories ?? rawActiveCalories
	}
	///Active energy burned in kilocalories.
	var activeCalories: Double? {
		return rawTotalCalories != nil ? rawActiveCalories : nil
	}
	
	private var activeCaloriesData = 0.0
	private var restingCaloriesData = 0.0
	
	private var rawTotalCalories: Double? {
		let total = (rawActiveCalories ?? 0) + restingCaloriesData
		return total > 0 ? total : nil
	}
	private var rawActiveCalories: Double? {
		if activeCaloriesData > 0 {
			return activeCaloriesData
		} else if let total = raw.totalEnergyBurned?.doubleValue(for: WorkoutUnit.calories.unit), total > 0 {
			return total
		} else {
			return nil
		}
	}
	
	
	private var heartData = [Double]()
	
	private var rawStart: TimeInterval {
		return raw.startDate.timeIntervalSince1970
	}
	private let workoutPredicate: NSPredicate!
	private let timePredicate: NSPredicate!
	private let sourcePredicate: NSPredicate!
	
	/// Create an instance of the proper `Workout` subclass (if any) for the given workout.
	class func workoutFor(raw: HKWorkout, delegate: WorkoutDelegate? = nil) -> Workout {
		let wClass: Workout.Type
		
		switch raw.workoutActivityType {
		case .running, .walking:
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
			sourcePredicate = nil
			delegate?.dataIsReady()
			
			return
		}
		
		workoutPredicate = HKQuery.predicateForObjects(from: raw)
		timePredicate = NSPredicate(format: "%K >= %@ AND %K < %@", HKPredicateKeyPathEndDate, raw.startDate as NSDate, HKPredicateKeyPathStartDate, raw.endDate as NSDate)
		sourcePredicate = HKQuery.predicateForObjects(from: raw.sourceRevision.source)
		
		if let heart = WorkoutDataQuery(typeID: .heartRate, withUnit: .heartRate, andTimeType: .instant, searchingBy: .time) {
			self.addQuery(heart, isBase: true)
		}
		if let activeCal = WorkoutDataQuery(typeID: .activeEnergyBurned, withUnit: .calories, andTimeType: .ranged, searchingBy: .workout(fallbackToTime: true)) {
			self.addQuery(activeCal, isBase: true)
		}
		if let baseCal = WorkoutDataQuery(typeID: .basalEnergyBurned, withUnit: .calories, andTimeType: .ranged, searchingBy: .time) {
			self.addQuery(baseCal, isBase: true)
		}
	}
	
	func setLengthUnitsFor(distance dUnit: WorkoutUnit, speed sUnit: WorkoutUnit, pace pUnit: WorkoutUnit) {
		guard !loading && !loaded else {
			return
		}

		distanceUnit = dUnit
		speedUnit = sUnit
		paceUnit = pUnit
	}

	/// Sets the max acceptable pace, if any, in time per kilometer.
	func set(maxPace: TimeInterval?) {
		guard !loading && !loaded else {
			return
		}

		self.maxPace = maxPace ?? 0 > 0 ? maxPace : nil
	}
	
	// MARK: - Set and load other data
	
	/// Add a query to load data for the workout.
	/// - parameter isBase: Whether to execute the resulting query even if doing a quick load. This needs to be set to `true` when the data is part of `exportGeneralData()`.
	private func addQuery(_ q: WorkoutDataQuery, isBase: Bool) {
		guard !loading && !loaded else {
			return
		}
		
		if isBase {
			baseReq.append(q)
		} else {
			requests.append(q)
		}
	}
	
	/// Add a query to load data for the workout.
	func addQuery(_ q: WorkoutDataQuery) {
		self.addQuery(q, isBase: false)
	}
	
	func addAdditionalDataProcessors(_ dp: AdditionalDataProcessor...) {
		guard !loading && !loaded else {
			return
		}
		
		self.additionalProcessors += dp
	}
	
	func addAdditionalDataProviders(_ dp: AdditionalDataProvider...) {
		guard !loading && !loaded else {
			return
		}
		
		self.additionalProviders += dp
	}
	
	func addAdditionalDataProcessorsAndProviders(_ dp: (AdditionalDataProcessor & AdditionalDataProvider)...) {
		guard !loading && !loaded else {
			return
		}
		
		self.additionalProcessors += dp as [AdditionalDataProcessor]
		self.additionalProviders += dp as [AdditionalDataProvider]
	}
	
	/// Loads required additional data for the workout.
	/// - parameter quickLoad: If enabled only base queries, i.e. heart data and calories, will be executed and not custom ones defined by specific workouts.
	func load(quickLoad: Bool = false) {
		guard !loading && !loaded else {
			return
		}
		
		for dp in additionalProcessors {
			dp.set(workout: self)
		}
		
		loading = true
		let req = baseReq + (quickLoad ? [] : requests)
		requestToDo = req.count
		for r in req {
			r.execute(forStart: startDate, usingWorkoutPredicate: workoutPredicate, timePredicate: timePredicate, sourcePredicate: sourcePredicate) { _, data, err  in
				defer {
					// Move to a serial queue to synchronize access to counter
					DispatchQueue.workout.async {
						self.requestDone += 1
					}
				}
				
				guard err == nil, let res = data as? [HKQuantitySample] else {
					self.hasError = true
					return
				}
				
				for dp in self.additionalProcessors {
					if dp.wantData(for: r.typeID) {
						dp.process(data: res, for: r)
					}
				}
				
				if [HKQuantityTypeIdentifier.heartRate, .activeEnergyBurned, .basalEnergyBurned].contains(r.typeID) {
					for s in res {
						guard s.quantity.is(compatibleWith: r.unit) else {
							continue
						}
						
						let val = s.quantity.doubleValue(for: r.unit.unit)
						
						switch r.typeID {
						case .heartRate:
							self.maxHeart = max(self.maxHeart ?? 0, val)
							self.heartData.append(val)
						case .activeEnergyBurned:
							self.activeCaloriesData += val
						case .basalEnergyBurned:
							self.restingCaloriesData += val
						default:
							break
						}
					}
				}
			}
		}
	}
	
	// MARK: - Export
	
	private var generalData: [String] {
		return [
			type.name.toCSV(),
			startDate.getUNIXDateTime().toCSV(),
			endDate.getUNIXDateTime().toCSV(),
			duration.getDuration().toCSV(),
			totalDistance?.toCSV() ?? "",
			avgHeart?.toCSV() ?? "",
			maxHeart?.toCSV() ?? "",
			pace?.getDuration().toCSV() ?? "",
			speed?.toCSV() ?? "",
			activeCalories?.toCSV() ?? "",
			totalCalories?.toCSV() ?? ""
		]
	}
	
	func exportGeneralData() -> String {
		return generalData.joined(separator: CSVSeparator)
	}
	
	func export() -> [URL]? {
		let general = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("generalData.csv")
		var res = [general]
		
		let genData = generalData
		let sep = CSVSeparator
		var data = "Field\(sep)Value\n"
		data += "Type\(sep)" + genData[0] + "\n"
		data += "Start\(sep)" + genData[1] + "\n"
		data += "End\(sep)" + genData[2] + "\n"
		data += "Duration\(sep)" + genData[3] + "\n"
		data += "\("Distance \(distanceUnit.description)".toCSV())\(sep)" + genData[4] + "\n"
		data += "\("Average Heart Rate".toCSV())\(sep)" + genData[5] + "\n"
		data += "\("Max Heart Rate".toCSV())\(sep)" + genData[6] + "\n"
		data += "\("Average Pace time/\(paceUnit.description)".toCSV())\(sep)" + genData[7] + "\n"
		data += "\("Average Speed \(speedUnit.description)/h".toCSV())\(sep)" + genData[8] + "\n"
		data += "\("Active Energy kcal".toCSV())\(sep)" + genData[9] + "\n"
		data += "\("Total Energy kcal".toCSV())\(sep)" + genData[10] + "\n"
		
		do {
			try data.write(to: general, atomically: true, encoding: .utf8)
		} catch _ {
			return nil
		}
		
		for dp in additionalProviders {
			guard let files = dp.export() else {
				return nil
			}
			
			res += files
		}
		
		return res
	}
	
}
