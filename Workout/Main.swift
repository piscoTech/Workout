//
//  Main.swift
//  Workout
//
//  Created by Marco Boschi on 15/01/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary
import WorkoutCore

let preferences = Preferences()
let healthData = Health()

/// Enable or disable ads override.
let adsEnable = true
/// Enabled status of ads.
var areAdsEnabled: Bool {
	return adsEnable && !iapManager.isProductPurchased(pId: removeAdsId)
}

let iapManager = InAppPurchaseManager(productIds: [removeAdsId], inUserDefaults: preferences.local)
