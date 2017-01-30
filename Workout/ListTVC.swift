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

class ListTableViewController: UITableViewController, GADBannerViewDelegate, WorkoutDelegate {
	
	private var workouts: [HKWorkout]!
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
		if HKHealthStore.isHealthDataAvailable() {
			workouts = nil
			err = nil
			tableView.reloadData()
	
			let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
			let type = HKObjectType.workoutType()
			let predicate =  HKQuery.predicateForWorkouts(with: .running)
			let workoutQuery = HKSampleQuery(sampleType: type, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { (_, r, err) in
				self.workouts = nil
				self.err = err
				if let res = r as? [HKWorkout] {
					self.workouts = res
				}
				
				DispatchQueue.main.async {
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
        return workouts?.count ?? 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if workouts == nil {
			let res = tableView.dequeueReusableCell(withIdentifier: "msg", for: indexPath)
			let msg: String
			if HKHealthStore.isHealthDataAvailable() {
				msg = err == nil ? "LOADING" : "ERR_LOADING"
			} else {
				msg = "ERR_NO_HEALTH"
			}
			res.textLabel?.text = NSLocalizedString(msg, comment: "Loading/Error")
			
			return res
		}

		let cell = tableView.dequeueReusableCell(withIdentifier: "workout", for: indexPath)
		let w = workouts[indexPath.row]
		
		cell.textLabel?.text = w.startDate.getFormattedDateTime()
		
		var detail = w.duration.getDuration()
		if let dist = w.totalDistance {
			detail += " - " + (dist.doubleValue(for: .meter()) / 1000).getFormattedDistance()
		}
		cell.detailTextLabel?.text = detail
		
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
		} else {
			performSegue(withIdentifier: "showWorkout", sender: self)
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	func authorize(_ sender: AnyObject) {
		healthStore.requestAuthorization(toShare: nil, read: [
			HKObjectType.workoutType(),
			HKObjectType.quantityType(forIdentifier: .heartRate)!,
			HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
			HKObjectType.quantityType(forIdentifier: .stepCount)!
		]) { (success, _) in
			if success {
				preferences.set(true, forKey: PreferenceKey.authorized)
				preferences.set(authRequired, forKey: PreferenceKey.authVersion)
				preferences.synchronize()
			}
			
			self.refresh()
		}
	}
	
	// MARK: - Export all workouts
	
	private var documentController: UIActivityViewController!
	private var exportWorkouts = [Workout]()
	private var waitingForExport = 0
	
	@IBAction func chooseExport(_ sender: AnyObject) {
		inExportMode = true
		
		exportToggleBtn.title = NSLocalizedString("SEL_EXPORT_NONE", comment: "Select None")
		exportSelection = [Bool](repeating: true, count: workouts?.count ?? 0)
		
		navigationItem.leftBarButtonItem = exportLeftBtn
		navigationItem.rightBarButtonItems = exportRightBtns
		
		for i in 0 ..< (workouts?.count ?? 0) {
			if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) {
				cell.accessoryType = .checkmark
			}
		}
	}
	
	func doExport(_ sender: UIBarButtonItem) {
		DispatchQueue.userInitiated.async {
			self.exportWorkouts = []
			
			self.waitingForExport = self.exportSelection.map { $0 ? 1 : 0 }.reduce(0) { $0 + $1 }
			for (w, e) in zip(self.workouts, self.exportSelection) {
				if e {
					self.exportWorkouts.append(Workout(w, delegate: self))
				}
			}
		}
	}
	
	func cancelExport(_ sender: AnyObject) {
		inExportMode = false
		
		navigationItem.leftBarButtonItem = standardLeftBtn
		navigationItem.rightBarButtonItems = standardRightBtns
		
		for i in 0 ..< (workouts?.count ?? 0) {
			if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) {
				cell.accessoryType = .disclosureIndicator
			}
		}
	}
	
	func toggleExportAll(_ sender: AnyObject) {
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
		
		for i in 0 ..< (workouts?.count ?? 0) {
			if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) {
				cell.accessoryType = newVal ? .checkmark : .none
			}
		}
	}
	
	private func updateToggleExportAllText() {
		exportToggleBtn.title = NSLocalizedString("SEL_EXPORT_" + (exportSelection?.index(of: false) == nil ? "NONE" : "ALL"), comment: "Select")
	}
	
	private func updateExportModeEnabled() {
		enterExportModeBtn.isEnabled = (workouts?.count ?? 0) > 0
	}
	
	func dataIsReady() {
		waitingForExport -= 1;
		
		if waitingForExport == 0 {
			let filePath = URL(fileURLWithPath: NSString(string: NSTemporaryDirectory()).appendingPathComponent("allWorkouts.csv"))
			let displayError = {
				let alert = UIAlertController(simpleAlert: NSLocalizedString("CANNOT_EXPORT", comment: "Export error"), message: nil)
				
				DispatchQueue.main.async {
					self.present(alert, animated: true, completion: nil)
				}
			}
			
			var data = "Start\(CSVSeparator)End\(CSVSeparator)Duration\(CSVSeparator)Distance\(CSVSeparator)\("Average Heart Rate".toCSV())\(CSVSeparator)\("Max Heart Rate".toCSV())\(CSVSeparator)\("Average Pace".toCSV())\n"
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
				
				self.documentController = UIActivityViewController(activityItems: [filePath], applicationActivities: nil)
				
				DispatchQueue.main.async {
					self.present(self.documentController, animated: true, completion: nil)
					self.documentController.popoverPresentationController?.barButtonItem = self.exportCommitBtn
				}
			} catch _ {
				displayError()
			}
		}
	}
	
	// MARK: - Ads stuff
	
	private var adView: GADBannerView!
	private var adRetryDelay = 1.0
	
	private func initializeAds() {
		navigationController?.isToolbarHidden = true
		
		guard areAdsEnabled else {
			return
		}
		
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
	
	func transactionUpdated(_ not: NSNotification) {
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
		req.testDevices = [kGADSimulatorID]
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
				dest.rawWorkout = workouts[indexPath.row]
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
