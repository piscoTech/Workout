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
let authRequired = 4
///List of health data to require access to.
let healthReadData: Set<HKObjectType> = {
	var res: Set<HKObjectType> = [
		HKObjectType.workoutType(),
		HKObjectType.quantityType(forIdentifier: .heartRate)!,
		HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
		HKObjectType.quantityType(forIdentifier: .stepCount)!,
		HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
		HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!
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
///Ads publisher ID
let adsPublisherID = "pub-7085161342725707"
///Ads app ID.
let adsAppID = "ca-app-pub-7085161342725707~3715618473"
///Ads unit ID.
let adsUnitID = "ca-app-pub-7085161342725707/5192351673"
///Max acceptable pace in time per kilometer.
let maxPace: TimeInterval = 30 * 60

let healthStore = HKHealthStore()

var areAdsEnabled: Bool {
	return adsEnable && !iapManager.isProductPurchased(pId: removeAdsId)
}

/// ID for InApp purchase to remove ads.
let removeAdsId = "MarcoBoschi.ios.Workout.removeAds"
let iapManager = InAppPurchaseManager(productIds: [removeAdsId], inUserDefaults: Preferences.local)

let distanceF: NumberFormatter = {
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	formatter.usesSignificantDigits = false
	formatter.maximumFractionDigits = 2
	
	return formatter
}()

let speedF: NumberFormatter = {
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	formatter.usesSignificantDigits = false
	formatter.maximumFractionDigits = 1
	
	return formatter
}()

let integerF: NumberFormatter = {
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
	
	func filterAsPace(withLengthUnit unit: HKUnit) -> Double? {
		let timeKm = HKUnit.second().unitDivided(by: .meterUnit(with: .kilo))
		let timeUnit = HKUnit.second().unitDivided(by: unit)
		
		return self.convertFrom(timeUnit, to: timeKm) > maxPace ? nil : self
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
	
	///- returns: The formatted value, considered in kilocalories.
	func getFormattedCalories() -> String {
		return integerF.string(from: NSNumber(value: self))! + " kcal"
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
