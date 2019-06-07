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

class FilterListTableViewController: UITableViewController {
	
	weak var delegate: ListTableViewController?
	var availableFilters: [HKWorkoutActivityType]! {
		didSet {
			defer {
				tableView.reloadSections([0, 1], with: .automatic)
				updateFiltersCount()
			}
			
			guard var unique = availableFilters else {
				selected = []
				filterList = []
				
				return
			}
			unique.removeDuplicates()
			
			let oldSel = zip(filterList, 0 ..< filterList.count).filter { selected.contains($0.1) }.map { $0.0.type }
			filterList = unique.map { ($0, $0.name)}.sorted { $0.1 < $1.1 }
			selected = zip(filterList, 0 ..< filterList.count).filter { oldSel.contains($0.0.type) }.map { $0.1 }
			
			updateFiltersCount()
		}
	}
	var selectedFilters: [HKWorkoutActivityType]! {
		didSet {
			selected = zip(filterList, 0 ..< filterList.count).filter { selectedFilters.contains($0.0.type) }.map { $0.1 }
			updateFiltersCount()
		}
	}
	
	private var filterList: [(type: HKWorkoutActivityType, name: String)] = []
	private var selected: [Int] = []
	
	@IBOutlet private weak var filtersCountLbl: UILabel!
	
	private let allStr = NSLocalizedString("FILTER_ALL", comment: "All wrkt")
	private let oneStr = NSLocalizedString("FILTER_COUNT", comment: "1/x")
	private let manyStr = NSLocalizedString("FILTERS_COUNT", comment: "y/x")

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	@IBAction func done(_ sender: AnyObject) {
		self.dismiss(animated: true)
	}
	
	private func updateFiltersCount() {
		if selected.isEmpty {
			filtersCountLbl.text = allStr
		} else {
			filtersCountLbl.text = String(format: selected.count > 1 ? manyStr : oneStr, selected.count, filterList.count)
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
			cell.textLabel?.text = NSLocalizedString("FILTER_ALL", comment: "All")
			cell.accessoryType = selected.count == 0 ? .checkmark : .none
		} else {
			cell.textLabel?.text = filterList[indexPath.row].name
			cell.accessoryType = selected.contains(indexPath.row) ? .checkmark : .none
		}

        return cell
    }
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let allSelected = {
			self.selected = []
			tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.accessoryType = .checkmark
			for i in 0 ..< self.filterList.count {
				tableView.cellForRow(at: IndexPath(row: i, section: 1))?.accessoryType = .none
			}
		}
		if indexPath.section == 0 {
			allSelected()
		} else {
			if selected.contains(indexPath.row) {
				selected.removeElement(indexPath.row)
				tableView.cellForRow(at: indexPath)?.accessoryType = .none
				if selected.isEmpty {
					tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.accessoryType = .checkmark
				}
			} else {
				selected.append(indexPath.row)
				if selected.count == filterList.count {
					allSelected()
				} else {
					tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.accessoryType = .none
					tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
				}
			}
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
		updateFiltersCount()
		
		delegate?.filters = zip(filterList, 0 ..< filterList.count).filter { selected.contains($0.1) }.map { $0.0.type }
	}

}
