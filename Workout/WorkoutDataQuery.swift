//
//  WorkoutDataQuery.swift
//  Workout
//
//  Created by Marco Boschi on 27/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit

/// Manage the delayed and lazy creation of a `HKQuery` required for loading data of a workout.
class WorkoutDataQuery {
	
	enum SearchType {
		case time, workout(fallbackToTime: Bool)
	}
	
	typealias AdditionalPredicateProvider = (@escaping (NSPredicate) -> Void) -> Void
	
	let typeID: HKQuantityTypeIdentifier
	let type: HKQuantityType
	let unit: HKUnit
	let timeType: DataPointType
	let searchType: SearchType
	private let additionalPredicateProvider: AdditionalPredicateProvider?
	
	private static let queryNoLimit = HKObjectQueryNoLimit
	private static let startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
	
	/// Prepare all data required for creating the query.
	///
	/// The creation fails if the given type identifier does not correspond to a concreate type.
	/// - important: Make sure that when loading distance data (`.distanceWalkingRunning`, `.distanceSwimming` or others) you must specify `.meter()` as unit, use `setLengthPrefixFor(distance: _, speed: _, pace: _)` of the `Workout` to specify the desired prefixes.
	init?(typeID: HKQuantityTypeIdentifier, withUnit unit: HKUnit, andTimeType tType: DataPointType, searchingBy sType: SearchType, predicate additionalPredicate: AdditionalPredicateProvider? = nil) {
		guard let type = typeID.getType() else {
			return nil
		}
		
		self.typeID = typeID
		self.type = type
		self.unit = unit
		self.timeType = tType
		self.searchType = sType
		self.additionalPredicateProvider = additionalPredicate
	}
	
	/// Prepare all data required for creating the query.
	///
	/// The creation fails if the given type identifier does not correspond to a concreate type.
	/// - important: Make sure that when loading distance data (`.distanceWalkingRunning`, `.distanceSwimming` or others) you must specify `.meter()` as unit, use `setLengthPrefixFor(distance: _, speed: _, pace: _)` of the `Workout` to specify the desired prefixes.
	convenience init?(typeID: HKQuantityTypeIdentifier, withUnit unit: HKUnit, andTimeType tType: DataPointType, searchingBy sType: SearchType, predicate additionalPredicate: NSPredicate) {
		self.init(typeID: typeID, withUnit: unit, andTimeType: tType, searchingBy: sType) { c in
			c(additionalPredicate)
		}
	}
	
	func execute(forStart start: Date,
				 usingWorkoutPredicate wrktPred: NSPredicate, timePredicate timePred: NSPredicate, sourcePredicate srcPred: NSPredicate,
				 resultHandler handler: @escaping (HKSampleQuery, [HKSample]?, Error?) -> Void) {
		let predicate: NSPredicate
		var tryTimeIfEmpty = false
		switch searchType {
		case .time:
			predicate = timePred
		case let .workout(tryTime):
			predicate = wrktPred
			tryTimeIfEmpty = tryTime
		}
		
		func prepareQuery(withAdditionalPredicate additionalPredicate: NSPredicate?) {
			let mainPredicate: NSPredicate
			if let addPred = additionalPredicate {
				mainPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [addPred, predicate])
			} else {
				mainPredicate = predicate
			}
			
			func resultHandler(q: HKSampleQuery, r: [HKSample]?, err: Error?) {
				if tryTimeIfEmpty, err != nil || r?.count ?? 0 == 0 {
					tryTimeIfEmpty = false
					var preds: [NSPredicate] = [timePred, srcPred]
					if let addPred = additionalPredicate {
						preds.append(addPred)
					}
					let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: preds)
					let query = HKSampleQuery(sampleType: type,
											  predicate: predicate,
											  limit: WorkoutDataQuery.queryNoLimit,
											  sortDescriptors: [WorkoutDataQuery.startDateSort],
											  resultsHandler: resultHandler)
					healthStore.execute(query)
					
					return
				}
				
				handler(q, r, err)
			}
			let query = HKSampleQuery(sampleType: type,
									  predicate: mainPredicate,
									  limit: WorkoutDataQuery.queryNoLimit,
									  sortDescriptors: [WorkoutDataQuery.startDateSort],
									  resultsHandler: resultHandler)
			healthStore.execute(query)
		}
		
		if let addPred = self.additionalPredicateProvider {
			addPred { p in
				prepareQuery(withAdditionalPredicate: p)
			}
		} else {
			prepareQuery(withAdditionalPredicate: nil)
		}
	}
	
}
