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
import StoreKit

class ListTableViewController: UITableViewController, GADBannerViewDelegate, WorkoutDelegate, EnhancedNavigationBarDelegate {
	
	private let batchSize = 40
	private let filteredLoadMultiplier = 5
	private var moreToBeLoaded = true
	private var isLoadingMore = false
	
	private var allWorkouts: [Workout]!
	private var displayWorkouts: [Workout]!
	private var err: Error?
	
	private var standardRightBtns: [UIBarButtonItem]!
	@IBOutlet private weak var enterExportModeBtn: UIBarButtonItem!
	private var standardLeftBtn: UIBarButtonItem!
	
	private var exportRightBtns: [UIBarButtonItem]!
	private var exportLeftBtn: UIBarButtonItem!
	
	private var exportToggleBtn: UIBarButtonItem!
	private var exportCommitBtn: UIBarButtonItem!
	private var exportSelection: [Bool]!
	
	private var inExportMode = false
	
	private var heightFixed = false
	private var titleLblShouldHide = false
	@IBOutlet private var titleView: UIView!
	@IBOutlet private weak var titleLbl: UILabel!
	@IBOutlet private weak var filterLbl: UILabel!
	
	private var loaded = false

    override func viewDidLoad() {
        super.viewDidLoad()
		
		let navBar = navigationController?.navigationBar as? EnhancedNavigationBar
		titleLbl.text = self.navigationItem.title
		filterLbl.textColor = navBar?.tintColor
		navigationItem.titleView = titleView
		navBar?.enhancedDelegate = self
		updateFilterLabel()
		
		NotificationCenter.default.addObserver(self, selector: #selector(transactionUpdated(_:)), name: InAppPurchaseManager.transactionNotification, object: nil)
		standardRightBtns = navigationItem.rightBarButtonItems
		standardLeftBtn = navigationItem.leftBarButtonItem
		
		exportToggleBtn = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(toggleExportAll(_:)))
		exportCommitBtn = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(doExport(_:)))
		exportRightBtns = [exportCommitBtn, exportToggleBtn]
		exportLeftBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelExport(_:)))

        refresh(self)
		initializeAds()
		
		DispatchQueue.main.async {
			self.checkRequestReview()
		}
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if !heightFixed {
			heightFixed = true
			NSLayoutConstraint(item: titleView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: titleView.frame.height).isActive = true
			titleLbl.isHidden = titleLblShouldHide
		}
		
		if !loaded {
			loaded = true
			authorize()
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	func authorize() {
		let req = {
			healthStore.requestAuthorization(toShare: nil, read: healthReadData) { _, _ in
				DispatchQueue.main.async {
					self.refresh(self)
				}
			}
		}
		
		if #available(iOS 12.0, *) {
			healthStore.getRequestStatusForAuthorization(toShare: [], read: healthReadData) { status, _ in
				if status != .unnecessary {
					req()
				}
			}
		} else {
			req()
		}
	}
	
	func largeTitleChanged(isLarge: Bool) {
		if !heightFixed {
			titleLblShouldHide = isLarge
		} else {
			titleLbl.isHidden = isLarge
		}
	}
	
	func checkRequestReview() {
		if #available(iOS 10.3, *) {
			guard Preferences.reviewRequestCounter >= Preferences.reviewRequestThreshold else {
				return
			}
			
			SKStoreReviewController.requestReview()
		}
	}
	
	// MARK: - Data Loading
	
	private weak var loadMoreCell: LoadMoreCell?
	
	@IBAction func refresh(_ sender: AnyObject) {
		allWorkouts = nil
		displayWorkouts = filter(workouts: allWorkouts)
		err = nil
		isLoadingMore = true
		
		updateExportModeEnabled()
		tableView.beginUpdates()
		tableView.reloadSections([0], with: .automatic)
		if tableView.numberOfSections > 1 {
			tableView.deleteSections([1], with: .automatic)
		}
		tableView.endUpdates()
		
		if HKHealthStore.isHealthDataAvailable() {
			loadBatch(targetDisplayCount: batchSize)
		}
	}
	
	private func loadMore() {
		isLoadingMore = true
		updateExportModeEnabled()
		loadBatch(targetDisplayCount: displayWorkouts.count + batchSize)
	}
	
	private func loadBatch(targetDisplayCount target: Int) {
		let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
		let type = HKObjectType.workoutType()
		let predicate: NSPredicate?
		let limit: Int
		
		if let last = allWorkouts?.last {
			predicate = NSPredicate(format: "%K <= %@", HKPredicateKeyPathStartDate, last.startDate as NSDate)
			let sameDateCount = allWorkouts.count - (allWorkouts.firstIndex { $0.startDate == last.startDate } ?? allWorkouts.count)
			let missing = target - (displayWorkouts?.count ?? 0)
			limit = sameDateCount + min(batchSize, isFiltering ? missing * filteredLoadMultiplier : missing)
		} else {
			predicate = nil
			limit = target
		}
		
		let workoutQuery = HKSampleQuery(sampleType: type, predicate: predicate, limit: limit, sortDescriptors: [sortDescriptor]) { (_, r, err) in
			// There's no need to call .load() as additional data is not needed here, we just need information about units
			let res = r as? [HKWorkout]
			var actions: [() -> Void] = []
			
			self.err = err
			DispatchQueue.workout.async {
				let addedLineCount: Int?
				let loadingMore: Bool
				let wasEmpty: Bool
				
				if let res = res {
					self.moreToBeLoaded = res.count >= limit
					
					var wrkts: [Workout] = []
					do {
						wrkts.reserveCapacity(res.count)
						var addAll = false
						// By searching the reversed collection we reduce comparison as both collections are sorted
						let revLoaded = (self.allWorkouts ?? []).reversed()
						for w in res {
							if addAll || !revLoaded.contains(where: { $0.raw == w }) {
								// Stop searching already loaded workouts when the first new workout is not present.
								addAll = true
								wrkts.append(Workout.workoutFor(raw: w))
							}
						}
					}
					let disp = self.filter(workouts: wrkts) ?? []
					addedLineCount = self.allWorkouts == nil ? nil : disp.count
					
					wasEmpty = (self.displayWorkouts?.count ?? 0) == 0
					self.allWorkouts = (self.allWorkouts ?? []) + wrkts
					self.displayWorkouts = (self.displayWorkouts ?? []) + disp
					
					if self.moreToBeLoaded && self.displayWorkouts.count < target {
						loadingMore = true
						actions.append {
							self.loadBatch(targetDisplayCount: target)
						}
					} else {
						loadingMore = false
						actions.append {
							self.updateExportModeEnabled()
						}
					}
				} else {
					self.moreToBeLoaded = false
					addedLineCount = nil
					loadingMore = false
					wasEmpty = true
					
					self.allWorkouts = nil
					self.displayWorkouts = self.filter(workouts: self.allWorkouts)
					
					actions.append(self.updateExportModeEnabled)
				}
				
				actions.insert({
					self.isLoadingMore = loadingMore
					self.tableView.beginUpdates()
					if let added = addedLineCount {
						if wasEmpty {
							self.tableView.reloadSections([0], with: .automatic)
						} else {
							let oldCount = self.tableView.numberOfRows(inSection: 0)
							self.tableView.insertRows(at: (oldCount ..< (oldCount + added)).map { IndexPath(row: $0, section: 0) }, with: .automatic)
						}
						
						self.loadMoreCell?.isEnabled = !loadingMore
					} else {
						self.tableView.reloadSections([0], with: .automatic)
					}
					
					if self.moreToBeLoaded && self.tableView.numberOfSections == 1 {
						self.tableView.insertSections([1], with: .automatic)
					} else if !self.moreToBeLoaded && self.tableView.numberOfSections > 1 {
						self.tableView.deleteSections([1], with: .automatic)
					}
					self.tableView.endUpdates()
				}, at: 0)
				
				for a in actions {
					DispatchQueue.main.async(execute: a)
				}
			}
		}
		
		healthStore.execute(workoutQuery)
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
		if self.err == nil && self.allWorkouts != nil && self.moreToBeLoaded && !self.inExportMode {
			return 2
		} else {
			return 1
		}
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
        	return max(displayWorkouts?.count ?? 1, 1)
		} else {
			return 1
		}
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 1 {
			let res = tableView.dequeueReusableCell(withIdentifier: "loadMore", for: indexPath) as! LoadMoreCell
			res.isEnabled = !self.isLoadingMore
			loadMoreCell = res
			
			return res
		}
		
		if displayWorkouts?.count ?? 0 == 0 {
			let res = tableView.dequeueReusableCell(withIdentifier: "msg", for: indexPath)
			let msg: String
			if HKHealthStore.isHealthDataAvailable() {
				if err != nil {
					msg = "ERR_LOADING"
				} else if displayWorkouts != nil {
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
		let w = displayWorkouts[indexPath.row]
		
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
		if indexPath.section == 1 {
			if loadMoreCell?.isEnabled ?? false {
				loadMoreCell?.isEnabled = false
				loadMore()
			}
		} else {
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
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	// MARK: - Filter Workouts
	
	private let allFiltersStr = NSLocalizedString("FILTER_ALL", comment: "All")
	private let manyFiltersStr = NSLocalizedString("FILTERS_MANY", comment: "Many")
	
	private func updateFilterLabel() {
		switch filters.count {
		case 0:
			filterLbl.text = allFiltersStr
		case 1:
			filterLbl.text = filters.first?.name
		default:
			filterLbl.text = String(format: manyFiltersStr, filters.count)
		}
	}
	
	var filters: [HKWorkoutActivityType] = [] {
		didSet {
			displayWorkouts = filter(workouts: allWorkouts)
			tableView.reloadSections([0], with: .automatic)
			
			updateFilterLabel()
			updateExportModeEnabled()
		}
	}
	
	var isFiltering: Bool {
		return !filters.isEmpty
	}
	
	private func filter(workouts wrkts: [Workout]?) -> [Workout]? {
		return wrkts?.filter { filters.isEmpty || filters.contains($0.raw.workoutActivityType) }
	}
	
	// MARK: - Export all workouts
	
	private var documentController: UIActivityViewController!
	private var exportWorkouts = [Workout]()
	private var waitingForExport = 0
	private var loadingBar: UIAlertController?
	private weak var loadingProgress: UIProgressView?
	
	@IBAction func chooseExport(_ sender: AnyObject) {
		inExportMode = true
		if tableView.numberOfSections > 1 {
			tableView.deleteSections([1], with: .automatic)
		}
		
		exportToggleBtn.title = NSLocalizedString("SEL_EXPORT_NONE", comment: "Select None")
		exportSelection = [Bool](repeating: true, count: displayWorkouts?.count ?? 0)
		updateExportCommitButton()
		
		navigationItem.leftBarButtonItem = exportLeftBtn
		navigationItem.rightBarButtonItems = exportRightBtns
		
		for i in 0 ..< (displayWorkouts?.count ?? 0) {
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
			
			for (w, e) in zip(self.displayWorkouts, self.exportSelection) {
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
		if moreToBeLoaded && tableView.numberOfSections == 1 {
			tableView.insertSections([1], with: .automatic)
		}
		
		navigationItem.leftBarButtonItem = standardLeftBtn
		navigationItem.rightBarButtonItems = standardRightBtns
		
		for i in 0 ..< (displayWorkouts?.count ?? 0) {
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
		
		for i in 0 ..< (displayWorkouts?.count ?? 0) {
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
		enterExportModeBtn.isEnabled = !isLoadingMore && (displayWorkouts?.count ?? 0) > 0
	}
	
	func dataIsReady() {
		// Move to a serial queue to synchronize access to counter
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
					self.documentController.completionWithItemsHandler = { _, completed, _, _ in
						self.documentController = nil
						
						if completed {
							Preferences.reviewRequestCounter += 1
							self.checkRequestReview()
						}
					}
					
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
	private let defaultAdRetryDelay = 5.0
	private let maxAdRetryDelay = 5 * 60.0
	private var adRetryDelay = 5.0
	private var allowPersonalizedAds = true
	
	private func initializeAds() {
		navigationController?.isToolbarHidden = true
		
		guard areAdsEnabled else {
			return
		}
		
		PACConsentInformation.sharedInstance.requestConsentInfoUpdate(forPublisherIdentifiers: [adsPublisherID]) { err in
			if err != nil {
				DispatchQueue.main.asyncAfter(delay: self.adRetryDelay, closure: self.initializeAds)
				self.adRetryDelay = min(self.maxAdRetryDelay, self.adRetryDelay * 2)
			} else {
				self.adRetryDelay = self.defaultAdRetryDelay
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
	
	func getAdsConsentForm(shouldOfferAdFree: Bool) -> PACConsentForm {
		guard let privacyUrl = URL(string: "https://github.com/piscoTech/Workout/blob/master/PRIVACY.md"),
			let form = PACConsentForm(applicationPrivacyPolicyURL: privacyUrl) else {
				fatalError("Incorrect privacy URL.")
		}
		
		form.shouldOfferPersonalizedAds = true
		form.shouldOfferNonPersonalizedAds = true
		form.shouldOfferAdFree = shouldOfferAdFree && iapManager.canMakePayments
		
		return form
	}
	
	private func collectAdsConsent() {
		let form = getAdsConsentForm(shouldOfferAdFree: true)
		form.load { err in
			if err != nil {
				DispatchQueue.main.asyncAfter(delay: self.adRetryDelay, closure: self.initializeAds)
				self.adRetryDelay = min(self.maxAdRetryDelay, self.adRetryDelay * 2)
			} else {
				self.adRetryDelay = self.defaultAdRetryDelay
				DispatchQueue.main.async {
					form.present(from: self) { err, adsFree in
						if err != nil {
							DispatchQueue.main.asyncAfter(delay: self.adRetryDelay, closure: self.initializeAds)
							self.adRetryDelay = min(self.maxAdRetryDelay, self.adRetryDelay * 2)
						} else {
							self.adRetryDelay = self.defaultAdRetryDelay
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
		adView.adUnitID = adsUnitID
		
		adView.load(getAdRequest())
		navigationController?.toolbar.addSubview(adView)
		var constraint = NSLayoutConstraint(item: adView, attribute: .centerX, relatedBy: .equal, toItem: navigationController!.toolbar, attribute: .centerX, multiplier: 1, constant: 0)
		constraint.isActive = true
		constraint = NSLayoutConstraint(item: adView, attribute: .top, relatedBy: .equal, toItem: navigationController!.toolbar, attribute: .top, multiplier: 1, constant: 0)
		constraint.isActive = true
	}
	
	func adConsentChanged(allowPersonalized pers: Bool) {
		allowPersonalizedAds = pers
		guard areAdsEnabled else {
			return
		}
		
		if let view = adView{
			view.load(getAdRequest())
		} else {
			loadAd()
		}
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
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		if identifier == "selectFilter" {
			return !inExportMode
		}
		
		return true
	}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let id = segue.identifier else {
			return
		}
		
		switch id {
		case "showWorkout":
			if let dest = segue.destination as? WorkoutTableViewController, let indexPath = tableView.indexPathForSelectedRow {
				dest.rawWorkout = displayWorkouts[indexPath.row].raw
				dest.listController = self
			}
		case "info":
			if let dest = segue.destination as? UINavigationController, let root = dest.topViewController as? AboutViewController {
				root.delegate = self
			}
		case "selectFilter":
			if let dest = segue.destination as? UINavigationController, let root = dest.topViewController as? FilterListTableViewController {
				PopoverController.preparePresentation(for: dest)
				dest.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
				dest.popoverPresentationController?.sourceView = self.view
				dest.popoverPresentationController?.canOverlapSourceViewRect = true
				
				root.availableFilters = allWorkouts.map { $0.raw.workoutActivityType }
				root.selectedFilters = filters
				root.delegate = self
			}
		default:
			return
		}
    }

}
