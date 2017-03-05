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

///Keep track of the version of health authorization required, increase this number to automatically display an authorization request.
let authRequired = 2
///List of health data to require access to.
let healthReadData: Set<HKObjectType> = {
	var res: Set<HKObjectType> = [
		HKObjectType.workoutType(),
		HKObjectType.quantityType(forIdentifier: .heartRate)!,
		HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
		HKObjectType.quantityType(forIdentifier: .stepCount)!
	]
	
	if #available(iOS 10, *) {
		res.formUnion([
			HKObjectType.quantityType(forIdentifier: .distanceSwimming)!,
			HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)!
		])
	}
	
	return res
}()
///List of supported workouts.
let workoutTypes = [
	HKWorkoutActivityType.running,
	.functionalStrengthTraining,
	.swimming
]
///Enable or disable ads override.
let adsEnable = true
///Ads ID.
///
///For test purposes use the test ID provided by Google: `ca-app-pub-3940256099942544/2934735716`.
let adsID = "ca-app-pub-7085161342725707/5192351673"
///Filter for step count source name.
let stepSourceFilter = "Watch"

let healthStore = HKHealthStore()

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

let speedF = { Void -> NumberFormatter in
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	formatter.usesSignificantDigits = false
	formatter.maximumFractionDigits = 1
	
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
	
	///- returns: The formatted value, considered in kilometers.
	func getFormattedDistance() -> String {
		return distanceF.string(fromValue: self, unit: .kilometer)
	}
	
	///- returns: The formatted value, considered in kilometers per hour.
	func getFormattedSpeed() -> String {
		return speedF.string(from: NSNumber(value: self))! + " km/h"
	}
	
	func getFormattedHeartRate() -> String {
		return integerF.string(from: NSNumber(value: self))! + " bpm"
	}
	
}

extension DispatchQueue {
	
	///Serial queue to synchronize access to counters and data when loading and exporting workouts.
	static let workout = DispatchQueue(label: "Marco-Boschi.ios.Workout.loadExport")
	
}
