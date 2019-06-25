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
	private var cancelBtn: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
		
		zones = Preferences.runningHeartZones ?? RunningHeartZones.defaultZones

		editBtn = self.editButtonItem
		self.navigationItem.rightBarButtonItems = [editBtn]
		addZoneBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addZone))
		cancelBtn = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
    }
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()

		return true
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		for i in (0 ..< zones.count).map({ IndexPath(row: $0, section: 1) }) {
			(tableView.cellForRow(at: i) as? HeartZoneCell)?.isEnabled = editing
		}
		
		super.setEditing(editing, animated: animated)
		
		self.navigationItem.setRightBarButtonItems(self.isEditing ? [editBtn, addZoneBtn] : [editBtn], animated:  true)
		self.navigationItem.setLeftBarButton(self.isEditing ? cancelBtn : nil, animated: true)
		self.navigationController?.interactivePopGestureRecognizer?.isEnabled = !self.isEditing
		Preferences.runningHeartZones = self.zones
		
		updateButtons()
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
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 1 {
			return NSLocalizedString("HEART_ZONES_TITLE", comment: "Heart zones")
		}
		
		return nil
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
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		
		let cell = tableView.cellForRow(at: indexPath)
		(cell as? MaxHeartRateCell)?.heartRateField.becomeFirstResponder()
		(cell as? HeartZoneCell)?.lower.becomeFirstResponder()
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
		self.addZoneBtn.isEnabled = self.zones.last ?? 0 < 99
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
		let last = zones.last ?? 55
		zones.append(min(last + 5, 99))
		if let cell = tableView.cellForRow(at: IndexPath(row: zones.count - 2, section: 1)) as? HeartZoneCell {
			setCell(cell, number: zones.count - 2)
		}
		tableView.insertRows(at: [IndexPath(row: zones.count - 1, section: 1)], with: .automatic)
		updateButtons()
	}
	
	@objc private func cancel() {
		self.zones = Preferences.runningHeartZones ?? RunningHeartZones.defaultZones
		tableView.reloadSections([1], with: .automatic)
		self.setEditing(false, animated: true)
	}
	
	fileprivate func thresholdChanged(for cell: HeartZoneCell) {
		guard let index = tableView.indexPath(for: cell), index.section == 1 else {
			return
		}
		
		let p = Int(cell.lower.text ?? "") ?? -1
		zones[index.row] = p
		if p >= 0, p < 100, let cell = tableView.cellForRow(at: IndexPath(row: index.row - 1, section: 1)) as? HeartZoneCell {
			setCell(cell, number: index.row - 1)
		}
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
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		guard editingStyle == .delete, indexPath.section == 1 else {
			return
		}
		
		zones.remove(at: indexPath.row)
		tableView.deleteRows(at: [indexPath], with: .automatic)
		for i in indexPath.row - 1 ..< zones.count {
			if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 1)) as? HeartZoneCell {
				setCell(cell, number: i)
			}
		}
		updateButtons()
	}

}

class MaxHeartRateCell: UITableViewCell {
	
	@IBOutlet private(set) weak var heartRateField: UITextField!
	
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
	@IBOutlet fileprivate private(set) weak var lower: UITextField!
	@IBOutlet private weak var upper: UILabel!
	
	private static let zoneTitle = NSLocalizedString("HEART_ZONES_ZONE_%lld", comment: "Zone x")
	
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
