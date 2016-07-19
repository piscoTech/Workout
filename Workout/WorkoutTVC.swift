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

struct DataPoint: CustomStringConvertible {
	
	var time: TimeInterval
	
	private var heartData: [Double] = []
	var bpm: Double? {
		get {
			return heartData.count > 0 ? heartData.reduce(0) { $0 + $1 } / Double(heartData.count) : nil
		}
	}
	
	private(set) var distance: Double?
	
	init(time: TimeInterval) {
		self.time = time
	}
	
	mutating func addHeartData(_ bpm: Double) {
		heartData.append(bpm)
	}
	
	mutating func addDistanceData(_ d: Double) {
		distance = (distance ?? 0) + d
	}
	
	var description: String {
		get {
			return "'" + time.getDuration() + ": " + (distance?.getFormattedDistance() ?? "(nil)") + " - " + (bpm?.getFormattedHeartRate() ?? "(nil)") + "'"
		}
	}
}

class WorkoutTableViewController: UITableViewController {
	
	var workout: HKWorkout!
	
	private var requestDone = 0
	private var rawHeartData: [HKQuantitySample]!
	private var rawDistanceData: [HKQuantitySample]!
	private var error: Bool {
		get {
			return rawDistanceData == nil || rawHeartData == nil
		}
	}
	
	private var data: [DataPoint]!
	private var maxHeart: Double!

    override func viewDidLoad() {
        super.viewDidLoad()

        loadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	private func loadData() {
		let distancePredicate = HKQuery.predicateForObjects(from: workout)
		let heartPredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [])
		let startDateSort = SortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
		let noLimit = Int(HKObjectQueryNoLimit)

		//Heart data
		let heartType = HKObjectType.quantityType(forIdentifier: .heartRate)!
		
		let hearthQuery = HKSampleQuery(sampleType: heartType, predicate: heartPredicate, limit: noLimit, sortDescriptors: [startDateSort]) { (_, r, _) -> Void in
			self.rawHeartData = r as? [HKQuantitySample]
			self.requestDone += 1
			
			self.displayData()
		}
		
		//Distance data
		let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
		
		let distanceQuery = HKSampleQuery(sampleType: distanceType, predicate: distancePredicate, limit: noLimit, sortDescriptors: [startDateSort]) { (_, r, _) in
			self.rawDistanceData = r as? [HKQuantitySample]
			self.requestDone += 1
			
			self.displayData()
		}
		
		healthStore.execute(hearthQuery)
		healthStore.execute(distanceQuery)
	}
	
	private func displayData() {
		if requestDone < 2 {
			return
		}
		
		if !error {
			data = []
			maxHeart = 0
			
			let start = workout.startDate.timeIntervalSince1970
			let end = Int(floor( (workout.endDate.timeIntervalSince1970 - start) / 60 ))
			
			var sDate = workout.startDate
			for time in 0 ... end {
				let eDate = Date(timeIntervalSince1970: sDate.timeIntervalSince1970 + 60)
				
				var p = DataPoint(time: Double(time) * 60)
				
				while let d = rawDistanceData.first where d.startDate >= sDate && d.startDate <= eDate {
					let l = d.quantity.doubleValue(for: HKUnit.meter())
					p.addDistanceData(l / 1000)
					
					rawDistanceData.remove(at: 0)
				}
				
				while let h = rawHeartData.first where h.startDate >= sDate && h.startDate <= eDate {
					let bpm = h.quantity.doubleValue(for: HKUnit.heartRateUnit())
					maxHeart = max(maxHeart, bpm)
					p.addHeartData(bpm)
					
					rawHeartData.remove(at: 0)
				}
				
				data.append(p)
				sDate = eDate
			}
		}
		
		DispatchQueue.main.async { self.tableView.reloadData() }
	}

    // MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return error ? 1 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if error {
			return 1
		}
		
		return section == 0 ? 4 : data.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if error {
			return tableView.dequeueReusableCell(withIdentifier: "error", for: indexPath)
		}
		
		if indexPath.section == 1 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath) as! WorkoutDetailTableViewCell
			let d = data[indexPath.row]
			
			cell.time.text = d.time.getDuration()
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
				cell.detailTextLabel?.text = (workout.totalDistance!.doubleValue(for: HKUnit.meter()) / 1000).getFormattedDistance()
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
		gen += "Distance\(CSVSeparator)" + (workout.totalDistance!.doubleValue(for: HKUnit.meter()) / 1000).toCSV() + "\n"
		gen += "\("Max Heart Rate".toCSV())\(CSVSeparator)" + maxHeart.toCSV()
		
		var det = "Time\(CSVSeparator)\("Heart Rate".toCSV())\(CSVSeparator)Distance\(CSVSeparator)Pace\n"
		for d in data {
			det += d.time.getDuration().toCSV() + CSVSeparator
			det += (d.bpm?.toCSV() ?? "") + CSVSeparator
			det += (d.distance?.toCSV() ?? "") + CSVSeparator
			let pace: TimeInterval?
			do {
				if let d = d.distance {
					let p  = 60 / d
					pace = p < 20 * 60 ? p : nil
				} else {
					pace = nil
				}
			}
			det += pace?.getDuration().toCSV() ?? ""
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
