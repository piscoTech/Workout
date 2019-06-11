//
//  Preferences.swift
//  Workout
//
//  Created by Marco Boschi on 03/08/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

enum PreferenceKeys: String, KeyValueStoreKey {

	case systemOfUnits = "systemOfUnits"
	case stepSource = "stepSource"
	case maxHeartRate = "maxHeartRate"
	case runningHeartZones = "runningHeartZones"

	case reviewRequestCounter = "reviewRequestCounter"

	var description: String {
		return rawValue
	}

}

class Preferences {

	let local = KeyValueStore(userDefaults: UserDefaults.standard)

	let reviewRequestThreshold = 3
	var reviewRequestCounter: Int {
		get {
			return local.integer(forKey: PreferenceKeys.reviewRequestCounter)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.reviewRequestCounter)
			local.synchronize()
		}
	}

	/// Filter for step count source name.
	var stepSourceFilter: StepSource {
		get {
			return StepSource.getSource(for: local.string(forKey: PreferenceKeys.stepSource) ?? "")
		}
		set {
			local.set(newValue.description, forKey: PreferenceKeys.stepSource)
			local.synchronize()
		}
	}

	/// Max heart rate for calculating running heart zones.
	///
	/// Any value less than 60bpm (a normal resting heart rate) is considered invalid.
	var maxHeartRate: Int? {
		get {
			let hr = local.integer(forKey: PreferenceKeys.maxHeartRate)
			return hr >= 60 ? hr : nil
		}
		set {
			if let hr = newValue {
				local.set(hr, forKey: PreferenceKeys.maxHeartRate)
			} else {
				local.removeObject(forKey: PreferenceKeys.maxHeartRate)
			}
			local.synchronize()
		}
	}

	/// The thresholds, i.e. lower bound, for each running heart zone.
	///
	/// The upper bound for each zone is the threshold for the next one or 100 for the last. Each threshold is in the range `0 ..< 100` and the array is sorted. Setting a value that does not respect this conditions will result in `nil` being set instead.
	var runningHeartZones: [Int]? {
		get {
			return local.array(forKey: PreferenceKeys.runningHeartZones) as? [Int]
		}
		set {
			if let hz = newValue, hz.first(where: { $0 < 0 || $0 >= 100 }) == nil, hz == hz.sorted() {
				local.set(hz, forKey: PreferenceKeys.runningHeartZones)
			} else {
				local.removeObject(forKey: PreferenceKeys.runningHeartZones)
			}
			local.synchronize()
		}
	}

	/// The system of units, e.g. metric or imperial, the user wants to use.
	var systemOfUnits: SystemOfUnits {
		get {
			return SystemOfUnits(rawValue: local.integer(forKey: PreferenceKeys.systemOfUnits)) ?? .default
		}
		set {
			local.set(newValue.rawValue, forKey: PreferenceKeys.systemOfUnits)
			local.synchronize()
		}
	}

}
