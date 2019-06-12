//
//  WorkoutDataQuery.swift
//  Workout
//
//  Created by Marco Boschi on 27/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit
import Combine

/// Manage the delayed and lazy creation of a `HKSampleQuery` required for loading data of a workout.
class WorkoutDataQuery {
	
	enum SearchType {
		case time, workout(fallbackToTime: Bool)
	}
	
	typealias AdditionalPredicateProvider = (@escaping (NSPredicate?) -> Void) -> Void
	typealias DataChangedPublisher = AnyPublisher<Any, Never>
	
	let typeID: HKQuantityTypeIdentifier
	let type: HKQuantityType
	let unit: HKUnit
	let timeType: DataPointType
	let searchType: SearchType
	let dataChanged: DataChangedPublisher?
	private let additionalPredicateProvider: AdditionalPredicateProvider?
	
	private static let queryNoLimit = HKObjectQueryNoLimit
	private static let startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
	
	/// Prepare all data required for creating the query.
	///
	/// The creation fails if the given type identifier does not correspond to a concrete type.
	/// - parameter dataChanged: The workout using this query will subscribe to events from this publisher, when something is received the query is evaluated again.
	init?<P>(typeID: HKQuantityTypeIdentifier, withUnit unit: HKUnit, andTimeType tType: DataPointType, searchingBy sType: SearchType, dataChanged: P?, predicate additionalPredicate: AdditionalPredicateProvider? = nil) where P: Publisher, P.Output: Any, P.Failure == Never {
		guard let type = typeID.getType() else {
			return nil
		}
		
		self.typeID = typeID
		self.type = type
		self.unit = unit
		self.timeType = tType
		self.searchType = sType
		if let dc = dataChanged {
			self.dataChanged = AnyPublisher(dc.map { $0 as Any })
		} else {
			self.dataChanged = nil
		}
		self.additionalPredicateProvider = additionalPredicate
	}

	/// Prepare all data required for creating the query.
	///
	/// The creation fails if the given type identifier does not correspond to a concrete type.
	convenience init?(typeID: HKQuantityTypeIdentifier, withUnit unit: HKUnit, andTimeType tType: DataPointType, searchingBy sType: SearchType, predicate additionalPredicate: AdditionalPredicateProvider? = nil) {
		self.init(typeID: typeID, withUnit: unit, andTimeType: tType, searchingBy: sType, dataChanged: nil as AnyPublisher<Any,Never>?, predicate: additionalPredicate)
	}
	
	/// Prepare all data required for creating the query.
	///
	/// The creation fails if the given type identifier does not correspond to a concrete type.
	/// - parameter dataChanged: The workout using this query will subscribe to events from this publisher, when something is received the query is evaluated again.
	convenience init?<P>(typeID: HKQuantityTypeIdentifier, withUnit unit: HKUnit, andTimeType tType: DataPointType, searchingBy sType: SearchType, dataChanged: P?, predicate additionalPredicate: NSPredicate) where P: Publisher, P.Output: Any, P.Failure == Never {
		self.init(typeID: typeID, withUnit: unit, andTimeType: tType, searchingBy: sType, dataChanged: dataChanged) { c in
			c(additionalPredicate)
		}
	}

	/// Prepare all data required for creating the query.
	///
	/// The creation fails if the given type identifier does not correspond to a concrete type.
	convenience init?(typeID: HKQuantityTypeIdentifier, withUnit unit: HKUnit, andTimeType tType: DataPointType, searchingBy sType: SearchType, predicate additionalPredicate: NSPredicate) {
		self.init(typeID: typeID, withUnit: unit, andTimeType: tType, searchingBy: sType, dataChanged: nil as AnyPublisher<Any,Never>?, predicate: additionalPredicate)
	}
	
	func execute(on healthStore: HKHealthStore, forStart start: Date,
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
