//
//  HealthKit.swift
//  Workout
//
//  Created by Marco Boschi on 04/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit

extension HKWorkoutActivityType {
	
	var name: String {
		let wType: Int
		
		switch self {
		case .running:
			wType = 1
		case .functionalStrengthTraining:
			wType = 2
		case .swimming:
			wType = 3
		default:
			wType = 0
		}
		
		return NSLocalizedString("WORKOUT_NAME_\(wType)", comment: "Workout")
	}
	
}

extension HKQuantityTypeIdentifier {
	
	func getType() -> HKQuantityType? {
		return HKObjectType.quantityType(forIdentifier: self)
	}
	
}

extension HKUnit {
	
	class func heartRate() -> HKUnit {
		return HKUnit.count().unitDivided(by: HKUnit.minute())
	}
	
	class func steps() -> HKUnit {
		return HKUnit.count()
	}
	
	class func strokes() -> HKUnit {
		return HKUnit.count()
	}
	
	class func kilometer() -> HKUnit {
		return HKUnit.meterUnit(with: .kilo)
	}
	
}
