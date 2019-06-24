//
//  AdditionalDataProcessor.swift
//  Workout
//
//  Created by Marco Boschi on 28/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit

protocol AdditionalDataProcessor {
	
	/// Pass the parent workout if needed. The default implementation does nothing.
	func set(workout: Workout)
	func wantData(for typeIdentifier: HKQuantityTypeIdentifier) -> Bool
	func process(data: [HKQuantitySample], for request: WorkoutDataQuery, reloaded: Bool)
	/// Called when the workout is no longer in use, data and subrscription should be released. The default implementation does nothing.
	func cancel()
	
}

extension AdditionalDataProcessor {
	
	func set(workout: Workout) {}
	func cancel() {}
	
}
