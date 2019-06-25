//
//  HealthKit.swift
//  Workout
//
//  Created by Marco Boschi on 04/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit

extension HKQuantityTypeIdentifier {
	
	func getType() -> HKQuantityType? {
		return HKObjectType.quantityType(forIdentifier: self)
	}
	
}

extension HKQuantity {

	func `is`(compatibleWith unit: WorkoutUnit) -> Bool {
		return self.is(compatibleWith: unit.default)
	}

}
