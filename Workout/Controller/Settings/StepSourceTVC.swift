//
//  StepSourceTableViewController.swift
//  Workout
//
//  Created by Marco Boschi on 06/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit

class StepSourceTableViewController: UITableViewController, UITextFieldDelegate {
	
	@IBOutlet weak var customSource: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		let row: Int
		switch preferences.stepSourceFilter {
		case .all:
			row = 0
		case .iPhone:
			row = 1
		case .watch:
			row = 2
		case let .custom(str):
			customSource.text = str
			row = 3
		}
		
		tableView.cellForRow(at: IndexPath(row: row, section: 0))?.accessoryType = .checkmark
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		switch indexPath.row {
		case 0:
			preferences.stepSourceFilter = .all
		case 1:
			preferences.stepSourceFilter = .iPhone
		case 2:
			preferences.stepSourceFilter = .watch
		default:
			customSource.becomeFirstResponder()
		}
		
		func setCheckmark() {
			for i in 0 ..< 4 {
				tableView.cellForRow(at: IndexPath(row: i, section: 0))?.accessoryType = .none
			}
			tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
		}
		
		if indexPath.row != 3 {
			customSource.text = ""
			customSource.resignFirstResponder()
			setCheckmark()
		} else if let txt = customSource.text, txt != "" {
			setCheckmark()
			preferences.stepSourceFilter = .custom(txt)
		}
	}
	
	@IBAction func customSourceDidChange(_ sender: AnyObject) {
		let str = customSource.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
		
		if str != "" {
			for i in 0 ..< 4 {
				tableView.cellForRow(at: IndexPath(row: i, section: 0))?.accessoryType = .none
			}
			tableView.cellForRow(at: IndexPath(row: 3, section: 0))?.accessoryType = .checkmark
			
			preferences.stepSourceFilter = .custom(str)
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		
		return true
	}

}
