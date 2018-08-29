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
	case authorized = "authorized"
	case authVersion = "authVersion"
	case stepSource = "stepSource"
	case maxHeartRate = "maxHeartRate"
	
	case reviewRequestCounter = "reviewRequestCounter"
	
	var description: String {
		return rawValue
	}
	
}

class Preferences {
	
	static let local = KeyValueStore(userDefaults: UserDefaults.standard)
	private init() {}
	
	static let reviewRequestThreshold = 3
	static var reviewRequestCounter: Int {
		get {
			return local.integer(forKey: PreferenceKeys.reviewRequestCounter)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.reviewRequestCounter)
			local.synchronize()
		}
	}
	
	/// Filter for step count source name.
	static var stepSourceFilter: StepSource {
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
	static var maxHeartRate: Int? {
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
	
	// MARK: - Health Data Access
	
	static var authorized: Bool {
		get {
			return local.bool(forKey: PreferenceKeys.authorized)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.authorized)
			local.synchronize()
		}
	}
	
	static var authVersion: Int {
		get {
			return local.integer(forKey: PreferenceKeys.authVersion)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.authVersion)
			local.synchronize()
		}
	}
	
}
