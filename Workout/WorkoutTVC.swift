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
		
		return section == 0 ? 5 : workout.details.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if error {
			return tableView.dequeueReusableCell(withIdentifier: "error", for: indexPath)
		}
		
		if indexPath.section == 1 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath) as! WorkoutDetailTableViewCell
			let d = workout.details[indexPath.row]
			
			cell.time.text = d.startTime.getDuration()
			cell.bpm.text = d.bpm?.getFormattedHeartRate() ?? "-"
			cell.distance.text = d.distance?.getFormattedDistance() ?? "-"
			
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath)
			
			switch indexPath.row {
			case 0:
				cell.textLabel?.text = "Start"
				cell.detailTextLabel?.text = workout.startDate.getFormattedDateTime()
			case 1:
				cell.textLabel?.text = "End"
				cell.detailTextLabel?.text = workout.endDate.getFormattedDateTime()
			case 2:
				cell.textLabel?.text = "Duration"
				cell.detailTextLabel?.text = workout.duration.getDuration()
			case 3:
				cell.textLabel?.text = "Distance"
				cell.detailTextLabel?.text = workout.totalDistance.getFormattedDistance()
			case 4:
				cell.textLabel?.text = "Max Heart Rate"
				cell.detailTextLabel?.text = workout.maxHeart?.getFormattedHeartRate() ?? "-"
			default:
				break
			}
			
			return cell
		}
    }
	
	// MARK: - Export
	
	@IBAction func doExport(_ sender: UIBarButtonItem) {
		export(sender)
	}
	
	private var documentController: UIActivityViewController!
	
	private func export(_ sender: UIBarButtonItem) {
		var filePath = NSString(string: NSTemporaryDirectory()).appendingPathComponent("generalData.csv")
		let generalDataPath = URL(fileURLWithPath: filePath)
		filePath = NSString(string: NSTemporaryDirectory()).appendingPathComponent("details.csv")
		let detailsPath = URL(fileURLWithPath: filePath)
		
		var gen = "Field\(CSVSeparator)Value\n"
		gen += "Start\(CSVSeparator)" + workout.startDate.getUNIXDateTime().toCSV() + "\n"
		gen += "End\(CSVSeparator)" + workout.endDate.getUNIXDateTime().toCSV() + "\n"
		gen += "Duration\(CSVSeparator)" + workout.duration.getDuration().toCSV() + "\n"
		gen += "Distance\(CSVSeparator)" + workout.totalDistance.toCSV() + "\n"
		gen += "\("Max Heart Rate".toCSV())\(CSVSeparator)" + (workout.maxHeart?.toCSV() ?? "")
		
		var det = "Time\(CSVSeparator)\("Heart Rate".toCSV())\(CSVSeparator)Distance\(CSVSeparator)Pace\n"
		for d in workout.details {
			det += d.startTime.getDuration().toCSV() + CSVSeparator
			det += (d.bpm?.toCSV() ?? "") + CSVSeparator
			det += (d.distance?.toCSV() ?? "") + CSVSeparator
			det += d.pace?.getDuration().toCSV() ?? ""
			det += "\n"
		}
		
		do {
			try gen.write(to: generalDataPath, atomically: true, encoding: String.Encoding.utf8)
			try det.write(to: detailsPath, atomically: true, encoding: String.Encoding.utf8)
		} catch _ {
			let alert = UIAlertController(title: "Cannot export workout data", message: nil, preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
			
			self.present(alert, animated: true, completion: nil)
			
			return
		}
		
		documentController = UIActivityViewController(activityItems: [generalDataPath, detailsPath], applicationActivities: nil)
		
		DispatchQueue.main.async {
			self.present(self.documentController, animated: true, completion: nil)
			self.documentController.popoverPresentationController?.barButtonItem = sender
		}
	}

}
