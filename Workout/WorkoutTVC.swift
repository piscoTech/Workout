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
	
	@IBOutlet weak var exportBtn: UIBarButtonItem!
	
	var rawWorkout: HKWorkout!
	private var workout: Workout!
	
	private var ready = false
	private var error: Bool {
		get {
			return !ready || workout.hasError
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

        workout = Workout(rawWorkout, delegate: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func dataIsReady() {
		ready = true
		DispatchQueue.main.async {
			self.exportBtn.isEnabled = !self.error
			self.tableView.reloadData()
		}
	}

    // MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return error ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if error {
			return 1
		}
		
		return section == 0 ? 7 : workout.details.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if error {
			let res = tableView.dequeueReusableCell(withIdentifier: "msg", for: indexPath)
			let msg: String
			if HKHealthStore.isHealthDataAvailable() {
				msg = !ready ? "LOADING" : "ERR_LOADING"
			} else {
				msg = "ERR_NO_HEALTH"
			}
			res.textLabel?.text = NSLocalizedString(msg, comment: "Loading/Error")
			
			return res
		}
		
		if indexPath.section == 1 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath) as! WorkoutDetailTableViewCell
			let d = workout.details[indexPath.row]
			
			cell.time.text = "\(d.minute)m"
			cell.pace.text = d.pace?.getFormattedPace() ?? "-"
			cell.bpm.text = d.bpm?.getFormattedHeartRate() ?? "-"
			cell.steps.text = d.steps?.getFormattedSteps() ?? "-"
			
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath)
			
			let title: String
			switch indexPath.row {
			case 0:
				title = "START"
				cell.detailTextLabel?.text = workout.startDate.getFormattedDateTime()
			case 1:
				title = "END"
				cell.detailTextLabel?.text = workout.endDate.getFormattedDateTime()
			case 2:
				title = "DURATION"
				cell.detailTextLabel?.text = workout.duration.getDuration()
			case 3:
				title = "DISTANCE"
				cell.detailTextLabel?.text = workout.totalDistance.getFormattedDistance()
			case 4:
				title = "AVG_HEART"
				cell.detailTextLabel?.text = workout.avgHeart?.getFormattedHeartRate() ?? "-"
			case 5:
				title = "MAX_HEART"
				cell.detailTextLabel?.text = workout.maxHeart?.getFormattedHeartRate() ?? "-"
			case 6:
				title = "AVG_PACE";
				cell.detailTextLabel?.text = workout.pace.getFormattedPace()
			default:
				return cell
			}
			
			cell.textLabel?.text = NSLocalizedString(title, comment: "Cell title")
			return cell
		}
    }
	
	// MARK: - Export
	
	@IBAction func doExport(_ sender: UIBarButtonItem) {
		export(sender)
	}
	
	private var documentController: UIActivityViewController!
	
	private func export(_ sender: UIBarButtonItem) {
		DispatchQueue.userInitiated.async {
			guard let files = self.workout.export() else {
				let alert = UIAlertController(simpleAlert: NSLocalizedString("CANNOT_EXPORT", comment: "Export error"), message: nil)
				
				DispatchQueue.main.async {
					self.present(alert, animated: true, completion: nil)
				}
				
				return
			}
			
			self.documentController = UIActivityViewController(activityItems: files, applicationActivities: nil)
			
			DispatchQueue.main.async {
				self.present(self.documentController, animated: true, completion: nil)
				self.documentController.popoverPresentationController?.barButtonItem = sender
			}
		}
	}

}
