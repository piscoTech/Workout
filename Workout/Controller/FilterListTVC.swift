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

	@IBOutlet private weak var filtersLbl: UILabel!
	
	private let allStr = NSLocalizedString("WRKT_FILTER_ALL", comment: "All wrkt")
	private let someStr = NSLocalizedString("WRKT_FILTER_%lld_OUT_%lld", comment: "y/x")

	private let fromStr = NSLocalizedString("WRKT_FILTER_FROM", comment: "From")
	private let fromNoneStr = NSLocalizedString("WRKT_FILTER_FROM_NONE", comment: "From -∞")
	private let toStr = NSLocalizedString("WRKT_FILTER_TO", comment: "To")
	private let toNoneStr = NSLocalizedString("WRKT_FILTER_TO_NONE", comment: "To +∞")

    override func viewDidLoad() {
        super.viewDidLoad()

		workoutList.endDate = Date().addingTimeInterval(-10 * 24 * 2600)

		filterList = workoutList.availableFilters.map { ($0, $0.name)}.sorted { $0.1 < $1.1 }
		updateFiltersCount()

		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 44
    }
	
	@IBAction func done(_ sender: AnyObject) {
		self.dismiss(animated: true)
	}
	
	private func updateFiltersCount() {
		let types: String
		if workoutList.filters.isEmpty {
			types = allStr
		} else {
			types = String(format: someStr, workoutList.filters.count, filterList.count)
		}

		filtersLbl.text = [workoutList.dateFilterStringEvenNoFilter, types].joined(separator: " \(textSeparator) ")
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			#warning("Consider + 1 if changing")
			return 3
		case 1:
			return filterList.count + 1
		default:
			fatalError("Unknown section")
		}
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case 0:
			#warning("Consider picker cell")
			if indexPath.row == 2 {
				let cell = tableView.dequeueReusableCell(withIdentifier: "datePicker", for: indexPath) as! DatePickerCell
				cell.date = workoutList.endDate ?? Date()

				return cell
			}
			let cell = tableView.dequeueReusableCell(withIdentifier: "dateFilter", for: indexPath) as! DateFilterCell

			if indexPath.row == 0 {
				cell.title.text = fromStr
				cell.date.text = workoutList.startDate?.getFormattedDate() ?? fromNoneStr
			} else {
				cell.title.text = toStr
				cell.date.text = workoutList.endDate?.getFormattedDate() ?? toNoneStr
			}

			return cell
		case 1:
			let cell = tableView.dequeueReusableCell(withIdentifier: "wrktType", for: indexPath)

			if indexPath.row == 0 {
				cell.textLabel?.text = allStr
				cell.accessoryType = workoutList.filters.isEmpty
					? .checkmark
					: .none
			} else {
				let i = indexPath.row - 1
				cell.textLabel?.text = filterList[i].name
				cell.accessoryType = workoutList.filters.contains(filterList[i].type)
					? .checkmark
					: .none
			}

			return cell
		default:
			fatalError("Unknown section")
		}
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)

		switch indexPath.section {
		case 0:
			print("Coming soon")
		case 1:
			if indexPath.row == 0 {
				workoutList.filters = []
			} else {
				let type = filterList[indexPath.row - 1].type
				if workoutList.filters.contains(type) {
					workoutList.filters.remove(type)
				} else {
					workoutList.filters.insert(type)
				}
			}

			updateFiltersCount()
			// There are filterList.count + 1 cells in section 1
			tableView.reloadRows(at: (0 ... filterList.count).map { IndexPath(row: $0, section: 1) }, with: .automatic)
		default:
			fatalError("Unknown section")
		}
	}

}
