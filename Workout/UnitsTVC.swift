//
//  UnitsTableViewController.swift
//  Workout
//
//  Created by Marco Boschi on 26/03/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import UIKit

enum Units: Int, CaseIterable {
	case metric = 0, imperial
	
	var displayName: String {
		return NSLocalizedString("UNITS_NAME_\(self.rawValue)", comment: "Unit name")
	}
	
	/// The default system of units, the metric one.
	static let `default` = Units.metric
	
}

class UnitsTableViewController: UITableViewController {
	
	weak var delegate: AboutViewController!
	private var shouldUpdate = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if shouldUpdate {
			delegate.updateUnits()
			shouldUpdate = false
		}
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Units.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "unit", for: indexPath)
		let unit = Units.allCases[indexPath.row]
		cell.textLabel?.text = unit.displayName
		cell.accessoryType = Preferences.systemOfUnits == unit ? .checkmark : .none

        return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		Preferences.systemOfUnits = Units.allCases[indexPath.row]
		shouldUpdate = true
		
		for i in 0 ..< Units.allCases.count {
			if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) {
				cell.accessoryType = i == indexPath.row ? .checkmark : .none
			}
		}
		tableView.deselectRow(at: indexPath, animated: true)
	}

}
