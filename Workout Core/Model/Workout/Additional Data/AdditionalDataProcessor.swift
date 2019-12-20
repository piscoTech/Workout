//
//  AdditionalDataProcessor.swift
//  Workout
//
//  Created by Marco Boschi on 28/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit

protocol AdditionalDataProcessor: AdditionalDataManager {
	
	func wantData(for typeIdentifier: HKQuantityTypeIdentifier) -> Bool
	func process(data: [HKQuantitySample], for request: WorkoutDataQuery)
	
}
