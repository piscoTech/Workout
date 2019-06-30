//
//  FilterListTableViewController.swift
//  Workout
//
//  Created by Marco Boschi on 02/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit
import MBLibrary
import WorkoutCore

class FilterListTableViewController: UITableViewController {
	
	var workoutList: WorkoutList!
	
	private var filterList: [(type: HKWorkoutActivityType, name: String)] = []
	
	@IBOutlet private weak var dateLbl: UILabel!
	@IBOutlet private weak var filtersCountLbl: UILabel!
	
	private let allStr = NSLocalizedString("WRKT_FILTER_ALL", comment: "All wrkt")
	private let someStr = NSLocalizedString("WRKT_FILTER_%lld_OUT_%lld", comment: "y/x")

    override func viewDidLoad() {
        super.viewDidLoad()

		filterList = workoutList.availableFilters.map { ($0, $0.name)}.sorted { $0.1 < $1.1 }
		updateFiltersCount()
    }
	
	@IBAction func done(_ sender: AnyObject) {
		self.dismiss(animated: true)
	}
	
	private func updateFiltersCount() {
		if workoutList.filters.isEmpty {
			filtersCountLbl.text = allStr
		} else {
			filtersCountLbl.text = String(format: someStr, workoutList.filters.count, filterList.count)
		}
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return section == 0 ? 1 : filterList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wrktType", for: indexPath)

		if indexPath.section == 0 {
			cell.textLabel?.text = allStr
			cell.accessoryType = workoutList.filters.isEmpty
				? .checkmark
				: .none
		} else {
			cell.textLabel?.text = filterList[indexPath.row].name
			cell.accessoryType = workoutList.filters.contains(filterList[indexPath.row].type)
				? .checkmark
				: .none
		}

        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			workoutList.filters = []
		} else {
			let type = filterList[indexPath.row].type
			if workoutList.filters.contains(type) {
				workoutList.filters.remove(type)
			} else {
				workoutList.filters.insert(type)
			}
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
		updateFiltersCount()
		tableView.reloadRows(at: [IndexPath(row: 0, section: 0)] + (0 ..< filterList.count).map { IndexPath(row: $0, section: 1) }, with: .automatic)
	}

}
