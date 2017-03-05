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
	
	///Create a new workout detail.
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
	
	static let time = WorkoutDetail(name: "Time", valueFormatter: { (m) in
		return "\(m.minute)m"
	}, exportFormatter: { (m) in
		return m.startTime.getDuration().toCSV()
	}, color: .black)
	
	static let pace = WorkoutDetail(name: "Pace", valueFormatter: { (m) in
		return m.pace?.getFormattedPace()
	}, exportFormatter: { (m) in
		return m.pace?.getDuration().toCSV()
	})
	
	static let speed = WorkoutDetail(name: "Speed", valueFormatter: { (m) in
		return m.speed?.getFormattedSpeed()
	}, exportFormatter: { (m) in
		return m.speed?.toCSV()
	})
	
	static let heart = WorkoutDetail(name: "Heart Rate", valueFormatter: { (m) in
		return m.bpm?.getFormattedHeartRate()
	}, exportFormatter: { (m) in
		return m.bpm?.toCSV()
	})
	
	static let steps = WorkoutDetail(name: "Steps", valueFormatter: { (m) in
		guard let count = m.getTotal(for: .stepCount), let txt = integerF.string(from: NSNumber(value: count)) else {
			return nil
		}
		
		return txt + " " + NSLocalizedString("STEPS", comment: "steps")
	}, exportFormatter: { (m) in
		return m.getTotal(for: .stepCount)?.toCSV()
	})
	
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
