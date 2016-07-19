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

let heartRateF = { Void -> NumberFormatter in
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	formatter.usesSignificantDigits = false
	formatter.maximumFractionDigits = 0
	
	return formatter
}()

extension Double {
	
	///- returns: The formatted values, considered in kilometers.
	func getFormattedDistance() -> String {
		return distanceF.string(fromValue: self, unit: .kilometer)
	}
	
	func getFormattedHeartRate() -> String {
		return heartRateF.string(from: self)! + " bpm"
	}
	
}

extension HKUnit {
	
	class func heartRateUnit() -> HKUnit {
		return HKUnit.count().unitDivided(by: HKUnit.minute())
	}
	
}
