//
//  ListTableViewController.swift
//  Workout
//
//  Created by Marco Boschi on 15/01/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit
import MBLibrary
import GoogleMobileAds
import PersonalizedAdConsent

class ListTableViewController: UITableViewController, GADBannerViewDelegate, WorkoutDelegate {
	
	private var workouts: [Workout]!
	private var err: Error?
	
	private var standardRightBtns: [UIBarButtonItem]!
	@IBOutlet weak var enterExportModeBtn: UIBarButtonItem!
	private var standardLeftBtn: UIBarButtonItem!
	private var exportRightBtns: [UIBarButtonItem]!
	private var exportLeftBtn: UIBarButtonItem!
	private var exportToggleBtn: UIBarButtonItem!
	private var exportCommitBtn: UIBarButtonItem!
	private var exportSelection: [Bool]!
	
	private var inExportMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
		
		if #available(iOS 11, *) {
			self.navigationController?.navigationBar.prefersLargeTitles = true
			self.navigationItem.largeTitleDisplayMode = .always
		}
		
		NotificationCenter.default.addObserver(self, selector: #selector(transactionUpdated(_:)), name: InAppPurchaseManager.transactionNotification, object: nil)
		standardRightBtns = navigationItem.rightBarButtonItems
		standardLeftBtn = navigationItem.leftBarButtonItem
		
		exportToggleBtn = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(toggleExportAll(_:)))
		exportCommitBtn = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(doExport(_:)))
		exportRightBtns = [exportCommitBtn, exportToggleBtn]
		exportLeftBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelExport(_:)))

        refresh()
		initializeAds()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if !preferences.bool(forKey: PreferenceKey.authorized) || preferences.integer(forKey: PreferenceKey.authVersion) < authRequired {
			authorize(self)
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@IBAction func doRefresh(_ sender: AnyObject) {
		refresh()
	}
	
	private func refresh() {
		workouts = nil
		err = nil
		if HKHealthStore.isHealthDataAvailable() {
			tableView.reloadData()
	
			let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
			let type = HKObjectType.workoutType()
			let workoutQuery = HKSampleQuery(sampleType: type, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (_, r, err) in
				//There's no need to call .load() as additional data is not needed here, we just need information about units
				let wrkts = (r as? [HKWorkout])?.map { Workout.workoutFor(raw: $0) }
				
				DispatchQueue.main.async {
					self.workouts = wrkts
					self.err = err
					self.updateExportModeEnabled()
					self.tableView.reloadData()
				}
			}
			
			healthStore.execute(workoutQuery)
		} else {
			tableView.reloadData()
		}
		
		updateExportModeEnabled()
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(workouts?.count ?? 1, 1)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if workouts?.count ?? 0 == 0 {
			let res = tableView.dequeueReusableCell(withIdentifier: "msg", for: indexPath)
			let msg: String
			if HKHealthStore.isHealthDataAvailable() {
				if err != nil {
					msg = "ERR_LOADING"
				} else if workouts != nil {
					msg = "ERR_NO_WORKOUT"
				} else {
					msg = "LOADING"
				}
			} else {
				msg = "ERR_NO_HEALTH"
			}
			res.textLabel?.text = NSLocalizedString(msg, comment: "Loading/Error")
			
			return res
		}

		let cell = tableView.dequeueReusableCell(withIdentifier: "workout", for: indexPath)
		let w = workouts[indexPath.row]
		
		cell.textLabel?.text = w.type.name
		
		var detail = [w.startDate.getFormattedDateTime(), w.duration.getDuration() ]
		if let dist = w.totalDistance?.getFormattedDistance(withUnit: w.distanceUnit) {
			detail.append(dist)
		}
		cell.detailTextLabel?.text = detail.joined(separator: " – ")
		
		if inExportMode {
			cell.accessoryType = exportSelection[indexPath.row] ? .checkmark : .none
		} else {
			cell.accessoryType = .disclosureIndicator
		}

        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if inExportMode {
			let newSel = !exportSelection[indexPath.row]
			exportSelection[indexPath.row] = newSel
			
			if let cell = tableView.cellForRow(at: indexPath) {
				cell.accessoryType = newSel ? .checkmark : .none
			}
			
			updateToggleExportAllText()
			updateExportCommitButton()
		} else {
			performSegue(withIdentifier: "showWorkout", sender: self)
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	func authorize(_ sender: AnyObject) {
		healthStore.requestAuthorization(toShare: nil, read: healthReadData) { (success, _) in
			if success {
				preferences.set(true, forKey: PreferenceKey.authorized)
				preferences.set(authRequired, forKey: PreferenceKey.authVersion)
				preferences.synchronize()
			}
			
			DispatchQueue.main.async {
				self.refresh()
			}
		}
	}
	
	// MARK: - Export all workouts
	
	private var documentController: UIActivityViewController!
	private var exportWorkouts = [Workout]()
	private var waitingForExport = 0
	private var loadingBar: UIAlertController?
	private weak var loadingProgress: UIProgressView?
	
	@IBAction func chooseExport(_ sender: AnyObject) {
		inExportMode = true
		
		exportToggleBtn.title = NSLocalizedString("SEL_EXPORT_NONE", comment: "Select None")
		exportSelection = [Bool](repeating: true, count: workouts?.count ?? 0)
		updateExportCommitButton()
		
		navigationItem.leftBarButtonItem = exportLeftBtn
		navigationItem.rightBarButtonItems = exportRightBtns
		
		for i in 0 ..< (workouts?.count ?? 0) {
			if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) {
				cell.accessoryType = .checkmark
			}
		}
	}
	
	@objc func doExport(_ sender: UIBarButtonItem) {
		loadingBar?.dismiss(animated: false)
		
		DispatchQueue.userInitiated.async {
			self.exportWorkouts = []
			self.waitingForExport = self.exportSelection.map { $0 ? 1 : 0 }.reduce(0) { $0 + $1 }
			
			guard self.waitingForExport > 0 else {
				return
			}
			
			DispatchQueue.main.async {
				let (bar, progress) = UIAlertController.getModalProgress()
				self.loadingBar = bar
				self.loadingProgress = progress
				self.present(self.loadingBar!, animated: true)
			}
			
			for (w, e) in zip(self.workouts, self.exportSelection) {
				if e {
					let workout = Workout.workoutFor(raw: w.raw, delegate: self)
					//Avoid loading additional (and unused) detail
					workout.load(quickLoad: true)
					self.exportWorkouts.append(workout)
				}
			}
		}
	}
	
	@objc func cancelExport(_ sender: AnyObject) {
		inExportMode = false
		
		navigationItem.leftBarButtonItem = standardLeftBtn
		navigationItem.rightBarButtonItems = standardRightBtns
		
		for i in 0 ..< (workouts?.count ?? 0) {
			if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) {
				cell.accessoryType = .disclosureIndicator
			}
		}
	}
	
	@objc func toggleExportAll(_ sender: AnyObject) {
		let newVal: Bool
		let newText: String
		
		if exportSelection?.index(of: false) == nil {
			newVal = false
			newText = "ALL"
		} else {
			newVal = true
			newText = "NONE"
		}
		
		exportToggleBtn.title = NSLocalizedString("SEL_EXPORT_" + newText, comment: "Select")
		exportSelection = [Bool](repeating: newVal, count: exportSelection?.count ?? 0)
		updateExportCommitButton()
		
		for i in 0 ..< (workouts?.count ?? 0) {
			if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) {
				cell.accessoryType = newVal ? .checkmark : .none
			}
		}
	}
	
	private func updateExportCommitButton() {
		exportCommitBtn.isEnabled = (exportSelection ?? []).index(of: true) != nil
	}
	
	private func updateToggleExportAllText() {
		exportToggleBtn.title = NSLocalizedString("SEL_EXPORT_" + (exportSelection?.index(of: false) == nil ? "NONE" : "ALL"), comment: "Select")
	}
	
	private func updateExportModeEnabled() {
		enterExportModeBtn.isEnabled = (workouts?.count ?? 0) > 0
	}
	
	func dataIsReady() {
		//Move to a serial queue to synchronize access to counter
		DispatchQueue.workout.async {
			self.waitingForExport -= 1
			DispatchQueue.main.async {
				let total = self.exportWorkouts.count
				self.loadingProgress?.setProgress(Float(total - self.waitingForExport) / Float(total), animated: true)
			}
			
			if self.waitingForExport == 0 {
				let filePath = URL(fileURLWithPath: NSString(string: NSTemporaryDirectory()).appendingPathComponent("allWorkouts.csv"))
				let displayError = {
					let alert = UIAlertController(simpleAlert: NSLocalizedString("CANNOT_EXPORT", comment: "Export error"), message: nil)
					
					DispatchQueue.main.async {
						if let l = self.loadingBar {
							l.dismiss(animated: true) {
								self.loadingBar = nil
								self.present(alert, animated: true)
							}
						} else {
							self.present(alert, animated: true)
						}
					}
				}
				
				let sep = CSVSeparator
				var data = "Type\(sep)Start\(sep)End\(sep)Duration\(sep)Distance\(sep)\("Average Heart Rate".toCSV())\(sep)\("Max Heart Rate".toCSV())\(sep)\("Average Pace".toCSV())\(sep)\("Average Speed".toCSV())\(sep)\("Active Energy kcal".toCSV())\(sep)\("Total Energy kcal".toCSV())\n"
				for w in self.exportWorkouts {
					if w.hasError {
						displayError()
						return
					}
					
					data += w.exportGeneralData() + "\n"
				}
				
				DispatchQueue.main.async {
					self.cancelExport(self)
				}
				
				do {
					try data.write(to: filePath, atomically: true, encoding: .utf8)
					
					self.exportWorkouts = []
					self.documentController = UIActivityViewController(activityItems: [filePath], applicationActivities: nil)
					
					DispatchQueue.main.async {
						if let l = self.loadingBar {
							l.dismiss(animated: true) {
								self.loadingBar = nil
								self.present(self.documentController, animated: true)
							}
						} else {
							self.present(self.documentController, animated: true)
						}
						
						self.documentController.popoverPresentationController?.barButtonItem = self.exportCommitBtn
					}
				} catch _ {
					displayError()
				}
			}
		}
	}
	
	// MARK: - Ads stuff
	
	private var adView: GADBannerView!
	private var adRetryDelay = 1.0
	private var allowPersonalizedAds = true
	
	private func initializeAds() {
		navigationController?.isToolbarHidden = true
		
		guard areAdsEnabled else {
			return
		}
		
		PACConsentInformation.sharedInstance.requestConsentInfoUpdate(forPublisherIdentifiers: [adsID]) { err in
			if err != nil {
				DispatchQueue.main.asyncAfter(delay: self.adRetryDelay, closure: self.initializeAds)
			} else {
				if PACConsentInformation.sharedInstance.isRequestLocationInEEAOrUnknown {
					let consent = PACConsentInformation.sharedInstance.consentStatus
					if consent == .unknown {
						DispatchQueue.main.async {
							self.collectAdsConsent()
						}
					} else {
						self.allowPersonalizedAds = consent == .personalized
						DispatchQueue.main.async {
							self.loadAd()
						}
					}
				} else {
					self.allowPersonalizedAds = true
					DispatchQueue.main.async {
						self.loadAd()
					}
				}
			}
		}
	}
	
	private func collectAdsConsent() {
		guard let privacyUrl = URL(string: "https://github.com/piscoTech/Workout/blob/master/PRIVACY.md"),
			let form = PACConsentForm(applicationPrivacyPolicyURL: privacyUrl) else {
			fatalError("Incorrect privacy URL.")
		}
		
		form.shouldOfferPersonalizedAds = true
		form.shouldOfferNonPersonalizedAds = true
		form.shouldOfferAdFree = true
		
		form.load { err in
			if err != nil {
				DispatchQueue.main.asyncAfter(delay: self.adRetryDelay, closure: self.initializeAds)
			} else {
				DispatchQueue.main.async {
					form.present(from: self) { err, adsFree in
						if err != nil {
							DispatchQueue.main.asyncAfter(delay: self.adRetryDelay, closure: self.initializeAds)
						} else {
							self.allowPersonalizedAds = !adsFree && PACConsentInformation.sharedInstance.consentStatus == .personalized
							DispatchQueue.main.async {
								self.loadAd()
								if adsFree {
									self.performSegue(withIdentifier: "info", sender: self)
								}
							}
						}
					}
				}
			}
		}
	}
	
	private func loadAd() {
		adView = GADBannerView(adSize: kGADAdSizeBanner)
		adView.translatesAutoresizingMaskIntoConstraints = false
		adView.rootViewController = self
		adView.delegate = self
		adView.adUnitID = adsID
		
		adView.load(getAdRequest())
		navigationController?.toolbar.addSubview(adView)
		var constraint = NSLayoutConstraint(item: adView, attribute: .centerX, relatedBy: .equal, toItem: navigationController!.toolbar, attribute: .centerX, multiplier: 1, constant: 0)
		constraint.isActive = true
		constraint = NSLayoutConstraint(item: adView, attribute: .top, relatedBy: .equal, toItem: navigationController!.toolbar, attribute: .top, multiplier: 1, constant: 0)
		constraint.isActive = true
	}
	
	func adViewDidReceiveAd(_ bannerView: GADBannerView) {
		guard areAdsEnabled else {
			return
		}
		
		//Display ad
		navigationController?.setToolbarHidden(false, animated: true)
	}
	
	func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
		//Remove ad view
		DispatchQueue.main.asyncAfter(delay: adRetryDelay) {
			self.adView.load(self.getAdRequest())
			self.adRetryDelay *= 2
		}
	}
	
	@objc func transactionUpdated(_ not: NSNotification) {
		guard let transaction = not.object as? TransactionStatus, transaction.product == removeAdsId else {
			return
		}
		
		if transaction.status.isSuccess() {
			DispatchQueue.main.async {
				self.terminateAds()
			}
		}
	}
	
	func terminateAds() {
		guard adView != nil else {
			//Ads already removed
			return
		}

		navigationController?.setToolbarHidden(false, animated: false)
		navigationController?.setToolbarHidden(true, animated: true)
		DispatchQueue.main.asyncAfter(delay: 2) {
			self.adView?.removeFromSuperview()
			self.adView = nil
		}
	}
	
	private func getAdRequest() -> GADRequest {
		let req = GADRequest()
		if !allowPersonalizedAds {
			let extras = GADExtras()
			extras.additionalParameters = ["npa": "1"]
			req.register(extras)
		}
		return req
	}

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let id = segue.identifier else {
			return
		}
		
		switch id {
		case "showWorkout":
			if let dest = segue.destination as? WorkoutTableViewController, let indexPath = tableView.indexPathForSelectedRow {
				dest.rawWorkout = workouts[indexPath.row].raw
			}
		case "info":
			if let dest = segue.destination as? UINavigationController, let root = dest.topViewController as? AboutViewController {
				root.delegate = self
			}
		default:
			return
		}
    }

}
