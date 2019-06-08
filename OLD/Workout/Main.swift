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

///Enable or disable ads override.
let adsEnable = true
///Ads publisher ID
let adsPublisherID = "pub-7085161342725707"
//Ads app ID is set in the app Info.plist file
///Ads unit ID.
let adsUnitID = "ca-app-pub-7085161342725707/5192351673"

var areAdsEnabled: Bool {
	return adsEnable && !iapManager.isProductPurchased(pId: removeAdsId)
}

/// ID for InApp purchase to remove ads.
let removeAdsId = "MarcoBoschi.ios.Workout.removeAds"
let iapManager = InAppPurchaseManager(productIds: [removeAdsId], inUserDefaults: Preferences.local)
