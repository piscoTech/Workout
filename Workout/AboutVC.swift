//
//  InfoViewController.swift
//  Matrix
//
//  Created by Marco Boschi on 03/11/14.
//  Copyright (c) 2014 Marco Boschi. All rights reserved.
//

import UIKit
import MBLibrary

class AboutViewController: UITableViewController {
	
	private var appInfo: String!
	var delegate: ListTableViewController!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		appInfo = NSLocalizedString("REPORT_TEXT", comment: "Report problem") + "\n\nWorkout \(Bundle.main.versionDescription)\n© 2016-2017 Marco Boschi"
		
		NotificationCenter.default.addObserver(self, selector: #selector(transactionUpdated(_:)), name: InAppPurchaseManager.transactionNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(restoreCompleted(_:)), name: InAppPurchaseManager.restoreNotification, object: nil)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if section == 1 {
			return appInfo
		}
		
		return nil
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return areAdsEnabled && iapManager.canMakePayments ? 2 : 1
		case 1:
			return 1
		default:
			return 0
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch (indexPath.section, indexPath.row) {
		case (0, 0):
			return tableView.dequeueReusableCell(withIdentifier: "authorize", for: indexPath)
		case (0, 1):
			return tableView.dequeueReusableCell(withIdentifier: "removeAds", for: indexPath)
		case (1, 0):
			return tableView.dequeueReusableCell(withIdentifier: "sourceCode", for: indexPath)
		default:
			return UITableViewCell()
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch (indexPath.section, indexPath.row) {
		case (0, 0):
			delegate.authorize(self)
		case (1, 0):
			UIApplication.shared.openURL(URL(string: "https://github.com/piscoTech/Workout")!)
		default:
			break
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	// MARK: - Ads management
	
	var loading: UIAlertController?
	
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
	
	func transactionUpdated(_ not: NSNotification) {
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
			
			self.deleteRemoveAdsRow()
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
	
	func restoreCompleted(_ not: NSNotification) {
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
			} else if status.restored! == 0 {
				// Nothing has been restored
				self.loading?.dismiss(animated: true) {
					self.loading = nil
				}
			}
		}
	}
	
	private func deleteRemoveAdsRow() {
		let adsIndex = IndexPath(row: 1, section: 0)
		
		guard !areAdsEnabled, let _ = tableView.cellForRow(at: adsIndex) else {
			return
		}
		
		tableView.deleteRows(at: [adsIndex], with: .automatic)
	}
	
	// MARK: - Navigation
	
	@IBAction func done(_ sender: AnyObject) {
		dismiss(animated: true, completion: nil)
	}
	
}
