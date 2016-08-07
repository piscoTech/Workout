//
//  InfoViewController.swift
//  Matrix
//
//  Created by Marco Boschi on 03/11/14.
//  Copyright (c) 2014 Marco Boschi. All rights reserved.
//

import UIKit

class AboutViewController: UITableViewController {
	
	private var appInfo: String!
	var delegate: ListTableViewController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let appVers = Bundle.main.objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
		let build = Bundle.main.objectForInfoDictionaryKey("CFBundleVersion") as! String

		appInfo = "Report any problem on Twitter @piscoTech or at GitHub tapping Source Code.\nWorkout v\(appVers) (\(build))\n© 2016 Marco Boschi"
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
			UIApplication.shared().openURL(URL(string: "https://github.com/piscoTech/Workout")!)
		default:
			break
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	// MARK: - Ads management
	
	@IBAction func removeAds() {
		guard areAdsEnabled else {
			return
		}
		
		let loading = UIAlertController.getModalLoading()
		present(loading, animated: true, completion: nil)
		
		let buy: () -> () = {
			iapManager.buyProduct(pId: removeAdsId) { (success, error) in
				print("Ads removed: \(success)")
				
				DispatchQueue.main.async {
					loading.dismiss(animated: true, completion: nil)
					self.deleteRemoveAdsRow()
					if(success) {
						self.delegate.terminateAds()
					}
				}
			}
		}
		
		if !iapManager.areProductsLoaded {
			iapManager.loadProducts(completion: { (success, _) in
				if !success {
					DispatchQueue.main.async {
						loading.dismiss(animated: true, completion: nil)
						//TODO: Display error on view
						print("Unable to load products")
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
		iapManager.restorePurchases(productCompletion: [removeAdsId: { (success, error) in
			print("Ads removed: \(success)")
			
			DispatchQueue.main.async {
				self.deleteRemoveAdsRow()
				if(success) {
					self.delegate.terminateAds()
				}
			}
		}])
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
