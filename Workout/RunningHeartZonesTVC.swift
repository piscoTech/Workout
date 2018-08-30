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
	private var zones: [Int]!
	private weak var editBtn: UIBarButtonItem!
	private var addZoneBtn: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
		
		#warning("Implement me")
		zones = /* Preferences.runningHeartZones ?? */ RunningHeartZones.defaultZones

		editBtn = self.editButtonItem
		self.navigationItem.rightBarButtonItems = [editBtn]
		addZoneBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addZone))
    }
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()

		return true
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		self.navigationItem.setRightBarButtonItems(self.isEditing ? [editBtn, addZoneBtn] : [editBtn], animated:  true)
		for i in (0 ..< zones.count).map({ IndexPath(row: $0, section: 1) }) {
			(tableView.cellForRow(at: i) as? HeartZoneCell)?.isEnabled = self.isEditing
		}
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
		} else {
			return zones.count
		}
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			let cell = tableView.dequeueReusableCell(withIdentifier: "maxRate", for: indexPath) as! MaxHeartRateCell
			cell.setHeartRate(Preferences.maxHeartRate)
			
			return cell
		} else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "zone", for: indexPath) as! HeartZoneCell
			setCell(cell, number: indexPath.row)
			
			return cell
		}
    }
	
	private func setCell(_ cell: HeartZoneCell, number n: Int) {
		cell.setRange(from: zones[n], to: n == zones.count - 1 ? nil : zones[n + 1])
		cell.setZoneNumber(n + 1)
		cell.isEnabled = self.isEditing
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
	
	// MARK: - Edit zones
	
	private func updateButtons() {
		self.editBtn.isEnabled = !self.isEditing || filterZones(inTable: false).count > 1
	}
	
	private func filterZones(inTable: Bool) -> [Int] {
		var res: [Int] = self.zones
		
		var i = 0
		var row = 0
		while i < res.count {
			defer {
				row += 1
			}
			
			guard res[i] >= 0, res[i] < 100, i == 0 || res[i] > res[i - 1] else {
				res.remove(at: i)
				if inTable {
					tableView.deleteRows(at: [IndexPath(row: row, section: 1)], with: .automatic)
				}
				continue
			}
			
			i += 1
		}
		
		return res
	}
	
	@objc private func addZone() {
		#warning("Implement me")
		print("Add zone")
	}
	
	fileprivate func thresholdChanged(for cell: HeartZoneCell) {
		guard let index = tableView.indexPath(for: cell), index.section == 1 else {
			return
		}
		
		zones[index.row] = Int(cell.lower.text ?? "") ?? -1
		updateButtons()
	}
	
	fileprivate func thresholdFinishedChanging(for cell: HeartZoneCell) {
		guard let index = tableView.indexPath(for: cell), index.section == 1 else {
			return
		}
		
		cell.lower.text = zones[index.row].description
		tableView.beginUpdates()
		self.zones = filterZones(inTable: true)
		tableView.endUpdates()
		
		for (c, n) in (0 ..< zones.count).lazy.map({ IndexPath(row: $0, section: 1) }).map({ (self.tableView.cellForRow(at: $0) as? HeartZoneCell, $0.row) }) {
			if let c = c {
				setCell(c, number: n)
			}
		}
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

class HeartZoneCell: UITableViewCell {
	
	@IBOutlet private weak var delegate: RunningHeartZonesTableViewController!
	
	@IBOutlet private weak var title: UILabel!
	@IBOutlet fileprivate weak var lower: UITextField!
	@IBOutlet private weak var upper: UILabel!
	
	private static let zoneTitle = NSLocalizedString("HEART_ZONE", comment: "Zone x")
	
	var isEnabled: Bool {
		get {
			return lower.isEnabled
		}
		set {
			lower.isEnabled = newValue
			if !newValue {
				lower.resignFirstResponder()
			}
		}
	}
	
	func setZoneNumber(_ n: Int) {
		title.text = String(format: HeartZoneCell.zoneTitle, n)
	}

	func setRange(from: Int, to: Int?) {
		lower.text = from.description
		upper.text = (to?.description ?? "100") + " %"
	}
	
	@IBAction func thresholdChanged() {
		delegate.thresholdChanged(for: self)
	}
	
	@IBAction func thresholdFinishedChanging() {
		delegate.thresholdFinishedChanging(for: self)
	}
	
}
