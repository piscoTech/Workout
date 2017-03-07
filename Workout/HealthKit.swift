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
	
}
