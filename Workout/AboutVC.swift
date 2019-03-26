//
//  InfoViewController.swift
//  Matrix
//
//  Created by Marco Boschi on 03/11/14.
//  Copyright (c) 2014 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary
import PersonalizedAdConsent

class AboutViewController: UITableViewController {
	
	private var appInfo: String!
	private let maxHeart = NSLocalizedString("HEART_ZONES_MAX_RATE", comment: "Max x bpm")
	var delegate: ListTableViewController!
	
	private var numberOfRowsInAdsSection: Int {
		var count = 0
		if areAdsEnabled {
			if iapManager.canMakePayments {
				count += 1 // Remove Ads & Restore
			}
			
			if PACConsentInformation.sharedInstance.isRequestLocationInEEAOrUnknown {
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

		appInfo = NSLocalizedString("REPORT_TEXT", comment: "Report problem") + "\n\nWorkout \(Bundle.main.versionDescription)\n© 2016-2018 Marco Boschi"
		
		NotificationCenter.default.addObserver(self, selector: #selector(transactionUpdated(_:)), name: InAppPurchaseManager.transactionNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(restoreCompleted(_:)), name: InAppPurchaseManager.restoreNotification, object: nil)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
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
			return 3
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
		// Source Code
		case (settingsSectionOffset + 1, 0):
			return tableView.dequeueReusableCell(withIdentifier: "sourceCode", for: indexPath)
		// Contacts
		case (settingsSectionOffset + 1, 1):
			return tableView.dequeueReusableCell(withIdentifier: "contact", for: indexPath)
		// Remove Ads
		case (0, 0):
			if iapManager.canMakePayments {
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
			manageConsent()
		case (0, 0) where !iapManager.canMakePayments:
			manageConsent()
		
		default:
			break
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	func updateUnits() {
		delegate.refreshUnits()
		if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: settingsSectionOffset)) {
			setUnits(in: cell)
		}
	}
	
	func updateStepSource() {
		if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: settingsSectionOffset)) {
			setStepSource(in: cell)
		}
	}
	
	func updateMaxHeartRate() {
		if let cell = tableView.cellForRow(at: IndexPath(row: 2, section: settingsSectionOffset)) {
			setMaxHeartRate(in: cell)
		}
	}
	
	private func setUnits(in cell: UITableViewCell) {
		cell.detailTextLabel?.text = Preferences.systemOfUnits.displayName
	}
	
	private func setStepSource(in cell: UITableViewCell) {
		cell.detailTextLabel?.text = Preferences.stepSourceFilter.displayName
	}
	
	private func setMaxHeartRate(in cell: UITableViewCell) {
		let s: String?
		if let hr = Preferences.maxHeartRate {
			s = String(format: maxHeart, Double(hr).getFormattedHeartRate())
		} else {
			s = nil
		}
		cell.detailTextLabel?.text = s
	}
	
	// MARK: - Ads management
	
	private var loading: UIAlertController?
	
	private func manageConsent() {
		guard PACConsentInformation.sharedInstance.isRequestLocationInEEAOrUnknown else {
			return
		}
		
		loading = UIAlertController.getModalLoading()
		self.present(loading!, animated: true)
		
		func displayError() {
			DispatchQueue.main.async {
				let alert = UIAlertController(simpleAlert: NSLocalizedString("MANAGE_CONSENT", comment: "Manage consent"), message: NSLocalizedString("MANAGE_CONSENT_ERR", comment: "Manage consent error"))
				
				if let l = self.loading {
					l.dismiss(animated: true) {
						self.present(alert, animated: true)
					}
				} else {
					self.present(alert, animated: true)
				}
			}
		}
		
		let form = delegate.getAdsConsentForm(shouldOfferAdFree: false)
		form.load { err in
			if err != nil {
				displayError()
			} else {
				DispatchQueue.main.async {
					func presentForm() {
						form.present(from: self) { err, _ in
							if err != nil {
								displayError()
							} else {
								DispatchQueue.main.async {
									let personalized = PACConsentInformation.sharedInstance.consentStatus == .personalized
									self.delegate.adConsentChanged(allowPersonalized: personalized)
								}
							}
						}
					}
					
					if let l = self.loading {
						l.dismiss(animated: true) {
							presentForm()
						}
					} else {
						presentForm()
					}
				}
			}
		}
	}
	
	@IBAction func removeAds() {
		guard areAdsEnabled else {
			return
		}
		
		loading = UIAlertController.getModalLoading()
		present(loading!, animated: true, completion: nil)
		
		let buy = {
			if !iapManager.buyProduct(pId: removeAdsId) {
				if let load = self.loading {
					load.dismiss(animated: true) {
						self.loading = nil
						self.present(InAppPurchaseManager.getProductListError(), animated: true)
					}
				} else {
					self.present(InAppPurchaseManager.getProductListError(), animated: true)
				}
			}
		}
		
		if !iapManager.areProductsLoaded {
			iapManager.loadProducts(completion: { (success, _) in
				if !success {
					DispatchQueue.main.async {
						if let load = self.loading {
							load.dismiss(animated: true) {
								self.loading = nil
								self.present(InAppPurchaseManager.getProductListError(), animated: true)
							}
						} else {
							self.present(InAppPurchaseManager.getProductListError(), animated: true)
						}
					}
				} else {
					buy()
				}
			})
		} else {
			buy()
		}
	}
	
	@IBAction func restorePurchase() {
		loading = UIAlertController.getModalLoading()
		present(loading!, animated: true, completion: nil)
		
		iapManager.restorePurchases()
	}
	
	@objc func transactionUpdated(_ not: NSNotification) {
		guard let transaction = not.object as? TransactionStatus, transaction.product == removeAdsId else {
			return
		}
		
		DispatchQueue.main.async {
			var alert: UIAlertController?
			if let err = transaction.error {
				alert = InAppPurchaseManager.getAlert(forError: err)
			} else if transaction.status == .restored {
				alert = UIAlertController(simpleAlert: NSLocalizedString("REMOVE_ADS", comment: "Ads"), message: MBLocalizedString("PURCHASE_RESTORED", comment: "Restored"))
			}
			
			self.deleteRemoveAdsRows()
			if let load = self.loading {
				load.dismiss(animated: true) {
					self.loading = nil
					if let a = alert {
						self.present(a, animated: true)
					}
				}
			} else if let a = alert {
				self.present(a, animated: true)
			}
		}
	}
	
	@objc func restoreCompleted(_ not: NSNotification) {
		guard let status = not.object as? RestorationStatus else {
			return
		}

		DispatchQueue.main.async {
			if let err = status.error {
				guard let alert = InAppPurchaseManager.getAlert(forError: err) else {
					self.loading?.dismiss(animated: true) {
						self.loading = nil
					}
					
					return
				}
				
				if let load = self.loading {
					load.dismiss(animated: true) {
						self.loading = nil
						self.present(alert, animated: true)
					}
				} else {
					self.present(alert, animated: true)
				}
			} else if status.restored == 0 {
				// Nothing has been restored
				self.loading?.dismiss(animated: true) {
					self.loading = nil
				}
			}
		}
	}
	
	private func deleteRemoveAdsRows() {
		let old = tableView.numberOfSections
		let new = self.numberOfSections(in: tableView)
		guard !areAdsEnabled, old > new else {
			// Rows already hidden
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
		case "units":
			let dest = segue.destination as! UnitsTableViewController
			dest.delegate = self
		case "stepSource":
			let dest = segue.destination as! StepSourceTableViewController
			dest.delegate = self
		case "heartZones":
			let dest = segue.destination as! RunningHeartZonesTableViewController
			dest.delegate = self
		case "contact":
			let dest = (segue.destination as! UINavigationController).topViewController as! ContactMeViewController
			dest.appName = "Workout"
		default:
			break
		}
	}
	
}
