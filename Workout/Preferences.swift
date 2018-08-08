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
