//
//  RouteTypeTableViewController.swift
//  Workout
//
//  Created by Marco Boschi on 22/12/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import UIKit
import WorkoutCore

class RouteTypeTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return RouteType.allCases.count
    }

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "type", for: indexPath)
		let type = RouteType.allCases[indexPath.row]
		cell.textLabel?.text = type.displayName
		cell.accessoryType = preferences.routeType == type ? .checkmark : .none

		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		preferences.routeType = RouteType.allCases[indexPath.row]

		for i in 0 ..< RouteType.allCases.count {
			if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) {
				cell.accessoryType = i == indexPath.row ? .checkmark : .none
			}
		}
		tableView.deselectRow(at: indexPath, animated: true)
	}

}
