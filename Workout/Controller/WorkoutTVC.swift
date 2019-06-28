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
import WorkoutCore

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
		
		workout = Workout.workoutFor(raw: rawWorkout, from: healthData, and: preferences, delegate: self)
		workout.load()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func workoutLoaded(_ workout: Workout) {
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
		if workout.hasError || !workout.isLoaded {
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
				title = "WRKT_TYPE"
				cell.detailTextLabel?.text = workout.type.name
			case 1:
				title = "WRKT_START"
				cell.detailTextLabel?.text = workout.startDate.getFormattedDateTime()
			case 2:
				title = "WRKT_END"
				cell.detailTextLabel?.text = workout.endDate.getFormattedDateTime()
			case 3:
				title = "WRKT_DURATION"
				cell.detailTextLabel?.text = workout.duration.getFormattedDuration()
			case 4:
				title = "WRKT_DISTANCE"
				cell.detailTextLabel?.text = workout.totalDistance?.formatAsDistance(withUnit: workout.distanceUnit.unit(for: preferences.systemOfUnits)) ?? missingValueStr
			case 5:
				title = "WRKT_AVG_HEART"
				cell.detailTextLabel?.text = workout.avgHeart?.formatAsHeartRate(withUnit: WorkoutUnit.heartRate.unit(for: preferences.systemOfUnits)) ?? missingValueStr
			case 6:
				title = "WRKT_MAX_HEART"
				cell.detailTextLabel?.text = workout.maxHeart?.formatAsHeartRate(withUnit: WorkoutUnit.heartRate.unit(for: preferences.systemOfUnits)) ?? missingValueStr
			case 7:
				title = "WRKT_AVG_PACE"
				cell.detailTextLabel?.text = workout.pace?.formatAsPace(withReferenceLength: workout.paceUnit.unit(for: preferences.systemOfUnits)) ?? missingValueStr
			case 8:
				title = "WRKT_AVG_SPEED"
				cell.detailTextLabel?.text = workout.speed?.formatAsSpeed(withUnit: workout.speedUnit.unit(for: preferences.systemOfUnits)) ?? missingValueStr
			case 9:
				title = "WRKT_ENERGY"
				if let total = workout.totalEnergy {
					if let active = workout.activeEnergy {
						cell.detailTextLabel?.text = String(format: NSLocalizedString("WRKT_SPLIT_CAL_%@_TOTAL_%@", comment: "Active/Total"),
															active.formatAsEnergy(withUnit: WorkoutUnit.calories.unit(for: preferences.systemOfUnits)),
															total.formatAsEnergy(withUnit: WorkoutUnit.calories.unit(for: preferences.systemOfUnits)))
					} else {
						cell.detailTextLabel?.text = total.formatAsEnergy(withUnit: WorkoutUnit.calories.unit(for: preferences.systemOfUnits))
					}
				} else {
					cell.detailTextLabel?.text = missingValueStr
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
			guard let files = self.workout.export(for: preferences.systemOfUnits) else {
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
					preferences.reviewRequestCounter += 1
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
