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

class ListTableViewController: UITableViewController {
	
	var workouts: [HKWorkout]!

    override func viewDidLoad() {
        super.viewDidLoad()

        refresh()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if !preferences.bool(forKey: PreferenceKey.authorized) || preferences.integer(forKey: PreferenceKey.authVersion) < authRequired {
			authorize(self)
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@IBAction func doRefresh(_ sender: AnyObject) {
		refresh()
	}
	
	private func refresh() {
		let sortDescriptor = SortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
		let type = HKObjectType.workoutType()
		let predicate =  HKQuery.predicateForWorkouts(with: .running)
		let workoutQuery = HKSampleQuery(sampleType: type, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { (_, r, _) in
			self.workouts = nil
			if let res = r as? [HKWorkout] {
				self.workouts = res
			}
			
			DispatchQueue.main.async { self.tableView.reloadData() }
		}
		
		healthStore.execute(workoutQuery)
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
			return tableView.dequeueReusableCell(withIdentifier: "error", for: indexPath)
		}

		let cell = tableView.dequeueReusableCell(withIdentifier: "workout", for: indexPath)
		let w = workouts[indexPath.row]
		
		cell.textLabel?.text = w.startDate.getFormattedDateTime()
		
		var detail = w.duration.getDuration()
		if let dist = w.totalDistance {
			detail += " - " + (dist.doubleValue(for: .meter()) / 1000).getFormattedDistance()
		}
		cell.detailTextLabel?.text = detail

        return cell
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
			}
			
			self.refresh()
		}
	}

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
		guard let id = segue.identifier else {
			return
		}
		
		switch id {
		case "showWorkout":
			if let dest = segue.destinationViewController as? WorkoutTableViewController, let indexPath = tableView.indexPathForSelectedRow {
				dest.rawWorkout = workouts[indexPath.row]
			}
		case "info":
			if let dest = segue.destinationViewController as? UINavigationController, let root = dest.topViewController as? AboutViewController {
				root.delegate = self
			}
		default:
			return
		}
    }

}
