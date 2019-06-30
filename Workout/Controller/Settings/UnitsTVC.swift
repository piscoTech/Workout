//
//  UnitsTableViewController.swift
//  Workout
//
//  Created by Marco Boschi on 26/03/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import UIKit
import WorkoutCore

class UnitsTableViewController: UITableViewController {
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return SystemOfUnits.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "unit", for: indexPath)
		let unit = SystemOfUnits.allCases[indexPath.row]
		cell.textLabel?.text = unit.displayName
		cell.accessoryType = preferences.systemOfUnits == unit ? .checkmark : .none

        return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		preferences.systemOfUnits = SystemOfUnits.allCases[indexPath.row]
		
		for i in 0 ..< SystemOfUnits.allCases.count {
			if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) {
				cell.accessoryType = i == indexPath.row ? .checkmark : .none
			}
		}
		tableView.deselectRow(at: indexPath, animated: true)
	}

}
