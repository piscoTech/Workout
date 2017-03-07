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
///Enable or disable ads override.
let adsEnable = true
///Ads ID.
///
///For test purposes use the test ID provided by Google: `ca-app-pub-3940256099942544/2934735716`.
let adsID = "ca-app-pub-7085161342725707/5192351673"
///Filter for step count source name.
var stepSourceFilter: StepSource {
	return StepSource.getSource(for: preferences.string(forKey: PreferenceKey.stepSource) ?? "")
}

let healthStore = HKHealthStore()

var areAdsEnabled: Bool {
	return adsEnable && !iapManager.isProductPurchased(pId: removeAdsId)
}

let removeAdsId = "MarcoBoschi.ios.Workout.removeAds"
let iapManager = InAppPurchaseManager(productIds: [removeAdsId], inUserDefaults: preferences)

let distanceF = { Void -> NumberFormatter in
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	formatter.usesSignificantDigits = false
	formatter.maximumFractionDigits = 2
	
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
	
	///- parameter forLengthUnit: The unit to use to represent the distance component
	///- returns: The formatted value, considered in time per `forLengthUnit`.
	func getFormattedPace(forLengthUnit unit: HKUnit) -> String {
		return getDuration() + "/\(unit.description)"
	}
	
}

extension Double {
	
	///- returns: The formatted value, considered in the passed unit.
	func getFormattedDistance(withUnit unit: HKUnit) -> String {
		return distanceF.string(from: NSNumber(value: self))! + " \(unit.description)"
	}
	
	///- parameter forLengthUnit: The unit to use to represent the distance component
	///- returns: The formatted value, considered in `forLengthUnit` per hour.
	func getFormattedSpeed(forLengthUnit unit: HKUnit) -> String {
		return speedF.string(from: NSNumber(value: self))! + " \(unit.description)/h"
	}
	
	func getFormattedHeartRate() -> String {
		return integerF.string(from: NSNumber(value: self))! + " bpm"
	}
	
	func convertFrom(_ un1: HKUnit, to un2: HKUnit) -> Double {
		let quant = HKQuantity(unit: un1, doubleValue: self)
		precondition(quant.is(compatibleWith: un2), "Units are not compatible")
		
		return quant.doubleValue(for: un2)
	}
	
}

extension DispatchQueue {
	
	///Serial queue to synchronize access to counters and data when loading and exporting workouts.
	static let workout = DispatchQueue(label: "Marco-Boschi.ios.Workout.loadExport")
	
}
