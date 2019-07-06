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

	private enum DateFilter {
		case none, start, end
	}
	
	var workoutList: WorkoutList!
	
	private var filterList: [(type: HKWorkoutActivityType, name: String)] = []
	private var editingDate = DateFilter.none

	private let startDateRow = 0
	private var endDateRow: Int {
		editingDate == .start ? 2 : 1
	}
	private var editingDateRow: Int? {
		switch editingDate {
		case .none:
			return nil
		case .start:
			return 1
		case .end:
			return 2
		}
	}

	@IBOutlet private weak var filtersLbl: UILabel!
	
	private let allStr = NSLocalizedString("WRKT_FILTER_ALL", comment: "All wrkt")
	private let someStr = NSLocalizedString("WRKT_FILTER_%lld_OUT_%lld", comment: "y/x")

	private let fromStr = NSLocalizedString("WRKT_FILTER_FROM", comment: "From")
	private let fromNoneStr = NSLocalizedString("WRKT_FILTER_FROM_NONE", comment: "From -∞")
	private let toStr = NSLocalizedString("WRKT_FILTER_TO", comment: "To")
	private let toNoneStr = NSLocalizedString("WRKT_FILTER_TO_NONE", comment: "To +∞")

    override func viewDidLoad() {
        super.viewDidLoad()

		filterList = workoutList.availableFilters.map { ($0, $0.name)}.sorted { $0.1 < $1.1 }
		updateFilterLabel()

		tableView.rowHeight = UITableView.automaticDimension
		tableView.estimatedRowHeight = 44
    }
	
	@IBAction func done(_ sender: AnyObject) {
		self.dismiss(animated: true)
	}
	
	private func updateFilterLabel() {
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

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0:
			return NSLocalizedString("WRKT_FILTER_DATE", comment: "Date")
		case 1:
			return NSLocalizedString("WRKT_FILTER_TYPE", comment: "Type")
		default:
			fatalError("Unknown section")
		}
	}

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 2 + (editingDate != .none ? 1 : 0)
		case 1:
			return filterList.count + 1
		default:
			fatalError("Unknown section")
		}
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case 0:
			switch indexPath.row {
			case startDateRow:
				let cell = tableView.dequeueReusableCell(withIdentifier: "dateFilter", for: indexPath) as! DateFilterCell
				cell.title.text = fromStr
				cell.date.text = workoutList.startDate?.getFormattedDate() ?? fromNoneStr
				cell.hidesClearButton = workoutList.startDate == nil
				cell.clearAction = {
					self.workoutList.startDate = nil
					self.tableView.beginUpdates()
					self.tableView.reloadRows(at: [IndexPath(row: self.startDateRow, section: 0)], with: .automatic)
					if self.editingDate == .start {
						self.tableView.deleteRows(at: [IndexPath(row: self.editingDateRow!, section: 0)], with: .automatic)
						self.editingDate = .none
					}
					self.tableView.endUpdates()
					self.updateFilterLabel()
				}

				return cell
			case endDateRow:
				let cell = tableView.dequeueReusableCell(withIdentifier: "dateFilter", for: indexPath) as! DateFilterCell
				cell.title.text = toStr
				cell.date.text = workoutList.endDate?.getFormattedDate() ?? toNoneStr
				cell.hidesClearButton = workoutList.endDate == nil
				cell.clearAction = {
					self.workoutList.endDate = nil
					self.tableView.beginUpdates()
					self.tableView.reloadRows(at: [IndexPath(row: self.endDateRow, section: 0)], with: .automatic)
					if self.editingDate == .end {
						self.tableView.deleteRows(at: [IndexPath(row: self.editingDateRow!, section: 0)], with: .automatic)
						self.editingDate = .none
					}
					self.tableView.endUpdates()
					self.updateFilterLabel()
				}

				return cell
			case editingDateRow:
				guard editingDate != .none else {
					fallthrough
				}
				let cell = tableView.dequeueReusableCell(withIdentifier: "datePicker", for: indexPath) as! DatePickerCell

				if editingDate == .start {
					cell.date = workoutList.startDate ?? Date()
					cell.dateChanged = { d in
						let e = self.workoutList.endDate
						self.workoutList.startDate = d
						self.tableView.reloadRows(at: [IndexPath(row: self.startDateRow, section: 0)], with: .automatic)
						if e != self.workoutList.endDate {
							self.tableView.reloadRows(at: [IndexPath(row: self.endDateRow, section: 0)], with: .automatic)
						}
						self.updateFilterLabel()
					}
				} else {
					cell.date = workoutList.endDate ?? Date()
					cell.dateChanged = { d in
						let s = self.workoutList.startDate
						self.workoutList.endDate = d
						self.tableView.reloadRows(at: [IndexPath(row: self.endDateRow, section: 0)], with: .automatic)
						if s != self.workoutList.startDate {
							self.tableView.reloadRows(at: [IndexPath(row: self.startDateRow, section: 0)], with: .automatic)
						}
						self.updateFilterLabel()
					}
				}

				return cell
			default:
				fatalError("Unknown section")
			}
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
			guard [startDateRow, endDateRow].contains(indexPath.row) else {
				break
			}

			let this = indexPath.row == startDateRow ? DateFilter.start : .end
			let other = indexPath.row == startDateRow ? DateFilter.end : .start
			let thisDate = indexPath.row == startDateRow ? \WorkoutList.startDate : \.endDate
			let otherDate = indexPath.row == startDateRow ? \WorkoutList.endDate : \.startDate

			tableView.beginUpdates()
			if editingDate != this, workoutList?[keyPath: thisDate] == nil {
				let o = workoutList?[keyPath: otherDate]
				#warning("This doesn't work but should (Beta 3)")
				// workoutList?[keyPath: thisDate] = Date()
				let today = Date()
				if this == .start {
					workoutList.startDate = today
				} else {
					workoutList.endDate = today
				}
				
				self.tableView.reloadRows(at: [indexPath], with: .automatic)
				if o != workoutList?[keyPath: otherDate] {
					self.tableView.reloadRows(at: [IndexPath(row: indexPath.row == startDateRow ? endDateRow : startDateRow, section: 0)], with: .automatic)
				}
			}

			switch editingDate {
			case other:
				tableView.deleteRows(at: [IndexPath(row: editingDateRow!, section: 0)], with: .right)
				fallthrough
			case .none:
				editingDate = this
				tableView.insertRows(at: [IndexPath(row: editingDateRow!, section: 0)], with: .left)
			case this:
				tableView.deleteRows(at: [IndexPath(row: editingDateRow!, section: 0)], with: .right)
				editingDate = .none
			default:
				break
			}
			tableView.endUpdates()
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

			updateFilterLabel()
			// There are filterList.count + 1 cells in section 1
			tableView.reloadRows(at: (0 ... filterList.count).map { IndexPath(row: $0, section: 1) }, with: .automatic)
		default:
			fatalError("Unknown section")
		}
	}

}
