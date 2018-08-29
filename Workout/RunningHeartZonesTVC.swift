//
//  RunningHeartZonesTableViewController.swift
//  Workout
//
//  Created by Marco Boschi on 29/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit

class RunningHeartZonesTableViewController: UITableViewController, UITextFieldDelegate {
	
	weak var delegate: AboutViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()

		return true
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if section == 0 {
			return NSLocalizedString("HEART_ZONES_EXPLANATION", comment: "Explain heart zone")
		}
		
		return nil
	}
	
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return 1
		}
		
		return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "maxRate", for: indexPath) as! MaxHeartRateCell
		cell.setHeartRate(Preferences.maxHeartRate)

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1 && tableView.isEditing
    }
	
	// MARK: - Max heart rate
	
	@IBAction func maxHeartRateChanged(_ sender: UITextField) {
		Preferences.maxHeartRate = Int(sender.text ?? "")
		delegate.updateMaxHeartRate()
	}
	
	@IBAction func maxHeartRateDone(_ sender: UITextField) {
		(tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? MaxHeartRateCell)?.setHeartRate(Preferences.maxHeartRate)
	}

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

}

class MaxHeartRateCell: UITableViewCell {
	
	@IBOutlet private weak var heartRateField: UITextField!
	
	func setHeartRate(_ hr: Int?) {
		heartRateField.text = hr?.description ?? ""
	}
	
	var isEnabled: Bool {
		get {
			return heartRateField.isEnabled
		}
		set {
			heartRateField.isEnabled = newValue
			if !newValue {
				heartRateField.resignFirstResponder()
			}
		}
	}
	
}
