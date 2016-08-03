//
//  Preferences.swift
//  Workout
//
//  Created by Marco Boschi on 03/08/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

let preferences = KeyValueStore(userDefaults: UserDefaults.standard)

enum PreferenceKey: String, KeyValueStoreKey {
	case authorized = "authorized"
	case authVersion = "authVersion"
	
	func get() -> String {
		return rawValue
	}
	
}
