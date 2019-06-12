//
//  MinuteByMinuteBreakdown.swift
//  Workout
//
//  Created by Marco Boschi on 16/11/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import SwiftUI
import HealthKit
import MBLibrary
import MBHealth

class MinuteByMinuteBreakdown: AdditionalDataProvider, AdditionalDataProcessor {

	private(set) weak var owner: Workout!
	/// Segments of the workout, separated by pauses.
	private(set) var segments: [WorkoutSegment]?
	/// Specify how details should be displayed and in which order, time detail will be automaticall prepended.
	let displayDetail: [WorkoutDetail]
	
	/// Display minute-by-minute details for the workout.
	/// - parameter details: The details to display, time will be added as the first one automatically.
	init(details: [WorkoutDetail]) {
		precondition(!details.isEmpty, "Adding no details is meaningless")
		
		self.displayDetail = details
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
	
	func process(data: [HKQuantitySample], for request: WorkoutDataQuery, reloaded: Bool) {
		_ = self.segments?.reduce(data) { $1.process(data: $0, for: request, reloaded: reloaded) }
	}
	
	// MARK: - Display Data

	override var section: AnyView {
		AnyView(Section(header: Text("MINBYMIN_TITLE")) {
			if self.segments != nil {
				ForEach(self.segments!) { s in
					ForEach(s.minutes) { m in
						WorkoutMinuteCell(workoutMinute: m, details: self.displayDetail)
					}

					if s.pauseTime != nil {
						MessageCell("MINBYMIN_\(s.pauseTime!.getLocalizedDuration())_PAUSE")
					}
				}
			} else {
				MessageCell("WRKT_ERR_LOADING")
			}
		})
	}
	
	override func export() -> [URL]? {
		return []
		#warning("Add back")
//		guard let seg = self.segments else {
//			return []
//		}
//
//		let export = [WorkoutDetail.time] + self.displayDetail
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

private struct WorkoutMinuteCell: View {
	@EnvironmentObject private var preferences: Preferences

	let workoutMinute: WorkoutMinute
	let details: [WorkoutDetail]

	var body: some View {
		HStack {
			ForEach([.time] + details) { d in
				Text(d.display(self.workoutMinute, withSystemOfUnits: self.preferences.systemOfUnits))
					.color(d.color)

				if d !== self.details.last {
					Spacer()
				}
			}
		}
	}

}
