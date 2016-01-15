//
//  ListTableViewController.swift
//  Workout
//
//  Created by Marco Boschi on 15/01/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit

class ListTableViewController: UITableViewController {
	
	var workouts: [HKWorkout]!

    override func viewDidLoad() {
        super.viewDidLoad()

        refresh()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@IBAction func doRefresh(sender: AnyObject) {
		refresh()
	}
	
	private func refresh() {
		let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
		let type = HKObjectType.workoutType()
		let workoutQuery = HKSampleQuery(sampleType: type, predicate: nil, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { (_, r, _) in
			self.workouts = nil
			if let res = r as? [HKWorkout] {
				self.workouts = res
			}
			
			dispatchMainQueue { self.tableView.reloadData() }
		}
		
		healthStore.executeQuery(workoutQuery)
	}

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts?.count ?? 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if workouts == nil {
			return tableView.dequeueReusableCellWithIdentifier("error", forIndexPath: indexPath)
		}

		let cell = tableView.dequeueReusableCellWithIdentifier("workout", forIndexPath: indexPath)
		let w = workouts[indexPath.row]
		
		cell.textLabel?.text = w.startDate.getFormattedDateTime()
		
		var detail = w.duration.getDuration()
		if let dist = w.totalDistance {
			detail += " - " + (dist.doubleValueForUnit(HKUnit.meterUnit()) / 1000).getFormattedDistance()
		}
		cell.detailTextLabel?.text = detail

        return cell
    }
	
	@IBAction func authorize(sender: AnyObject) {
		healthStore.requestAuthorizationToShareTypes(nil, readTypes: [
			HKObjectType.workoutType(),
			HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
			HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!
		]) { (success, err) in
			self.refresh()
		}
	}

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		guard let id = segue.identifier else {
			return
		}
		
		if id == "showWorkout" {
			if let dest = segue.destinationViewController as? WorkoutTableViewController, let indexPath = tableView.indexPathForSelectedRow {
				dest.workout = workouts[indexPath.row]
			}
		}
    }

}
