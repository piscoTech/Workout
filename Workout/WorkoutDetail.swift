//
//  WorkoutDetail.swift
//  Workout
//
//  Created by Marco Boschi on 05/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit

class WorkoutDetail {
	
	static let noData = "–"
	
	let name: String
	private let color: UIColor
	private let displayer: (WorkoutMinute) -> String?
	private let exporter: (WorkoutMinute) -> String?
	
	///Create a new workout detail to present values stored inside a `WorkoutMinute`.
	///- parameter name: The name of the detail used as header when exporting.
	///- parameter valueFormatter: A block called to format the value for display on screen, return `nil` if the value is not available.
	///- parameter exportFormatter: A block called to format the value for exporting, return `nil` if the value is not available, remember to invoke `.toCSV()` inside the block.
	private init(name: String, valueFormatter v: @escaping (WorkoutMinute) -> String?, exportFormatter e: @escaping (WorkoutMinute) -> String?, color c: UIColor = #colorLiteral(red: 0.5568627451, green: 0.5568627451, blue: 0.5764705882, alpha: 1)) {
		self.name = name
		self.color = c
		self.displayer = v
		self.exporter = e
	}
	
	func newView() -> UILabel {
		let res = UILabel()
		res.textColor = color
		
		return res
	}
	
	func update(view: UILabel, with val: WorkoutMinute) {
		view.text = displayer(val) ?? WorkoutDetail.noData
	}
	
	func export(val: WorkoutMinute) -> String {
		return exporter(val) ?? ""
	}
	
	///Provides information about the time.
	static let time = WorkoutDetail(name: "Time", valueFormatter: { (m) in
		return "\(m.minute)m"
	}, exportFormatter: { (m) in
		return m.startTime.getDuration().toCSV()
	}, color: .black)
	
	///Provides the average pace in seconds per kilometer.
	static let pace = WorkoutDetail(name: "Pace", valueFormatter: { (m) in
		return m.pace?.getFormattedPace(forLengthUnit: m.owner.paceUnit)
	}, exportFormatter: { (m) in
		return m.pace?.getDuration().toCSV()
	})
	
	///Provides the average speed in kilometer per hour.
	static let speed = WorkoutDetail(name: "Speed", valueFormatter: { (m) in
		return m.speed?.getFormattedSpeed(forLengthUnit: m.owner.speedUnit)
	}, exportFormatter: { (m) in
		return m.speed?.toCSV()
	})
	
	///Provides the average heart rate.
	static let heart = WorkoutDetail(name: "Heart Rate", valueFormatter: { (m) in
		return m.bpm?.getFormattedHeartRate()
	}, exportFormatter: { (m) in
		return m.bpm?.toCSV()
	})
	
	///Provides the number of steps.
	static let steps = WorkoutDetail(name: "Steps", valueFormatter: { (m) in
		guard let count = m.getTotal(for: .stepCount), let txt = integerF.string(from: NSNumber(value: count)) else {
			return nil
		}
		
		return txt + " " + NSLocalizedString("STEPS", comment: "steps")
	}, exportFormatter: { (m) in
		return m.getTotal(for: .stepCount)?.toCSV()
	})
	
	///Provides the number of strokes.
	@available(iOS 10, *)
	static let strokes = WorkoutDetail(name: "Strokes", valueFormatter: { (m) in
		guard let count = m.getTotal(for: .swimmingStrokeCount), let txt = integerF.string(from: NSNumber(value: count)) else {
			return nil
		}
		
		return txt + " " + NSLocalizedString("STROKES", comment: "strokes")
	}, exportFormatter: { (m) in
		return m.getTotal(for: .swimmingStrokeCount)?.toCSV()
	})
	
}
