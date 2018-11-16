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

class MinuteByMinuteBreakdown: AdditionalDataProvider, AdditionalDataProcessor {
	#warning("Test with multiple segments!!")
	/// Segments of the workout, separated by pauses.
	private(set) var segments: [WorkoutSegment]?
	///Specify how details should be displayed and in which order, time detail will be automaticall prepended.
	private(set) var displayDetail: [WorkoutDetail]
	
	/// Display minute-by-minute details for the workout.
	/// - parameter details: The details to display, time will be added as the first one automatically.
	init(details: [WorkoutDetail]) {
		precondition(!details.isEmpty, "Adding no details is meaningless")
		
		self.displayDetail = details
	}
	
	// MARK: - Process Data
	
	func set(workout: Workout) {
		let segments = workout.raw.activeSegments
		self.segments = []
		for (cur, next) in zip(segments, (segments as [DateInterval?])[1...] + [nil]) {
			let s = WorkoutSegment(start: cur.start, end: cur.end,
								   pauseTime: next?.start.timeIntervalSince(cur.end),
								   owner: workout,
								   withStartingMinuteCount: (self.segments?.last?.minutes.last?.minute ?? UInt.max) &+ 1) // 0 for the first segment
			self.segments?.append(s)
		}
	}
	
	func wantData(for typeIdentifier: HKQuantityTypeIdentifier) -> Bool {
		guard segments != nil else {
			return false
		}
		
		return true
	}
	
	func process(data: [HKQuantitySample], for request: WorkoutDataQuery) {
		guard let seg = self.segments else {
			return
		}
		
		var toProcess = data
		for s in seg {
			guard !toProcess.isEmpty else {
				break
			}
			
			toProcess = s.process(data: toProcess, for: request)
		}
	}
	
	// MARK: - Display Data
	
	let sectionHeader: String? = NSLocalizedString("DETAILS_TITLE", comment: "Details")
	let sectionFooter: String? = nil
	
	var numberOfRows: Int {
		return segments?.reduce(0) { $0 + $1.partCount } ?? 0
	}
	
	func cellForRowAt(_ indexPath: IndexPath, for tableView: UITableView) -> UITableViewCell {
		guard let seg = self.segments else {
			fatalError("Workout not set up")
		}
		
		var sum = 0
		for s in seg {
			let n = s.partCount
			if indexPath.row >= sum && indexPath.row < sum + n {
				let i = indexPath.row - sum
				if i < s.minutes.count {
					let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath) as! WorkoutMinuteTableViewCell
					let d = s.minutes[i]
					cell.update(for: displayDetail, withData: d)
					
					return cell
				} else {
					#warning("Implement me")
					fatalError("Display a pause")
				}
			}
			
			sum += n
		}
		
		preconditionFailure("Given index path cannot be rendered")
//		guard let s = seg.first(where: { $0.minutes.count })
//
//		let cell = tableView.dequeueReusableCell(withIdentifier: "detail", for: indexPath) as! WorkoutDetailTableViewCell
//		let d = workout.details![indexPath.row]
//
//		cell.update(for: displayDetail!, withData: d)
//
//		return cell
	}
	
	func export() -> [URL]? {
		#warning("Check me!!")
		guard let seg = self.segments else {
			return []
		}
		
		let export = [.time] + self.displayDetail
		let sep = CSVSeparator
		let data = export.map { $0.name.toCSV() }.joined(separator: sep) + "\n" + seg.map { $0.export(details: export) }.joined()
		
		do {
			let detFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("details.csv")
			try data.write(to: detFile, atomically: true, encoding: .utf8)
			
			return [detFile]
		} catch {
			return nil
		}
	}
	
}
