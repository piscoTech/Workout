//
//  RunningHeartZones.swift
//  Workout
//
//  Created by Marco Boschi on 28/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit
import MBLibrary

class RunningHeartZones: AdditionalDataProcessor, AdditionalDataProvider {
	
	#warning("Fix me according to GitHub issue")
	static let defaultZones = [60, 70, 80, 90]
	/// The maximum valid between two samples.
	static let maxInterval: TimeInterval = 60
	
	private var maxHeartRate: Int!
	private var zones: [Int]!
	private var zonesData: [TimeInterval]?
	
	// MARK: - Process data
	
	func wantData(for typeIdentifier: HKQuantityTypeIdentifier) -> Bool {
		return typeIdentifier == .heartRate
	}
	
	private func zone(for s: HKQuantitySample) -> Int? {
		return nil
	}
	
	func process(data: [HKQuantitySample]) {
		#warning("Implement me")
//		guard let maxHeartRate = Preferences.maxHeartRate else {
//			return
//		}
//		self.maxHeartRate = maxHeartRate
		zones = /* Preferences.runningHeartZones ?? */ RunningHeartZones.defaultZones
		zonesData = [TimeInterval](repeating: 0, count: zones.count)
		
		var previous: HKQuantitySample?
		for s in data {
			defer {
				previous = s
			}
			
			guard let prev = previous else {
				continue
			}
			
			let time = s.startDate.timeIntervalSince(prev.startDate)
			guard time <= RunningHeartZones.maxInterval else {
				continue
			}
			
			let pZone = zone(for: prev)
			let cZone = zone(for: s)
			
			if let c = cZone, pZone == c {
				zonesData?[c] += time
			} else if let p = pZone, let c = cZone, abs(p - c) == 1 {
				// split time according to a linear interpolation
			}
		}
	}
	
	// MARK: - Display data
	
	let preferAppearanceBeforeDetails = true
	
	let sectionHeader: String? = NSLocalizedString("HEART_ZONES_TITLE", comment: "Heart zones")
	
	var numberOfRows: Int {
		return zonesData?.count ?? 1
	}
	
	func cellForRowAt(_ indexPath: IndexPath, for tableView: UITableView) -> UITableViewCell {
		guard let data = zonesData?[indexPath.row] else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "msg", for: indexPath)
			cell.textLabel?.text = NSLocalizedString("HEART_ZONES_NEED_CONFIG", comment: "Need config")
			
			return cell
		}
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath)
		cell.textLabel?.text = String(format: NSLocalizedString("HEART_ZONE", comment: "Zone x"), indexPath.row + 1)
		cell.detailTextLabel?.text = data > 0 ? data.getDuration() : WorkoutDetail.noData
		
		return cell
	}
	
	func export() -> [URL]? {
		#warning("Implement me")
		fatalError()
	}
	
	
}
