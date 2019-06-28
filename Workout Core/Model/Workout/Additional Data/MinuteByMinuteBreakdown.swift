//
//  MinuteByMinuteBreakdown.swift
//  Workout
//
//  Created by Marco Boschi on 16/11/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit
import MBLibrary
import MBHealth

class MinuteByMinuteBreakdown: AdditionalDataProvider, AdditionalDataProcessor, PreferencesDelegate {

	private weak var preferences: Preferences?
	private var systemOfUnits: SystemOfUnits

	private(set) weak var owner: Workout!
	/// Segments of the workout, separated by pauses.
	private(set) var segments: [WorkoutSegment]?
	/// Specify how details should be displayed and in which order, time detail will be automaticall prepended.
	let displayDetail: [WorkoutDetail]
	
	/// Display minute-by-minute details for the workout.
	/// - parameter details: The details to display, time will be added as the first one automatically.
	init(details: [WorkoutDetail], with preferences: Preferences) {
		precondition(!details.isEmpty, "Adding no details is meaningless")
		
		self.displayDetail = details
		self.preferences = preferences
		self.systemOfUnits = preferences.systemOfUnits

		preferences.add(delegate: self)
	}

	func preferredSystemOfUnitsChanged() {
		if let p = preferences {
			self.systemOfUnits = p.systemOfUnits
		}
	}
	
	// MARK: - Process Data
	
	func set(workout: Workout) {
		owner = workout
		let segments = workout.raw.activeSegments
		self.segments = zip(segments, (segments as [DateInterval?])[1...] + [nil]).reduce(into: [WorkoutSegment]()) { (segments, segInfo) in
			let (cur, next) = segInfo
			segments.append(WorkoutSegment(start: cur.start, end: cur.end,
										   pauseTime: next?.start.timeIntervalSince(cur.end),
										   owner: workout,
										   withStartingMinuteCount: (segments.last?.minutes.last?.minute ?? UInt.max) &+ 1) // 0 for the first segment
			)
		}
	}
	
	func wantData(for typeIdentifier: HKQuantityTypeIdentifier) -> Bool {
		guard segments != nil else {
			return false
		}
		
		return true
	}
	
	func process(data: [HKQuantitySample], for request: WorkoutDataQuery) {
		_ = self.segments?.reduce(data) { $1.process(data: $0, for: request) }
	}
	
	// MARK: - Display Data
	
	public let sectionHeader: String? = NSLocalizedString("MINBYMIN_TITLE", comment: "Details")
	public let sectionFooter: String? = nil

	private static let pauseStr = NSLocalizedString("MINBYMIN_%@_PAUSE", comment: "Pause for mm:ss")
	
	public var numberOfRows: Int {
		return segments?.reduce(0) { $0 + $1.partCount } ?? 0
	}
	
	public func cellForRowAt(_ indexPath: IndexPath, for tableView: UITableView) -> UITableViewCell {
		guard let seg = self.segments else {
			preconditionFailure("Workout not set up")
		}
		
		var sum = 0
		for s in seg {
			let n = s.partCount
			if indexPath.row >= sum && indexPath.row < sum + n {
				let i = indexPath.row - sum
				if i < s.minutes.count {
					let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath) as! WorkoutMinuteTableViewCell
					let d = s.minutes[i]
					cell.update(for: displayDetail, withData: d, andSystemOfUnits: systemOfUnits)
					
					return cell
				} else if let p = s.pauseTime {
					let cell = tableView.dequeueReusableCell(withIdentifier: "msg", for: indexPath)
					cell.textLabel?.text = String(format: MinuteByMinuteBreakdown.pauseStr, p.getFormattedDuration())
					
					return cell
				} else {
					preconditionFailure("Given index path cannot be rendered")
				}
			}
			
			sum += n
		}
		
		preconditionFailure("Given index path cannot be rendered")
	}
	
	public func export() -> [URL]? {
		return []
		#warning("Add Back")
//		guard let seg = self.segments else {
//			return []
//		}
//		
//		let export = [.time] + self.displayDetail
//		let sep = CSVSeparator
//		let data = export.map { $0.getNameAndUnit(for: owner).toCSV() }.joined(separator: sep) + "\n" + seg.map { $0.export(details: export) }.joined()
//		
//		do {
//			let detFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("details.csv")
//			try data.write(to: detFile, atomically: true, encoding: .utf8)
//			
//			return [detFile]
//		} catch {
//			return nil
//		}
	}
	
}
