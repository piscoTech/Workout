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
///Keep track of the version of health authorization required, increase this number to automatically display an authorization request.
let authRequired = 1
///Enable or disable ads override.
let adsEnable = true
///Ads ID.
///
///For test purposes use the test ID provided by Google: `ca-app-pub-3940256099942544/2934735716`.
let adsID = "ca-app-pub-7085161342725707/5192351673"
///Filter for step count source name.
let stepSourceFilter = "Watch"

var areAdsEnabled: Bool {
	return adsEnable && !iapManager.isProductPurchased(pId: removeAdsId)
}

let removeAdsId = "MarcoBoschi.ios.Workout.removeAds"
let iapManager = InAppPurchaseManager(productIds: [removeAdsId], inUserDefaults: preferences)

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
		return integerF.string(from: NSNumber(value: self))! + " bpm"
	}
	
	func getFormattedSteps() -> String {
		return integerF.string(from: NSNumber(value: self))! + " steps"
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
