//
//  WorkoutTableViewController.swift
//  Workout
//
//  Created by Marco Boschi on 15/01/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit

struct DataPoint: CustomStringConvertible {
	
	var time: NSTimeInterval {
		get {
			return date.timeIntervalSince1970
		}
	}
	let date: NSDate
	
	private var heartData: [Double] = []
	var bpm: Double? {
		get {
			return heartData.count > 0 ? heartData.reduce(0) { $0 + $1 } / Double(heartData.count) : nil
		}
	}
	
	private(set) var distance: Double?
	
	init(date: NSDate) {
		self.date = date
	}
	
	mutating func addHeartData(bpm: Double) {
		heartData.append(bpm)
	}
	
	mutating func addDistanceData(d: Double) {
		distance = (distance ?? 0) + d
	}
	
	var description: String {
		get {
			return "'" + date.getUNIXDateTime() + ": " + (distance?.getFormattedDistance() ?? "(nil)") + " - " + (bpm?.getFormattedHeartRate() ?? "(nil)") + "'"
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

    override func viewDidLoad() {
        super.viewDidLoad()

        loadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	private func loadData() {
		let distancePredicate = HKQuery.predicateForObjectsFromWorkout(workout)
		let heartPredicate = HKQuery.predicateForSamplesWithStartDate(workout.startDate, endDate: workout.endDate, options: .None)
		let startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
		let noLimit = Int(HKObjectQueryNoLimit)

		//Heart data
		let heartType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!
		
		let hearthQuery = HKSampleQuery(sampleType: heartType, predicate: heartPredicate, limit: noLimit, sortDescriptors: [startDateSort]) { (_, r, _) -> Void in
			self.rawHeartData = r as? [HKQuantitySample]
			self.requestDone++
			
			self.displayData()
		}
		
		//Distance data
		let distanceType = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!
		
		let distanceQuery = HKSampleQuery(sampleType: distanceType, predicate: distancePredicate, limit: noLimit, sortDescriptors: [startDateSort]) { (_, r, _) in
			self.rawDistanceData = r as? [HKQuantitySample]
			self.requestDone++
			
			self.displayData()
		}
		
		healthStore.executeQuery(hearthQuery)
		healthStore.executeQuery(distanceQuery)
	}
	
	private func displayData() {
		if requestDone < 2 {
			return
		}
		
		if !error {
			data = []
			
			let start = Int(floor(workout.startDate.timeIntervalSince1970 / 60))
			let end = Int(floor(workout.endDate.timeIntervalSince1970 / 60))
			
			var sDate = NSDate(timeIntervalSince1970: Double(start) * 60.0)
			for _ in start ... end {
				let eDate = NSDate(timeIntervalSince1970: sDate.timeIntervalSince1970 + 60)
				
				var p = DataPoint(date: sDate)
				
				while let d = rawDistanceData.first where d.startDate >= sDate && d.startDate <= eDate {
					let l = d.quantity.doubleValueForUnit(HKUnit.meterUnit())
					p.addDistanceData(l / 1000)
					
					rawDistanceData.removeAtIndex(0)
				}
				
				while let h = rawHeartData.first where h.startDate >= sDate && h.startDate <= eDate {
					let bpm = h.quantity.doubleValueForUnit(HKUnit.heartRateUnit())
					p.addHeartData(bpm)
					
					rawHeartData.removeAtIndex(0)
				}
				
				data.append(p)
				sDate = eDate
			}
		}
		
		dispatchMainQueue { self.tableView.reloadData() }
	}

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return error ? 1 : 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if error {
			return 1
		}
		
		return section == 0 ? 4 : data.count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if error {
			return tableView.dequeueReusableCellWithIdentifier("error", forIndexPath: indexPath)
		}
		
		if indexPath.section == 1 {
			let cell = tableView.dequeueReusableCellWithIdentifier("detail", forIndexPath: indexPath) as! WorkoutDetailTableViewCell
			let d = data[indexPath.row]
			
			cell.time.text = d.date.getFormattedTime()
			cell.bpm.text = d.bpm?.getFormattedHeartRate() ?? "-"
			cell.distance.text = d.distance?.getFormattedDistance() ?? "-"
			
			return cell
		} else {
			let cell = tableView.dequeueReusableCellWithIdentifier("basic", forIndexPath: indexPath)
			
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
				cell.detailTextLabel?.text = (workout.totalDistance!.doubleValueForUnit(HKUnit.meterUnit()) / 1000).getFormattedDistance()
			default:
				break
			}
			
			return cell
		}
    }

}
