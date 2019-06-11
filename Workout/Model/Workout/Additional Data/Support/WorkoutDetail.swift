//
//  WorkoutDetail.swift
//  Workout
//
//  Created by Marco Boschi on 05/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import HealthKit
import SwiftUI
import MBLibrary

class WorkoutDetail: Identifiable {

	let id = UUID()
	let name: String

	func getNameAndUnit(for owner: Workout, andSystemOfUnits system: SystemOfUnits) -> String {
		guard let uf = unitFormatter else {
			return name
		}

		return "\(name) \(uf(owner, system))"
	}

	private let unitFormatter: ((Workout, SystemOfUnits) -> String)?
	private let displayer: (WorkoutMinute, SystemOfUnits) -> LocalizedStringKey?
	let color: Color
	private let exporter: (WorkoutMinute, SystemOfUnits) -> String?
	
	///Create a new workout detail to present values stored inside a `WorkoutMinute`.
	///- parameter name: The name of the detail used as header when exporting.
	///- parameter valueFormatter: A block called to format the value for display on screen, return `nil` if the value is not available.
	///- parameter exportFormatter: A block called to format the value for exporting, return `nil` if the value is not available, remember to invoke `.toCSV()` inside the block.
	private init(name: String, unitFormatter u: ((Workout, SystemOfUnits) -> String)? = nil, valueFormatter v: @escaping (WorkoutMinute, SystemOfUnits) -> LocalizedStringKey?, exportFormatter e: @escaping (WorkoutMinute, SystemOfUnits) -> String?, color: Color = .secondary) {
		self.name = name
		self.unitFormatter = u
		self.displayer = v
		self.color = color
		self.exporter = e
	}
	
	func display(_ val: WorkoutMinute, withSystemOfUnits system: SystemOfUnits) -> LocalizedStringKey {
		displayer(val, system) ?? missingValue
	}
	
	func export(_ val: WorkoutMinute, withSystemOfUnits system: SystemOfUnits) -> String {
		return exporter(val, system) ?? ""
	}

	private static let timeFormatter: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .abbreviated
		formatter.allowedUnits = [.hour, .minute]
		formatter.zeroFormattingBehavior = .default

		return formatter
	}()

	///Provides information about the time.
	static let time = WorkoutDetail(name: "Time", valueFormatter: { (m, _) in
		LocalizedStringKey(WorkoutDetail.timeFormatter.string(from: TimeInterval(m.minute) * 60)!)
	}, exportFormatter: { (m, _) in
		return (TimeInterval(m.minute) * 60).getRawDuration().toCSV()
	}, color: .primary)
	
	///Provides the average pace in seconds per kilometer.
	static let pace = WorkoutDetail(name: "Pace", unitFormatter: { "time/\($0.paceUnit.unit(for: $1))" }, valueFormatter: { (m, s) in
		guard let pace = m.pace else {
			return nil
		}

		return LocalizedStringKey(pace.formatAsPace(withReferenceLength: m.owner.paceUnit.unit(for: s)))
	}, exportFormatter: { (m, s) in
		guard let pace = m.pace else {
			return nil
		}

		let unit = HKUnit.second().unitDivided(by: m.owner.paceUnit.unit(for: s))
		return pace.doubleValue(for: unit).getRawDuration().toCSV()
	})

//	///Provides the average speed in the specified `speedUnit` per hour.
//	static let speed = WorkoutDetail(name: "Speed", unitFormatter: { "\($0.speedUnit.description)/h" }, valueFormatter: { (m) in
//		return m.speed?.getFormattedSpeed(forLengthUnit: m.owner.speedUnit.unit)
//	}, exportFormatter: { (m) in
//		return m.speed?.toCSV()
//	})
//
//	///Provides the average heart rate.
//	static let heart = WorkoutDetail(name: "Heart Rate", valueFormatter: { (m) in
//		return m.bpm?.getFormattedHeartRate()
//	}, exportFormatter: { (m) in
//		return m.bpm?.toCSV()
//	})
//
//	///Provides the number of steps.
//	static let steps = WorkoutDetail(name: "Steps", valueFormatter: { (m) in
//		guard let count = m.getTotal(for: .stepCount), let txt = integerF.string(from: NSNumber(value: count)) else {
//			return nil
//		}
//
//		return txt + " " + NSLocalizedString("STEPS", comment: "steps")
//	}, exportFormatter: { (m) in
//		return m.getTotal(for: .stepCount)?.toCSV()
//	})
//
//	///Provides the number of strokes.
//	static let strokes = WorkoutDetail(name: "Strokes", valueFormatter: { (m) in
//		guard let count = m.getTotal(for: .swimmingStrokeCount), let txt = integerF.string(from: NSNumber(value: count)) else {
//			return nil
//		}
//
//		return txt + " " + NSLocalizedString("STROKES", comment: "strokes")
//	}, exportFormatter: { (m) in
//		return m.getTotal(for: .swimmingStrokeCount)?.toCSV()
//	})
	
}
