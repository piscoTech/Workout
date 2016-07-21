//
//  Main.swift
//  Workout
//
//  Created by Marco Boschi on 15/01/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit
import MBLibrary

let healthStore = HKHealthStore()

let distanceF = { Void -> LengthFormatter in
	let formatter = LengthFormatter()
	formatter.numberFormatter.usesSignificantDigits = false
	formatter.numberFormatter.maximumFractionDigits = 3
	
	return formatter
}()

let integerF = { Void -> NumberFormatter in
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	formatter.usesSignificantDigits = false
	formatter.maximumFractionDigits = 0
	
	return formatter
}()

extension TimeInterval {
	
	func getFormattedPace() -> String {
		return getDuration() + "/km"
	}
	
}

extension Double {
	
	///- returns: The formatted values, considered in kilometers.
	func getFormattedDistance() -> String {
		return distanceF.string(fromValue: self, unit: .kilometer)
	}
	
	func getFormattedHeartRate() -> String {
		return integerF.string(from: self)! + " bpm"
	}
	
	func getFormattedSteps() -> String {
		return integerF.string(from: self)! + " steps"
	}
	
}

extension HKUnit {
	
	class func heartRate() -> HKUnit {
		return HKUnit.count().unitDivided(by: HKUnit.minute())
	}
	
	class func steps() -> HKUnit {
		return HKUnit.count()
	}
	
}
