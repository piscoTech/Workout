//
//  StepSource.swift
//  Workout
//
//  Created by Marco Boschi on 10/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import HealthKit

enum StepSource: CustomStringConvertible {
	private static let phoneStr = "iphone"
	private static let watchStr = "watch"

	case iPhone, watch
	case custom(String)

	var description: String {
		switch self {
		case .iPhone:
			return StepSource.phoneStr
		case .watch:
			return StepSource.watchStr
		case let .custom(str):
			return str
		}
	}

	var displayName: String {
		switch self {
		case .iPhone:
			return "iPhone"
		case .watch:
			return "Apple Watch"
		case let .custom(str):
			return str
		}
	}

	static func getSource(for str: String) -> StepSource {
		switch str.lowercased() {
		case "":
			fallthrough
		case phoneStr:
			return .iPhone
		case watchStr:
			return .watch
		default:
			return .custom(str)
		}
	}

	private static var predicateCache = [String: NSPredicate]()
	private static var predicateRequestCache = [String: [(NSPredicate) -> Void]]()

	/// Fetch the predicate to load only those step data point for the relevant source(s).
	func getPredicate(for healthStore: HKHealthStore, _ callback: @escaping (NSPredicate) -> Void) {
		DispatchQueue.workout.async {
			if StepSource.predicateRequestCache.keys.contains(self.description) {
				// A request for the same predicate is ongoing, wait for it
				StepSource.predicateRequestCache[self.description]?.append(callback)
			} else if let cached = StepSource.predicateCache[self.description] {
				// The requested predicate has been already loaded
				callback(cached)
			} else {
				guard let type = HKQuantityTypeIdentifier.stepCount.getType() else {
					fatalError("Step count type doesn't seem to exists...")
				}

				let q = HKSourceQuery(sampleType: type, samplePredicate: nil) { _, res, _ in
					let sources = (res ?? Set()).filter { s in
						return s.name.lowercased().range(of: self.description.lowercased()) != nil
					}

					let predicate = HKQuery.predicateForObjects(from: sources)
					DispatchQueue.workout.async {
						StepSource.predicateCache[self.description] = predicate
						if let callbacks = StepSource.predicateRequestCache.removeValue(forKey: self.description) {
							for c in callbacks {
								c(predicate)
							}
						}
					}
				}

				StepSource.predicateRequestCache[self.description] = [callback]
				healthStore.execute(q)
			}
		}
	}

}
