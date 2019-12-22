//
//  InfoViewController.swift
//  Matrix
//
//  Created by Marco Boschi on 03/11/14.
//  Copyright (c) 2014 Marco Boschi. All rights reserved.
//

import HealthKit
import UIKit
import MBLibrary
import WorkoutCore

class AboutViewController: UITableViewController, PreferencesDelegate, RemoveAdsDelegate {
	
	private var appInfo: String!
	private let maxHeart = NSLocalizedString("HEART_ZONES_MAX_RATE", comment: "Max x bpm")
	
	private var numberOfRowsInAdsSection: Int {
		var count = 0
		if adsManager.areAdsEnabled {
			if InAppPurchaseManager.canMakePayments {
				count += 1 // Remove Ads & Restore
			}
			
			if adsManager.userCanRequestNonPersonalizedAds {
				count += 1 // Manage Consent
			}
		}
		
		return count
	}
	
	private var settingsSectionOffset: Int {
		return numberOfRowsInAdsSection > 0 ? 1 : 0
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		appInfo = NSLocalizedString("REPORT_TEXT", comment: "Report problem") + "\n\nWorkout \(Bundle.main.versionDescription)\n© 2016-2019 Marco Boschi"
		
		preferences.add(delegate: self)
		adsManager.removeAdsDelegate = self
		adsManager.presenter = self
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		switch section {
		case settingsSectionOffset + 1:
			return appInfo
		default:
			return nil
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2 + settingsSectionOffset
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		// Settings
		case settingsSectionOffset:
			return 4
		// Source Code & Contacts
		case settingsSectionOffset + 1:
			return 2
		// Remove Ads
		case 0:
			return numberOfRowsInAdsSection
		default:
			return 0
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch (indexPath.section, indexPath.row) {
		// Units
		case (settingsSectionOffset, 0):
			let cell = tableView.dequeueReusableCell(withIdentifier: "units", for: indexPath)
			setUnits(in: cell)
			return cell
		// Step Source
		case (settingsSectionOffset, 1):
			let cell = tableView.dequeueReusableCell(withIdentifier: "stepSource", for: indexPath)
			setStepSource(in: cell)
			return cell
		// Running Heart Zones
		case (settingsSectionOffset, 2):
			let cell = tableView.dequeueReusableCell(withIdentifier: "heartZones", for: indexPath)
			setMaxHeartRate(in: cell)
			return cell
		// Route Type
		case (settingsSectionOffset, 3):
			let cell = tableView.dequeueReusableCell(withIdentifier: "routeType", for: indexPath)
			setRouteType(in: cell)
			return cell
		// Source Code
		case (settingsSectionOffset + 1, 0):
			return tableView.dequeueReusableCell(withIdentifier: "sourceCode", for: indexPath)
		// Contacts
		case (settingsSectionOffset + 1, 1):
			return tableView.dequeueReusableCell(withIdentifier: "contact", for: indexPath)
		// Remove Ads
		case (0, 0):
			if InAppPurchaseManager.canMakePayments {
				return tableView.dequeueReusableCell(withIdentifier: "removeAds", for: indexPath)
			} else {
				fallthrough
			}
		// Manage consent
		case (0, 1):
			return tableView.dequeueReusableCell(withIdentifier: "manageConsent", for: indexPath)
		
		default:
			return UITableViewCell()
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch (indexPath.section, indexPath.row) {
		case (settingsSectionOffset, _):
			// This is required to avoid calling ads stuff when they are disabled
			break
		case (settingsSectionOffset + 1, 0):
			let url = URL(string: "https://github.com/piscoTech/Workout")!
			UIApplication.shared.open(url)
		case (0, 1):
			adsManager.collectAdsConsent()
		case (0, 0) where !InAppPurchaseManager.canMakePayments:
			adsManager.collectAdsConsent()
		
		default:
			break
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}

	// MARK: - Preferences Updated

	func preferredSystemOfUnitsChanged() {
		if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: settingsSectionOffset)) {
			setUnits(in: cell)
		}
	}

	func stepSourceChanged() {
		if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: settingsSectionOffset)) {
			setStepSource(in: cell)
		}
	}

	func runningHeartZonesConfigChanged() {
		if let cell = tableView.cellForRow(at: IndexPath(row: 2, section: settingsSectionOffset)) {
			setMaxHeartRate(in: cell)
		}
	}

	func routeTypeChanged() {
		if let cell = tableView.cellForRow(at: IndexPath(row: 3, section: settingsSectionOffset)) {
			setRouteType(in: cell)
		}
	}

	private func setUnits(in cell: UITableViewCell) {
		cell.detailTextLabel?.text = preferences.systemOfUnits.displayName
	}
	
	private func setStepSource(in cell: UITableViewCell) {
		cell.detailTextLabel?.text = preferences.stepSourceFilter.displayName
	}
	
	private func setMaxHeartRate(in cell: UITableViewCell) {
		let s: String?
		if let hr = preferences.maxHeartRate {
			let hrQuantity = HKQuantity(unit: WorkoutUnit.heartRate.default, doubleValue: Double(hr))
			s = String(format: maxHeart, hrQuantity.formatAsHeartRate(withUnit: WorkoutUnit.heartRate.unit(for: preferences.systemOfUnits)))
		} else {
			s = nil
		}
		cell.detailTextLabel?.text = s
	}

	private func setRouteType(in cell: UITableViewCell) {
		cell.detailTextLabel?.text = preferences.routeType.displayName
	}
	
	// MARK: - Ads management
	
	@IBAction func removeAds() {
		adsManager.removeAds()
	}
	
	@IBAction func restorePurchase() {
		adsManager.restorePurchase()
	}
	
	func hideAds() {
		let old = tableView.numberOfSections
		let new = self.numberOfSections(in: tableView)
		guard !adsManager.areAdsEnabled, old > new else {
			// Rows already hidden or should not be hidden
			return
		}
		
		tableView.deleteSections(IndexSet(0 ..< old - new), with: .automatic)
	}
	
	// MARK: - Navigation
	
	@IBAction func done(_ sender: AnyObject) {
		dismiss(animated: true, completion: nil)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let segueID = segue.identifier else {
			return
		}
		
		switch segueID {
		case "contact":
			let dest = (segue.destination as! UINavigationController).topViewController as! ContactMeViewController
			dest.appName = "Workout"
		default:
			break
		}
	}
	
}
