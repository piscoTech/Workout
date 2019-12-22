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

public class RunningHeartZones: AdditionalDataProcessor, AdditionalDataProvider, PreferencesDelegate {

	private weak var preferences: Preferences?

	public static let defaultZones = [60, 70, 80, 94]
	/// The maximum valid time between two samples.
	static let maxInterval: TimeInterval = 60

	private var maxHeartRate: Double?
	private var zones: [Int]?

	private var rawHeartData: [HKQuantitySample]?
	private var zonesData: [TimeInterval]?

	init(with preferences: Preferences) {
		self.preferences = preferences
		preferences.add(delegate: self)
		runningHeartZonesConfigChanged()
	}

	public func runningHeartZonesConfigChanged() {
		if let hr = preferences?.maxHeartRate {
			self.maxHeartRate = Double(hr)
		} else {
			self.maxHeartRate = nil
		}
		self.zones = preferences?.runningHeartZones

		self.updateZones()
	}

	// MARK: - Process Data

	func wantData(for typeIdentifier: HKQuantityTypeIdentifier) -> Bool {
		return typeIdentifier == .heartRate
	}

	func process(data: [HKQuantitySample], for _: WorkoutDataQuery) {
		self.rawHeartData = data
		updateZones()
	}

	private func zone(for s: HKQuantitySample, in zones: [Double]) -> Int? {
		guard let maxHR = maxHeartRate else {
			return nil
		}

		let p = s.quantity.doubleValue(for: WorkoutUnit.heartRate.default) / maxHR
		return zones.lastIndex { p >= $0 }
	}

	private func updateZones() {
		guard let maxHR = maxHeartRate, let data = rawHeartData else {
			zonesData = nil
			return
		}
		let zones = (self.zones ?? RunningHeartZones.defaultZones).map({ Double($0) / 100 })
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

			let pZone = zone(for: prev, in: zones)
			let cZone = zone(for: s, in: zones)

			if let c = cZone, pZone == c {
				zonesData?[c] += time
			} else if let p = pZone, let c = cZone, abs(p - c) == 1 {
				let pH = prev.quantity.doubleValue(for: WorkoutUnit.heartRate.default) / maxHR
				let cH = s.quantity.doubleValue(for: WorkoutUnit.heartRate.default) / maxHR
				/// Threshold between zones
				let th = zones[max(p, c)]

				guard th >= min(pH, cH), th <= max(pH, cH) else {
					continue
				}

				/// Incline of a line joining the two data points
				let m = (cH - pH) / time
				/// The time after the previous data point when the zone change
				let change = (th - pH) / m

				zonesData?[p] += change
				zonesData?[c] += time - change
			}
		}
	}

	// MARK: - Display Data

	private static let header = NSLocalizedString("HEART_ZONES_TITLE", comment: "Heart zones")
	private static let footer = NSLocalizedString("HEART_ZONES_FOOTER", comment: "Can be less than total")
	private static let zoneTitle = NSLocalizedString("HEART_ZONES_ZONE_%lld", comment: "Zone x")
	private static let zoneConfig = NSLocalizedString("HEART_ZONES_NEED_CONFIG", comment: "Zone config")

	public let sectionHeader: String? = RunningHeartZones.header
	public var sectionFooter: String? {
		return zonesData == nil ? nil : RunningHeartZones.footer
	}

	public var numberOfRows: Int {
		return zonesData?.count ?? 1
	}

	public func cellForRowAt(_ indexPath: IndexPath, for tableView: UITableView) -> UITableViewCell {
		guard let data = zonesData?[indexPath.row] else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "msg", for: indexPath)
			cell.textLabel?.text = RunningHeartZones.zoneConfig

			return cell
		}

		let cell = tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath)
		cell.textLabel?.text = String(format: RunningHeartZones.zoneTitle, indexPath.row + 1)
		cell.detailTextLabel?.text = data > 0 ? data.formattedDuration : missingValueStr

		return cell
	}

	public func export(for preferences: Preferences, _ callback: @escaping ([URL]?) -> Void) {
		DispatchQueue.background.async {
			guard let zonesData = self.zonesData else {
				callback([])
				return
			}

			let hzFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("heartZones.csv")
			guard let file = OutputStream(url: hzFile, append: false) else {
				callback(nil)
				return
			}

			let sep = CSVSeparator
			do {
				file.open()
				defer{
					file.close()
				}

				try file.write("Zone\(sep)Time\n")
				for (i, t) in zonesData.enumerated() {
					try file.write("\(i + 1)\(sep)\(t.rawDuration().toCSV())\n")
				}

				callback([hzFile])
			} catch {
				callback(nil)
			}
		}
	}

}
