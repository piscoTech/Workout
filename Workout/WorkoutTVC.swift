//
//  WorkoutTableViewController.swift
//  Workout
//
//  Created by Marco Boschi on 15/01/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit
import MBLibrary

class WorkoutTableViewController: UITableViewController, WorkoutDelegate {
	
	@IBOutlet var exportBtn: UIBarButtonItem!
	
	weak var listController: ListTableViewController!
	var rawWorkout: HKWorkout!
	private var workout: Workout!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		let loading = UIActivityIndicatorView(style: .gray)
		loading.startAnimating()
		navigationItem.rightBarButtonItem = UIBarButtonItem(customView: loading)
		
		workout = Workout.workoutFor(raw: rawWorkout, delegate: self)
		workout.load()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func dataIsReady() {
		DispatchQueue.main.async {
			self.exportBtn.isEnabled = !self.workout.hasError
			self.navigationItem.setRightBarButton(self.exportBtn, animated: true)

			let old = self.tableView.numberOfSections
			let new = self.numberOfSections(in: self.tableView)
			self.tableView.beginUpdates()
			self.tableView.reloadSections(IndexSet(integersIn: 0 ..< min(old, new)), with: .fade)
			if old < new {
				self.tableView.insertSections(IndexSet(integersIn: old ..< new), with: .fade)
			} else if old > new {
				self.tableView.deleteSections(IndexSet(integersIn: new ..< old), with: .fade)
			}
			self.tableView.endUpdates()
		}
	}

    // MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		if workout.hasError || !workout.loaded {
			return 1
		}
		
		return 1 + workout.additionalProviders.count
    }
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section > 0 {
			return workout.additionalProviders[section - 1].sectionHeader
		}
		
		return nil
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if section > 0 {
			return workout.additionalProviders[section - 1].sectionFooter
		}
		
		return nil
	}

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if workout.hasError {
			return 1
		}
		
		if section == 0 {
			return 10
		} else {
			return workout.additionalProviders[section - 1].numberOfRows
		}
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if workout.hasError {
			let res = tableView.dequeueReusableCell(withIdentifier: "msg", for: indexPath)
			let msg: String
			if HKHealthStore.isHealthDataAvailable() {
				msg = "ERR_LOADING"
			} else {
				msg = "ERR_NO_HEALTH"
			}
			res.textLabel?.text = NSLocalizedString(msg, comment: "Error")
			
			return res
		}
		
		if indexPath.section == 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath)
			
			let title: String
			switch indexPath.row {
			case 0:
				title = "TYPE"
				cell.detailTextLabel?.text = workout.type.name
			case 1:
				title = "START"
				cell.detailTextLabel?.text = workout.startDate.getFormattedDateTime()
			case 2:
				title = "END"
				cell.detailTextLabel?.text = workout.endDate.getFormattedDateTime()
			case 3:
				title = "DURATION"
				cell.detailTextLabel?.text = workout.duration.getDuration()
			case 4:
				title = "DISTANCE"
				cell.detailTextLabel?.text = workout.totalDistance?.getFormattedDistance(withUnit: workout.distanceUnit) ?? WorkoutDetail.noData
			case 5:
				title = "AVG_HEART"
				cell.detailTextLabel?.text = workout.avgHeart?.getFormattedHeartRate() ?? WorkoutDetail.noData
			case 6:
				title = "MAX_HEART"
				cell.detailTextLabel?.text = workout.maxHeart?.getFormattedHeartRate() ?? WorkoutDetail.noData
			case 7:
				title = "AVG_PACE"
				cell.detailTextLabel?.text = workout.pace?.getFormattedPace(forLengthUnit: workout.paceUnit) ?? WorkoutDetail.noData
			case 8:
				title = "AVG_SPEED"
				cell.detailTextLabel?.text = workout.speed?.getFormattedSpeed(forLengthUnit: workout.speedUnit
					) ?? WorkoutDetail.noData
			case 9:
				title = "CALORIES"
				if let total = workout.totalCalories {
					if let active = workout.activeCalories {
						cell.detailTextLabel?.text = String(format: NSLocalizedString("CAL_SPLIT", comment: "Active/Total"), active.getFormattedCalories(), total.getFormattedCalories())
					} else {
						cell.detailTextLabel?.text = total.getFormattedCalories()
					}
				} else {
					cell.detailTextLabel?.text = WorkoutDetail.noData
				}
			default:
				return cell
			}
			
			cell.textLabel?.text = NSLocalizedString(title, comment: "Cell title")
			return cell
		} else {
			return workout.additionalProviders[indexPath.section - 1].cellForRowAt(indexPath, for: tableView)
		}
    }
	
	// MARK: - Export
	
	private var documentController: UIActivityViewController!
	private var loadingIndicator: UIAlertController?
	
	@IBAction func export(_ sender: UIBarButtonItem) {
		loadingIndicator?.dismiss(animated: false)
		loadingIndicator = UIAlertController.getModalLoading()
		self.present(loadingIndicator!, animated: true)
		
		DispatchQueue.userInitiated.async {
			guard let files = self.workout.export() else {
				let alert = UIAlertController(simpleAlert: NSLocalizedString("CANNOT_EXPORT", comment: "Export error"), message: nil)
				
				DispatchQueue.main.async {
					if let l = self.loadingIndicator {
						l.dismiss(animated: true) {
							self.loadingIndicator = nil
							self.present(alert, animated: true)
						}
					} else {
						self.present(alert, animated: true)
					}
				}
				
				return
			}
			
			self.documentController = UIActivityViewController(activityItems: files, applicationActivities: nil)
			self.documentController.completionWithItemsHandler = { _, completed, _, _ in
				self.documentController = nil
				
				if completed {
					Preferences.reviewRequestCounter += 1
					self.listController.checkRequestReview()
				}
			}
			
			DispatchQueue.main.async {
				if let l = self.loadingIndicator {
					l.dismiss(animated: true) {
						self.loadingIndicator = nil
						self.present(self.documentController, animated: true)
					}
				} else {
					self.present(self.documentController, animated: true)
				}
				
				self.documentController.popoverPresentationController?.barButtonItem = sender
			}
		}
	}

}
