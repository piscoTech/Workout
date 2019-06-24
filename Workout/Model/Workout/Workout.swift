//
//  Workout.swift
//  Workout
//
//  Created by Marco Boschi on 20/07/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import HealthKit
import Combine
import SwiftUI
import MBLibrary

class Workout: BindableObject {

	private let healthStore: HKHealthStore
	let raw: HKWorkout

	#warning("Use receive(on:) (Xcode bug)")
	let didChange = PassthroughSubject<Void, Never>() //.receive(on: RunLoop.main)

	/// Request required for base data for a quick load.
	private var baseReq = [WorkoutDataQuery]()
	/// Request for additional details and a full load.
	private var requests = [WorkoutDataQuery]()

	private var cancellables = [Cancellable]()

	//Set when .load() is called
	private var requestToDo = 0
	private var requestDone = 0 {
		didSet {
			if requestDone == requestToDo, requestToDo > 0 {
				loadedFully = loadingFully
				loadingFully = nil
				requestToDo = 0
				requestDone = 0

				#warning("Force receive on main thread until receive(on:) is not available (Xcode bug)")
				DispatchQueue.main.async {
					self.didChange.send(())
				}
			}
		}
	}

	private var additionalProcessors = [AdditionalDataProcessor]()
	private(set) var additionalProviders = [AdditionalDataProvider]()

	var isLoading: Bool {
		loadingFully != nil
	}
	/// The loading status. A non-`nil` value represents loading and `true` that the loading is full.
	private var loadingFully: Bool? = nil

	var loaded: Bool {
		loadedFully != nil
	}
	var fullyLoaded: Bool {
		loadedFully == true
	}
	/// The loaded status. A non-`nil` value represents that the workout has been loaded and `true` that it has been fully loaded.
	private var loadedFully: Bool? = nil

	private(set) var hasError = false

	/// The unit to represent distances.
	private(set) var distanceUnit = WorkoutUnit.kilometerAndMile
	/// The length unit to represent paces, time will be added automatically.
	private(set) var paceUnit = WorkoutUnit.kilometerAndMile
	/// The unit to represent speeds.
	private(set) var speedUnit = WorkoutUnit.kilometerAndMilePerHour

	/// Max acceptable pace, if any, in time per unit length.
	private(set) var maxPace: HKQuantity?

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
	/// The total distance of the workout, see `distanceUnit` for the desired unit for presentation.
	var totalDistance: HKQuantity? {
		// Don't expose a 0 distance, give nil instead
		if let dist = raw.totalDistance, dist > HKQuantity(unit: .meter(), doubleValue: 0) {
			return dist
		} else {
			return nil
		}
	}
	private(set) var maxHeart: HKQuantity? = nil
	private(set) var avgHeart: HKQuantity?
	/// Average pace of the workout in time per unit length, see `paceUnit` for the desired unit for presentation.
	var pace: HKQuantity? {
		guard let dist = totalDistance else {
			return nil
		}

		return HKQuantity(unit: .secondPerMeter, doubleValue: duration / dist.doubleValue(for: .meter()))
			.filterAsPace(withMaximum: maxPace)
	}
	///Average speed of the workout in distance per unit time, see `speedUnit` for the desired unit for presentation.
	var speed: HKQuantity? {
		guard let dist = totalDistance, duration > 0 else {
			return nil
		}

		return HKQuantity(unit: .meterPerSecond, doubleValue: dist.doubleValue(for: .meter()) / duration)
	}

	/// Active energy burned during the workout, in kilocalories.
	private var activeCaloriesData = 0.0
	/// Basal energy burned during the workout, in kilocalories.
	private var restingCaloriesData = 0.0
	/// Intermediate step to compute the total energy burned during the workout, in kilocalories.
	private var rawTotalCalories: Double? {
		let total = (rawActiveCalories ?? 0) + restingCaloriesData
		return total > 0 ? total : nil
	}
	/// Intermediate step to compute the active energy burned during the workout, in kilocalories.
	private var rawActiveCalories: Double? {
		if activeCaloriesData > 0 {
			return activeCaloriesData
		} else if let total = raw.totalEnergyBurned?.doubleValue(for: .kilocalorie()), total > 0 {
			return total
		} else {
			return nil
		}
	}
	///Total energy burned.
	var totalEnergy: HKQuantity? {
		if let kcal = rawTotalCalories ?? rawActiveCalories {
			return HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
		} else {
			return nil
		}
	}
	///Active energy burned.
	var activeEnergy: HKQuantity? {
		if rawTotalCalories != nil, let kcal = rawActiveCalories {
			return HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
		} else {
			return nil
		}
	}

	private var rawStart: TimeInterval {
		return raw.startDate.timeIntervalSince1970
	}
	private let workoutPredicate: NSPredicate!
	private let timePredicate: NSPredicate!
	private let sourcePredicate: NSPredicate!

	/// Create an instance of the proper `Workout` subclass (if any) for the given workout.
	class func workoutFor(raw: HKWorkout, from healthData: Health, and preferences: Preferences) -> Workout {
		let wClass: Workout.Type

		switch raw.workoutActivityType {
		case .running, .walking:
			wClass = RunningWorkout.self
			#warning("Add back")
//		case .swimming:
//			wClass = SwimmingWorkout.self
		default:
			wClass = Workout.self
		}

		return wClass.init(raw, from: healthData, and: preferences)
	}

	required init(_ raw: HKWorkout, from healthData: Health, and _: Preferences) {
		self.healthStore = healthData.store
		self.raw = raw

		guard healthData.isHealthDataAvailable else {
			loadedFully = false
			hasError = true
			workoutPredicate = nil
			timePredicate = nil
			sourcePredicate = nil

			return
		}

		workoutPredicate = HKQuery.predicateForObjects(from: raw)
		timePredicate = NSPredicate(format: "%K >= %@ AND %K < %@", HKPredicateKeyPathEndDate, raw.startDate as NSDate, HKPredicateKeyPathStartDate, raw.endDate as NSDate)
		sourcePredicate = HKQuery.predicateForObjects(from: raw.sourceRevision.source)

		if let heart = WorkoutDataQuery(typeID: .heartRate, withUnit: WorkoutUnit.heartRate.default, andTimeType: .instant, searchingBy: .time) {
			self.addQuery(heart, isBase: true)
		}
		if let activeCal = WorkoutDataQuery(typeID: .activeEnergyBurned, withUnit: .kilocalorie(), andTimeType: .ranged, searchingBy: .workout(fallbackToTime: true)) {
			self.addQuery(activeCal, isBase: true)
		}
		if let baseCal = WorkoutDataQuery(typeID: .basalEnergyBurned, withUnit: .kilocalorie(), andTimeType: .ranged, searchingBy: .time) {
			self.addQuery(baseCal, isBase: true)
		}
	}

	/// Set the units the specific workout requires for distance, speed and pace.
	/// - parameter dUnit: The unit used for distances, a length unit.
	/// - parameter sUnit: The unit used for speed, a length unit divided by a time unit.
	/// - parameter pUnit: The unit used for pace. By definition should be a time unit divided by a length unit but as times are always reported as `TimeInterval`, i.e. secods, just a length unit must be provided.
	func setUnitsFor(distance dUnit: WorkoutUnit, speed sUnit: WorkoutUnit, andPace pUnit: WorkoutUnit) {
		guard !isLoading && !loaded else {
			return
		}

		precondition(distanceUnit.is(compatibleWith: dUnit), "Distance unit not valid, provide a length unit")
		precondition(speedUnit.is(compatibleWith: sUnit), "Speed unit not valid, provide a speed unit")
		precondition(paceUnit.is(compatibleWith: pUnit), "Pace unit not valid, provide a length unit")

		distanceUnit = dUnit
		speedUnit = sUnit
		paceUnit = pUnit
	}

	/// Sets the max acceptable pace, if any, in time per unit length.
	func set(maxPace: HKQuantity?) {
		guard !isLoading && !loaded else {
			return
		}

		if let mp = maxPace, mp > HKQuantity(unit: .secondPerMeter, doubleValue: 0) {
			self.maxPace = mp
		} else {
			self.maxPace = nil
		}
	}

	// MARK: - Set and load other data

	/// Add a query to load data for the workout.
	/// - parameter isBase: Whether to execute the resulting query even if doing a quick load. This needs to be set to `true` when the data is part of `exportGeneralData()`.
	private func addQuery(_ q: WorkoutDataQuery, isBase: Bool) {
		guard !isLoading && !loaded else {
			return
		}

		if isBase {
			baseReq.append(q)
		} else {
			requests.append(q)

			if let changePublisher = q.dataChanged {
				cancellables.append(changePublisher.sink { [weak self] v in
					self?.reload(request: q)
				})
			}
		}
	}

	/// Add a query to load data for the workout.
	func addQuery(_ q: WorkoutDataQuery) {
		self.addQuery(q, isBase: false)
	}

	func addAdditionalDataProcessors(_ dp: AdditionalDataProcessor...) {
		guard !isLoading && !loaded else {
			return
		}

		self.additionalProcessors += dp
	}

	func addAdditionalDataProviders(_ dp: AdditionalDataProvider...) {
		guard !isLoading && !loaded else {
			return
		}

		self.additionalProviders += dp
	}

	func addAdditionalDataProcessorsAndProviders(_ dp: (AdditionalDataProcessor & AdditionalDataProvider)...) {
		guard !isLoading && !loaded else {
			return
		}

		self.additionalProcessors += dp as [AdditionalDataProcessor]
		self.additionalProviders += dp as [AdditionalDataProvider]
	}

	/// Loads required additional data for the workout.
	/// - parameter quickLoad: If enabled only base queries, i.e. heart data and calories, will be executed and not custom ones defined by specific workouts.
	func load(quickly quickLoad: Bool = false) {
		#warning("If requesting a full load when only quick loaded, then run only additional queries. Required for bulk exporting when workouts are shared between the list and the detail view")
		guard !isLoading && !loaded else {
			return
		}

		for dp in additionalProcessors {
			dp.set(workout: self)
		}

		loadingFully = !quickLoad
		let req = baseReq + (quickLoad ? [] : requests)
		DispatchQueue.workout.async {
			self.requestToDo = req.count
			self.requestDone = 0
		}

		for r in req {
			self.execute(query: r)
		}
	}

	/// Execute again a query when the query itself requires it.
	///
	/// This method is designed to work for additional queries, not the base one, i.e. those added by custom workouts for `AdditionalDataProcessor`s, so it works only when the workout has already been fully loaded.
	private func reload(request: WorkoutDataQuery) {
		guard loadedFully == true, !hasError else {
			return
		}

		DispatchQueue.workout.async {
			self.loadingFully = true
			// Increase request pending by one. This way if there's another reloading in progress only when both end the workout will signal an update.
			// The request pending count will automatically reset to 0 when all are loaded.
			self.requestToDo += 1
		}

		self.execute(query: request)
	}

	/// This method should be called only by `load(quickly:)` and `reload(request:)`.
	private func execute(query: WorkoutDataQuery) {
		let reloading = fullyLoaded
		query.execute(on: healthStore, forStart: startDate, usingWorkoutPredicate: workoutPredicate, timePredicate: timePredicate, sourcePredicate: sourcePredicate) { _, data, err  in
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
				if dp.wantData(for: query.typeID) {
					dp.process(data: res, for: query, reloaded: reloading)
				}
			}

			if [HKQuantityTypeIdentifier.heartRate, .activeEnergyBurned, .basalEnergyBurned].contains(query.typeID) {
				let hrUnit = WorkoutUnit.heartRate.default
				var avgHeart = 0.0

				for s in res {
					if query.typeID == .heartRate {
						if let mh = self.maxHeart {
							self.maxHeart = max(mh, s.quantity)
						} else {
							self.maxHeart = s.quantity
						}
						avgHeart += s.quantity.doubleValue(for: hrUnit)
					} else {
						let kcal = s.quantity.doubleValue(for: .kilocalorie())
						if query.typeID == .activeEnergyBurned {
							self.activeCaloriesData += kcal
						} else if query.typeID == .basalEnergyBurned {
							self.restingCaloriesData += kcal
						}
					}
				}

				if query.typeID == .heartRate {
					self.avgHeart = res.isEmpty ? nil : HKQuantity(unit: hrUnit, doubleValue: avgHeart / Double(res.count))
				}
			}
		}
	}

	// MARK: - Destroy

	func destroy() {
		#warning("This should not be required when SwiftUI correctly drop references to environment objects")
		for c in cancellables {
			c.cancel()
		}
		for dproc in additionalProcessors {
			dproc.cancel()
		}
		for dprov in additionalProviders {
			dprov.cancel()
		}

		baseReq = []
		requests = []
		cancellables = []
		additionalProviders = []
		additionalProcessors = []
		hasError = true
	}

	// MARK: - Export

	#warning("Add back")
	/*
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
		data += "\("Distance \(distanceUnit.description(for: preferences))".toCSV())\(sep)" + genData[4] + "\n"
		data += "\("Average Heart Rate".toCSV())\(sep)" + genData[5] + "\n"
		data += "\("Max Heart Rate".toCSV())\(sep)" + genData[6] + "\n"
		data += "\("Average Pace time/\(paceUnit.description(for: preferences))".toCSV())\(sep)" + genData[7] + "\n"
		data += "\("Average Speed \(speedUnit.description(for: preferences))/h".toCSV())\(sep)" + genData[8] + "\n"
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
	*/
}
