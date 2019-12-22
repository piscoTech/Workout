//
//  Workout.swift
//  Workout
//
//  Created by Marco Boschi on 20/07/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import HealthKit
import MBLibrary

public protocol WorkoutDelegate: AnyObject {

	func workoutLoaded(_ workout: Workout)

}

public class Workout {

	private let healthStore: HKHealthStore
	public let raw: HKWorkout

	weak var delegate: WorkoutDelegate?

	/// Request required for base data for a quick load.
	private var baseReq = [WorkoutDataQuery]()
	/// Request for additional details and a full load.
	private var requests = [WorkoutDataQuery]()

	// Set when .load() is called
	private var requestToDo = 0
	private var requestDone = 0 {
		didSet {
			if requestDone == requestToDo, requestToDo > 0 {
				completeLoading()
			}
		}
	}

	private var additionalProcessors = [AdditionalDataProcessor]()
	private var additionalExtractor = [AdditionalDataExtractor]()

	private var allAdditionalProviders = [AdditionalDataProvider]()
	/// Additional data providers with data to display
	public var additionalProviders: [AdditionalDataProvider] {
		allAdditionalProviders.filter { $0.numberOfRows > 0 }
	}

	public private(set) var isLoading = false
	public private(set) var isLoaded = false
	public private(set) var hasError = false

	/// The unit to represent distances.
	public private(set) var distanceUnit = WorkoutUnit.kilometerAndMile
	/// The length unit to represent paces, time will be added automatically.
	public private(set) var paceUnit = WorkoutUnit.kilometerAndMile
	/// The unit to represent speeds.
	public private(set) var speedUnit = WorkoutUnit.kilometerAndMilePerHour

	/// Max acceptable pace, if any, in time per unit length.
	private(set) var maxPace: HKQuantity?

	public var name: String {
		return raw.workoutActivityName
	}
	public var type: HKWorkoutActivityType {
		return raw.workoutActivityType
	}
	public var startDate: Date {
		return raw.startDate
	}
	public var endDate: Date {
		return raw.endDate
	}
	public var duration: TimeInterval {
		return raw.duration
	}
	/// The total distance of the workout, see `distanceUnit` for the desired unit for presentation.
	public var totalDistance: HKQuantity? {
		// Don't expose a 0 distance, give nil instead
		if let dist = raw.totalDistance, dist > HKQuantity(unit: .meter(), doubleValue: 0) {
			return dist
		} else {
			return nil
		}
	}
	public private(set) var maxHeart: HKQuantity?
	public private(set) var avgHeart: HKQuantity?
	/// Average pace of the workout in time per unit length, see `paceUnit` for the desired unit for presentation.
	public var pace: HKQuantity? {
		guard let dist = totalDistance else {
			return nil
		}

		return HKQuantity(unit: .secondPerMeter, doubleValue: duration / dist.doubleValue(for: .meter()))
			.filterAsPace(withMaximum: maxPace)
	}
	///Average speed of the workout in distance per unit time, see `speedUnit` for the desired unit for presentation.
	public var speed: HKQuantity? {
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
	/// Total energy burned.
	public var totalEnergy: HKQuantity? {
		if let kcal = rawTotalCalories ?? rawActiveCalories {
			return HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
		} else {
			return nil
		}
	}
	/// Active energy burned.
	public var activeEnergy: HKQuantity? {
		if rawTotalCalories != nil, let kcal = rawActiveCalories {
			return HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
		} else {
			return nil
		}
	}
	
	private var elevationChangeCache: (ascended: HKQuantity?, descended: HKQuantity?)?
	/// The elevation change, divided in distance ascended and descended, during the whole duration of the workout.
	public var elevationChange: (ascended: HKQuantity?, descended: HKQuantity?) {
		let (asc, desc) = raw.elevationChange
		
		if asc == nil && desc == nil {
			if let eg = elevationChangeCache {
				return eg
			} else if let res = allAdditionalProviders.compactMap({ $0 as? ElevationChangeProvider }).first?.elevationChange {
				self.elevationChangeCache = res
				
				return res
			} else {
				return (nil, nil)
			}
		} else {
			return (asc, desc)
		}
	}

	private var rawStart: TimeInterval {
		return raw.startDate.timeIntervalSince1970
	}
	private let workoutPredicate: NSPredicate!
	private let timePredicate: NSPredicate!
	private let sourcePredicate: NSPredicate!

	/// Create an instance of the proper `Workout` subclass (if any) for the given workout.
	public class func workoutFor(raw: HKWorkout, from healthData: Health, and preferences: Preferences, delegate: WorkoutDelegate? = nil) -> Workout {
		let wClass: Workout.Type

		switch raw.workoutActivityType {
		case .running, .walking:
			wClass = RunningWorkout.self
		case .swimming:
			wClass = SwimmingWorkout.self
		case .cycling:
			wClass = CyclingWorkout.self
		default:
			wClass = Workout.self
		}
		let wrkt = wClass.init(raw, from: healthData, and: preferences, delegate: delegate)

		if #available(iOS 11.0, *) {
			let route = WorkoutRoute(with: preferences)
			wrkt.addAdditionalExtractorsAndProviders(route)
		}

		return wrkt
	}

	required init(_ raw: HKWorkout, from healthData: Health, and _: Preferences, delegate del: WorkoutDelegate? = nil) {
		self.healthStore = healthData.store
		self.raw = raw
		self.delegate = del

		guard healthData.isHealthDataAvailable else {
			isLoaded = true
			hasError = true
			workoutPredicate = nil
			timePredicate = nil
			sourcePredicate = nil
			delegate?.workoutLoaded(self)

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
		guard !isLoading && !isLoaded else {
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
		guard !isLoading && !isLoaded else {
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
		guard !isLoading && !isLoaded else {
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

	func addAdditionalExtractor(_ de: AdditionalDataExtractor...) {
		guard !isLoading && !isLoaded else {
			return
		}

		self.additionalExtractor += de
	}

	func addAdditionalProcessors(_ dp: AdditionalDataProcessor...) {
		guard !isLoading && !isLoaded else {
			return
		}

		self.additionalProcessors += dp
	}

	func addAdditionalProviders(_ dp: AdditionalDataProvider...) {
		guard !isLoading && !isLoaded else {
			return
		}

		self.allAdditionalProviders += dp
	}

	func addAdditionalProcessorsAndProviders(_ dp: (AdditionalDataProcessor & AdditionalDataProvider)...) {
		guard !isLoading && !isLoaded else {
			return
		}

		self.additionalProcessors += dp as [AdditionalDataProcessor]
		self.allAdditionalProviders += dp as [AdditionalDataProvider]
	}

	func addAdditionalExtractorsAndProviders(_ dep: (AdditionalDataExtractor & AdditionalDataProvider)...) {
		guard !isLoading && !isLoaded else {
			return
		}

		self.additionalExtractor += dep as [AdditionalDataExtractor]
		self.allAdditionalProviders += dep as [AdditionalDataProvider]
	}

	/// Loads required additional data for the workout.
	/// - parameter quickLoad: If enabled only base queries, i.e. heart data and calories, will be executed and not custom ones defined by specific workouts.
	public func load(quickly quickLoad: Bool = false) {
		guard !isLoading && !isLoaded else {
			return
		}

		for dp in additionalProcessors {
			dp.set(workout: self)
		}

		isLoading = true
		let req = baseReq + (quickLoad ? [] : requests)
		let othExtractor = quickLoad ? [] : additionalExtractor
		DispatchQueue.workout.async {
			self.requestToDo = req.count + othExtractor.count
			self.requestDone = 0
		}

		// Execute quantity sample queries
		for r in req {
			r.execute(on: healthStore, forStart: startDate, usingWorkoutPredicate: workoutPredicate, timePredicate: timePredicate, sourcePredicate: sourcePredicate) { _, data, err  in
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
					let hrUnit = WorkoutUnit.heartRate.default
					var avgHeart = 0.0

					for s in res {
						if r.typeID == .heartRate {
							if let mh = self.maxHeart {
								self.maxHeart = max(mh, s.quantity)
							} else {
								self.maxHeart = s.quantity
							}
							avgHeart += s.quantity.doubleValue(for: hrUnit)
						} else {
							let kcal = s.quantity.doubleValue(for: .kilocalorie())
							if r.typeID == .activeEnergyBurned {
								self.activeCaloriesData += kcal
							} else if r.typeID == .basalEnergyBurned {
								self.restingCaloriesData += kcal
							}
						}
					}

					if r.typeID == .heartRate {
						self.avgHeart = res.isEmpty ? nil : HKQuantity(unit: hrUnit, doubleValue: avgHeart / Double(res.count))
					}
				}
			}
		}

		// Execute other queries
		for e in othExtractor {
			e.set(workout: self)
			e.extract(from: healthStore) { success in
				defer {
					// Move to a serial queue to synchronize access to counter
					DispatchQueue.workout.async {
						self.requestDone += 1
					}
				}

				if !success {
					self.hasError = true
				}
			}
		}
	}
	
	private func completeLoading() {
		isLoading = false
		isLoaded = true
		requestToDo = 0
		requestDone = 0
		
		elevationChangeCache = nil
		
		DispatchQueue.main.async {
			self.delegate?.workoutLoaded(self)
		}
	}

	// MARK: - Export

	private func generalData(for systemOfUnits: SystemOfUnits) -> [String] {
		[
			name.toCSV(),
			startDate.unixDateTime.toCSV(),
			endDate.unixDateTime.toCSV(),
			duration.rawDuration().toCSV(),
			totalDistance?.formatAsDistance(withUnit: distanceUnit.unit(for: systemOfUnits), rawFormat: true).toCSV() ?? "",
			avgHeart?.formatAsHeartRate(withUnit: WorkoutUnit.heartRate.unit(for: systemOfUnits), rawFormat: true).toCSV() ?? "",
			maxHeart?.formatAsHeartRate(withUnit: WorkoutUnit.heartRate.unit(for: systemOfUnits), rawFormat: true).toCSV() ?? "",
			pace?.formatAsPace(withReferenceLength: paceUnit.unit(for: systemOfUnits), rawFormat: true).toCSV() ?? "",
			speed?.formatAsSpeed(withUnit: speedUnit.unit(for: systemOfUnits), rawFormat: true).toCSV() ?? "",
			activeEnergy?.formatAsEnergy(withUnit: WorkoutUnit.calories.unit(for: systemOfUnits), rawFormat: true).toCSV() ?? "",
			totalEnergy?.formatAsEnergy(withUnit: WorkoutUnit.calories.unit(for: systemOfUnits), rawFormat: true).toCSV() ?? "",
			elevationChange.ascended?.formatAsElevationChange(withUnit: WorkoutUnit.elevation.unit(for: systemOfUnits), rawFormat: true).toCSV() ?? "",
			elevationChange.descended?.formatAsElevationChange(withUnit: WorkoutUnit.elevation.unit(for: systemOfUnits), rawFormat: true).toCSV() ?? ""
		]
	}

	func exportGeneralData(for systemOfUnits: SystemOfUnits) -> String {
		guard isLoaded, !hasError else {
			return ""
		}

		return generalData(for: systemOfUnits).joined(separator: CSVSeparator)
	}

	public func export(for preferences: Preferences, _ callback: @escaping ([URL]?) -> Void) {
		let systemOfUnits = preferences.systemOfUnits

		guard isLoaded, !hasError else {
			callback(nil)
			return
		}

		DispatchQueue.background.async {
			let general = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("generalData.csv")
			guard let file = OutputStream(url: general, append: false) else {
				callback(nil)
				return
			}

			do {
				file.open()
				defer {
					file.close()
				}

				let genData = self.generalData(for: systemOfUnits)
				let sep = CSVSeparator
				try file.write("Field\(sep)Value\n")
				try file.write("Type\(sep)" + genData[0] + "\n")
				try file.write("Start\(sep)" + genData[1] + "\n")
				try file.write("End\(sep)" + genData[2] + "\n")
				try file.write("Duration\(sep)" + genData[3] + "\n")
				try file.write("\("Distance \(self.distanceUnit.unit(for: systemOfUnits).description)".toCSV())\(sep)" + genData[4] + "\n")
				try file.write("\("Average Heart Rate".toCSV())\(sep)" + genData[5] + "\n")
				try file.write("\("Max Heart Rate".toCSV())\(sep)" + genData[6] + "\n")
				try file.write("\("Average Pace time/\(self.paceUnit.unit(for: systemOfUnits).description)".toCSV())\(sep)" + genData[7] + "\n")
				try file.write("\("Average Speed \(self.speedUnit.unit(for: systemOfUnits).description)".toCSV())\(sep)" + genData[8] + "\n")
				try file.write("\("Active Energy \(WorkoutUnit.calories.unit(for: systemOfUnits).description)".toCSV())\(sep)" + genData[9] + "\n")
				try file.write("\("Total Energy \(WorkoutUnit.calories.unit(for: systemOfUnits).description)".toCSV())\(sep)" + genData[10] + "\n")
				try file.write("\("Elevation Ascended \(WorkoutUnit.elevation.unit(for: systemOfUnits).description)".toCSV())\(sep)" + genData[11] + "\n")
				try file.write("\("Elevation Descended \(WorkoutUnit.elevation.unit(for: systemOfUnits).description)".toCSV())\(sep)" + genData[12] + "\n")
			} catch {
				callback(nil)
				return
			}

			if self.allAdditionalProviders.isEmpty {
				callback([general])
			} else {
				var files = [[URL]?](repeating: nil, count: self.allAdditionalProviders.count)
				var completed = 0
				for (i, dp) in self.allAdditionalProviders.enumerated() {
					dp.export(for: preferences) { f in
						DispatchQueue.workout.async {
							completed += 1
							files[i] = f

							if completed == self.allAdditionalProviders.count {
								DispatchQueue.background.async {
									if let res = files.reduce([], { (res, partial) -> [URL]? in
										if let r = res, let p = partial {
											return r + p
										} else {
											return nil
										}
									}) {
										callback([general] + res)
									} else {
										callback(nil)
									}
								}
							}
						}
					}
				}
			}
		}
	}
	
}
