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
import WorkoutCore
import GoogleMobileAds
import StoreKit

class ListTableViewController: UITableViewController, WorkoutListDelegate, WorkoutBulkExporterDelegate, PreferencesDelegate, AdsManagerDelegate, EnhancedNavigationBarDelegate {

	private let list = WorkoutList(healthData: healthData, preferences: preferences)
	private var exporter: WorkoutBulkExporter?
	
	private var standardRightBtns: [UIBarButtonItem]!
	private var standardLeftBtn: UIBarButtonItem!
	@IBOutlet private weak var enterExportModeBtn: UIBarButtonItem!
	
	private var exportRightBtns: [UIBarButtonItem]!
	private var exportLeftBtn: UIBarButtonItem!
	
	private var exportToggleBtn: UIBarButtonItem!
	private var exportCommitBtn: UIBarButtonItem!
	
	private var heightFixed = false
	private var titleLblShouldHide = false
	@IBOutlet private var titleView: UIView!
	@IBOutlet private weak var titleLbl: UILabel!
	@IBOutlet private weak var filterLbl: UILabel!
	
	private var loaded = false

    override func viewDidLoad() {
        super.viewDidLoad()
		
		// Navigation Bar
		let navBar = navigationController?.navigationBar as? EnhancedNavigationBar
		titleLbl.text = self.navigationItem.title
		filterLbl.textColor = navBar?.tintColor
		navigationItem.titleView = titleView
		navBar?.enhancedDelegate = self
		
		standardRightBtns = navigationItem.rightBarButtonItems
		standardLeftBtn = navigationItem.leftBarButtonItem
		if #available(iOS 13, *) {} else {
			standardLeftBtn.image = #imageLiteral(resourceName: "Settings")
		}
		
		exportToggleBtn = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(toggleExportAll))
		exportCommitBtn = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(doExport(_:)))
		exportRightBtns = [exportCommitBtn, exportToggleBtn]
		exportLeftBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelExport(_:)))
		
		// Ads
		navigationController?.isToolbarHidden = true
		adsManager.delegate = self
		adsManager.initialize()
		

		preferences.add(delegate: self)
		list.delegate = self
		updateFilterLabel()
        refresh()
		
		DispatchQueue.main.async {
			self.checkRequestReview()
		}
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if !heightFixed {
			heightFixed = true
			NSLayoutConstraint(item: titleView as Any, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: titleView.frame.height).isActive = true
			titleLbl.isHidden = titleLblShouldHide
		}
		
		if !loaded {
			loaded = true
			healthData.authorizeHealthKitAccess {
				DispatchQueue.main.async {
					self.refresh()
				}
			}
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
		#if !DEBUG
			if #available(iOS 10.3, *) {
				guard preferences.reviewRequestCounter >= preferences.reviewRequestThreshold else {
					return
				}
				
				SKStoreReviewController.requestReview()
			}
		#endif
	}
	
	// MARK: - Data Loading
	
	private weak var loadMoreCell: LoadMoreCell?
	
	@IBAction func refresh() {
		list.reload()
	}
	
	func preferredSystemOfUnitsChanged() {
		tableView.reloadSections([0], with: .automatic)
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
		if self.list.error == nil && self.list.workouts != nil && self.list.canDisplayMore && self.exporter == nil {
			return 2
		} else {
			return 1
		}
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
        	return max(list.workouts?.count ?? 1, 1)
		} else {
			return 1
		}
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 1 {
			let res = tableView.dequeueReusableCell(withIdentifier: "loadMore", for: indexPath) as! LoadMoreCell
			res.isEnabled = !list.isLoading
			loadMoreCell = res
			
			return res
		}
		
		guard let wrkts = list.workouts, !wrkts.isEmpty else {
			let res = tableView.dequeueReusableCell(withIdentifier: "msg", for: indexPath)
			let msg: String
			if HKHealthStore.isHealthDataAvailable() {
				if list.error != nil {
					msg = "WRKT_ERR_LOADING"
				} else if list.workouts != nil {
					msg = "WRKT_LIST_ERR_NO_WORKOUT"
				} else {
					msg = "WRKT_LIST_LOADING"
				}
			} else {
				msg = "WRKT_ERR_NO_HEALTH"
			}
			res.textLabel?.text = NSLocalizedString(msg, comment: "Loading/Error")
			
			return res
		}

		let cell = tableView.dequeueReusableCell(withIdentifier: "workout", for: indexPath)
		let w = wrkts[indexPath.row]
		
		cell.textLabel?.text = w.type.name
		
		var detail = [w.startDate.getFormattedDateTime(), w.duration.getFormattedDuration() ]
		if let dist = w.totalDistance?.formatAsDistance(withUnit: w.distanceUnit.unit(for: preferences.systemOfUnits)) {
			detail.append(dist)
		}
		cell.detailTextLabel?.text = detail.joined(separator: " \(textSeparator) ")
		
		if let exp = exporter {
			cell.accessoryType = exp.selection[indexPath.row] ? .checkmark : .none
		} else {
			cell.accessoryType = .disclosureIndicator
		}

        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 1 {
			if loadMoreCell?.isEnabled ?? false {
				list.loadMore()
			}
		} else {
			if let exp = exporter {
				exp[indexPath.row].toggle()
			} else {
				performSegue(withIdentifier: "showWorkout", sender: self)
			}
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}

	// MARK: - List Displaying

	private let allFiltersStr = NSLocalizedString("WRKT_FILTER_ALL", comment: "All")
	private let manyFiltersStr = NSLocalizedString("%lld_WRKT_FILTERS", comment: "Many")

	func loadingStatusChanged() {
		loadMoreCell?.isEnabled = !list.isLoading
		updateExportModeEnabled()
	}

	func listChanged() {
		updateExportModeEnabled()

		updateFilterLabel()

		tableView.beginUpdates()
		tableView.reloadSections([0], with: .automatic)
		setupLoadMore()
		tableView.endUpdates()
	}

	func additionalWorkoutsLoaded(count: Int, oldCount: Int) {
		tableView.beginUpdates()
		if count > 0 && oldCount > 0 {
			tableView.insertRows(at: (0 ..< count).map { IndexPath(row: $0 + oldCount, section: 0)}, with: .automatic)
		} else {
			tableView.reloadSections([0], with: .automatic)
		}
		setupLoadMore()
		tableView.endUpdates()
	}

	private func updateFilterLabel() {
		let types: String
		switch list.filters.count {
		case 0:
			types = allFiltersStr
		case 1:
			guard let n = list.filters.first?.name else {
				fallthrough
			}

			types = n
		default:
			types = String(format: manyFiltersStr, list.filters.count)
		}

		filterLbl.text = [list.dateFilterString, types].compactMap { $0 }.joined(separator: " \(textSeparator) ")
	}

	private func setupLoadMore() {
		if list.canDisplayMore && exporter == nil {
			if tableView.numberOfSections == 1 {
				tableView.insertSections([1], with: .automatic)
			}
		} else {
			if tableView.numberOfSections > 1 {
				tableView.deleteSections([1], with: .automatic)
			}
		}
	}
	
	// MARK: - Export all workouts
	
	private var documentController: UIActivityViewController!
	private var exportWorkouts = [Workout]()
	private var waitingForExport = 0
	private var loadingBar: UIAlertController?
	private weak var loadingProgress: UIProgressView?

	private func updateExportModeEnabled() {
		enterExportModeBtn.isEnabled = !list.isLoading && !(list.workouts?.isEmpty ?? true)
	}
	
	@IBAction func chooseExport() {
		guard let exp = WorkoutBulkExporter(list) else {
			return
		}

		self.exporter = exp
		exp.delegate = self
		listChanged()
		updateExportToggleAll()
		
		navigationItem.leftBarButtonItem = exportLeftBtn
		navigationItem.rightBarButtonItems = exportRightBtns
	}

	@objc func cancelExport(_ sender: AnyObject) {
		self.exporter = nil
		listChanged()

		navigationItem.leftBarButtonItem = standardLeftBtn
		navigationItem.rightBarButtonItems = standardRightBtns
	}
	
	private func updateExportToggleAll() {
		guard let exp = exporter else {
			return
		}
		
		exportToggleBtn.title = NSLocalizedString("EXPORT_SELECT_\(exp.selection.firstIndex(of: false) != nil ? "ALL" : "NONE")", comment: "Select")
	}

	@objc func toggleExportAll() {
		guard let exp = exporter else {
			return
		}

		exp.selectAll(exp.selection.firstIndex(of: false) != nil)
	}

	func exportSelectionChanged(for offsets: [Int]?) {
		guard let exp = exporter else {
			return
		}

		for i in offsets ?? Array(0 ..< (list.workouts?.count ?? 0)) {
			if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) {
				cell.accessoryType = exp.selection[i] ? .checkmark : .none
			}
		}

		exportCommitBtn.isEnabled = exp.canExport
		updateExportToggleAll()
	}
	
	@objc func doExport(_ sender: UIBarButtonItem) {
		guard let exp = exporter else {
			return
		}

		loadingBar?.dismiss(animated: false)
		if exp.export(from: healthData, and: preferences) {
			let (bar, progress) = UIAlertController.getModalProgress()
			self.loadingBar = bar
			self.loadingProgress = progress
			self.present(self.loadingBar!, animated: true)
		}
	}

	func exportProgressChanged(_ progress: Float) {
		DispatchQueue.main.async {
			self.loadingProgress?.setProgress(progress, animated: true)
		}
	}

	func exportCompleted(data: URL?, individualFailures failures: [Date]?) {
		DispatchQueue.main.async {
			self.cancelExport(self)

			guard let filePath = data, let fail = failures else {
				let alert = UIAlertController(simpleAlert: NSLocalizedString("EXPORT_ERROR", comment: "Export error"), message: nil)

				if let l = self.loadingBar {
					l.dismiss(animated: true) {
						self.loadingBar = nil
						self.present(alert, animated: true)
					}
				} else {
					self.present(alert, animated: true)
				}

				return
			}

			self.documentController = UIActivityViewController(activityItems: [filePath], applicationActivities: nil)
			self.documentController.completionWithItemsHandler = { _, completed, _, _ in
				self.documentController = nil

				if completed {
					let review = {
						preferences.reviewRequestCounter += 1
						self.checkRequestReview()
					}

					if !fail.isEmpty {
						let text = String(format: NSLocalizedString("EXPORT_ERROR_PARTIAL_%@", comment: "Failed workouts"), fail.map { $0.getFormattedDateTime() }.joined(separator: "\n"))
						let alert = UIAlertController(simpleAlert: NSLocalizedString("EXPORT_ERROR_PARTIAL", comment: "Export error"),
													  message: text) {
							review()
						}

						self.present(alert, animated: true)
					} else {
						review()
					}
				}
			}

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
	}
	
	// MARK: - Ads
	
	var defaultPresenter: UIViewController {
		self
	}
	
	func displayAds() {
		DispatchQueue.main.async {
			guard let nav = self.navigationController else {
				return
			}
			
			guard let adView = adsManager.adView else {
				self.hideAds()
				return
			}
			
			if nav.toolbar.subviews.isEmpty {
				nav.toolbar.addSubview(adView)
				var constraint = NSLayoutConstraint(item: adView, attribute: .centerX, relatedBy: .equal, toItem: nav.toolbar, attribute: .centerX, multiplier: 1, constant: 0)
				constraint.isActive = true
				constraint = NSLayoutConstraint(item: adView, attribute: .top, relatedBy: .equal, toItem: nav.toolbar, attribute: .top, multiplier: 1, constant: 0)
				constraint.isActive = true
			}
			
			nav.setToolbarHidden(false, animated: true)
		}
	}
	
	func hideAds() {
		DispatchQueue.main.async {
			guard let nav = self.navigationController else {
				return
			}
			
			nav.setToolbarHidden(true, animated: true)
			DispatchQueue.main.asyncAfter(delay: 2) {
				for v in nav.toolbar.subviews {
					v.removeFromSuperview()
				}
			}
		}
	}

    // MARK: - Navigation
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		if identifier == "selectFilter" {
			return exporter == nil && !list.isLoading
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
				dest.rawWorkout = list.workouts![indexPath.row].raw
				dest.listController = self
			}
			
		case "selectFilter":
			if let dest = segue.destination as? UINavigationController, let root = dest.topViewController as? FilterListTableViewController {
				PopoverController.preparePresentation(for: dest)
				dest.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
				dest.popoverPresentationController?.sourceView = self.view
				dest.popoverPresentationController?.canOverlapSourceViewRect = true
				
				root.workoutList = list
			}
			
		default:
			break
		}
    }

}
