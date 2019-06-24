//
//  RunningHeartZones.swift
//  Workout
//
//  Created by Marco Boschi on 28/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import HealthKit
import Combine
import SwiftUI
import MBLibrary

class RunningHeartZones: AdditionalDataProvider, AdditionalDataProcessor {
	
	static let defaultZones = [60, 70, 80, 94]
	/// The maximum valid time between two samples.
	static let maxInterval: TimeInterval = 60

	private(set) weak var owner: Workout!

	private var maxHeartRate: Double?
	private var zones: [Int]?
	private var cancellable: Cancellable?

	private var rawHeartData: [HKQuantitySample]?
	private var zonesData: [TimeInterval]?

	init(with preferences: Preferences) {
		super.init()

		let preprocess = preferences.didChange.prepend(preferences)
			.map { ($0.maxHeartRate, $0.runningHeartZones) }
			.removeDuplicates(by: { $0.0 == $1.0 && $0.1 == $1.1 })
		#warning("Add debounce before sink to avoid double checking when saving both HZ and max HR")
		//			.debounce(0.2, scheduler: DispatchQueue.background)
		self.cancellable = preprocess.sink { [weak self] (maxHR, zones) in
				if let hr = maxHR {
					self?.maxHeartRate = Double(hr)
				} else {
					self?.maxHeartRate = nil
				}
				self?.zones = zones

				self?.updateZones()
			}
	}
	
	// MARK: - Process Data

	func set(workout: Workout) {
		owner = workout
	}
	
	func wantData(for typeIdentifier: HKQuantityTypeIdentifier) -> Bool {
		return typeIdentifier == .heartRate
	}
	
	func process(data: [HKQuantitySample], for _: WorkoutDataQuery, reloaded _: Bool) {
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
		defer {
			#warning("Force receive on main thread until receive(on:) is not available (Xcode bug)")
			DispatchQueue.main.async {
				self.owner?.didChange.send(())
			}
		}

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

	override func cancel() {
		self.cancellable?.cancel()
		self.cancellable = nil
	}
	
	// MARK: - Display Data

	override var section: AnyView {
		AnyView(Section(header: Text("HEART_ZONES_TITLE"), footer: zonesData == nil
			? AnyView(EmptyView())
			: AnyView(Text("HEART_ZONES_FOOTER").lineLimit(nil))
		) {
			if zonesData == nil {
				MessageCell("HEART_ZONES_NEED_CONFIG")
			} else {
				ForEach(zoneData!.enumerated()) { (zone, time) in
					HStack {
						Text()
						Spacer()
						Text(time > 0 ? time.getLocalizedDuration() : missingData).foregroundColor(.secondary)
					}
				}
				Text("Data")
//				let cell = tableView.dequeueReusableCell(withIdentifier: "basic", for: indexPath)
//				cell.textLabel?.text = String(format: RunningHeartZones.zoneTitle, indexPath.row + 1)
//				cell.detailTextLabel?.text = data > 0 ? data.getDuration() : WorkoutDetail.noData
			}
		})
	}
	
	override func export() -> [URL]? {
		guard let zonesData = self.zonesData else {
			return []
		}

		#warning("Add Back")
		return []
		
//		let sep = CSVSeparator
//		var zones = "Zone\(sep)Time\n"
//		var i = 1
//		for t in zonesData {
//			zones += "\(i)\(sep)\(t.getDuration().toCSV())\n"
//			i += 1
//		}
//
//		do {
//			let hzFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("heartZones.csv")
//			try zones.write(to: hzFile, atomically: true, encoding: .utf8)
//
//			return [hzFile]
//		} catch {
//			return nil
//		}
	}
	
}
