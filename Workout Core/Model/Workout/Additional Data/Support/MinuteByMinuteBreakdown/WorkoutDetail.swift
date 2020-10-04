//
//  WorkoutDetail.swift
//  Workout
//
//  Created by Marco Boschi on 05/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit
import MBLibrary

class WorkoutDetail {

	private static let primaryColor: UIColor = {
		if #available(iOS 13.0, *) {
			return .label
		} else {
			return .black
		}
	}()

	private static let secondaryColor: UIColor = {
		if #available(iOS 13.0, *) {
			return .secondaryLabel
		} else {
			return #colorLiteral(red: 0.5568627451, green: 0.5568627451, blue: 0.5764705882, alpha: 1)
		}
	}()

	let name: String

	func getNameAndUnit(for owner: Workout, andSystemOfUnits system: SystemOfUnits) -> String {
		guard let uf = unitFormatter else {
			return name
		}

		return "\(name) \(uf(owner, system))"
	}

	private let color: UIColor
	private let unitFormatter: ((Workout, SystemOfUnits) -> String)?
	private let displayer: (WorkoutMinute, SystemOfUnits) -> String?
	private let exporter: (WorkoutMinute, SystemOfUnits) -> String?

	///Create a new workout detail to present values stored inside a `WorkoutMinute`.
	///- parameter name: The name of the detail used as header when exporting.
	///- parameter valueFormatter: A block called to format the value for display on screen, return `nil` if the value is not available.
	///- parameter exportFormatter: A block called to format the value for exporting, return `nil` if the value is not available, remember to invoke `.toCSV()` inside the block.
	private init(name: String, unitFormatter u: ((Workout, SystemOfUnits) -> String)? = nil, valueFormatter v: @escaping (WorkoutMinute, SystemOfUnits) -> String?, exportFormatter e: @escaping (WorkoutMinute, SystemOfUnits) -> String?, color: UIColor = WorkoutDetail.secondaryColor) {
		self.name = name
		self.unitFormatter = u
		self.displayer = v
		self.color = color
		self.exporter = e
	}

	func display(_ val: WorkoutMinute, withSystemOfUnits system: SystemOfUnits) -> UILabel {
		let res = UILabel()
		res.textColor = color

		res.text = displayer(val, system) ?? missingValueStr
		return res
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
		WorkoutDetail.timeFormatter.string(from: TimeInterval(m.number) * 60)!
	}, exportFormatter: { (m, _) in
		(TimeInterval(m.minute) * 60).rawDuration().toCSV()
	}, color: WorkoutDetail.primaryColor)

	/// Provides the average pace.
	static let pace = WorkoutDetail(name: "Pace", unitFormatter: { "time/\($0.paceUnit.unit(for: $1))" }, valueFormatter: { (m, s) in
		guard let pace = m.pace else {
			return nil
		}

		return pace.formatAsPace(withReferenceLength: m.owner.paceUnit.unit(for: s))
	}, exportFormatter: { (m, s) in
		guard let pace = m.pace else {
			return nil
		}

		let unit = HKUnit.second().unitDivided(by: m.owner.paceUnit.unit(for: s))
		return pace.doubleValue(for: unit).rawDuration().toCSV()
	})

	/// Provides the average speed.
	static let speed = WorkoutDetail(name: "Speed", unitFormatter: { $0.speedUnit.unit(for: $1).symbol }, valueFormatter: { (m, s) in
		guard let speed = m.speed else {
			return nil
		}

		return speed.formatAsSpeed(withUnit: m.owner.speedUnit.unit(for: s))
	}, exportFormatter: { (m, s) in
		guard let speed = m.speed else {
			return nil
		}

		return speed.doubleValue(for: m.owner.speedUnit.unit(for: s)).toCSV()
	})

	/// Provides the average heart rate.
	static let heart = WorkoutDetail(name: "Heart Rate", valueFormatter: { (m, s) in
		guard let bpm = m.heartRate else {
			return nil
		}

		return bpm.formatAsHeartRate(withUnit: WorkoutUnit.heartRate.unit(for: s))
	}, exportFormatter: { (m, s) in
		return m.heartRate?.doubleValue(for: WorkoutUnit.heartRate.unit(for: s)).toCSV()
	})

	//	"STROKES" = "strokes";

	private static let stepStr = NSLocalizedString("%lld_STEPS", comment: "%d step(s)")
	///Provides the number of steps.
	static let steps = WorkoutDetail(name: "Steps", valueFormatter: { (m, s) in
		guard let steps = m.getTotal(for: .stepCount)?.doubleValue(for: WorkoutUnit.steps.unit(for: s)), round(steps) > 0 else {
			return nil
		}

		return String(format: WorkoutDetail.stepStr, Int(round(steps)))
	}, exportFormatter: { (m, s) in
		guard let steps = m.getTotal(for: .stepCount)?.doubleValue(for: WorkoutUnit.steps.unit(for: s)), steps > 0 else {
			return nil
		}

		return steps.toCSV()
	})

	private static let strokesStr = NSLocalizedString("%lld_STROKES", comment: "%d stroke(s)")
	///Provides the number of strokes.
	static let strokes = WorkoutDetail(name: "Strokes", valueFormatter: { (m, s) in
		guard let strokes = m.getTotal(for: .swimmingStrokeCount)?.doubleValue(for: WorkoutUnit.strokes.unit(for: s)), round(strokes) > 0 else {
			return nil
		}

		return String(format: WorkoutDetail.strokesStr, Int(round(strokes)))
	}, exportFormatter: { (m, s) in
		guard let strokes = m.getTotal(for: .swimmingStrokeCount)?.doubleValue(for: WorkoutUnit.strokes.unit(for: s)), strokes > 0 else {
			return nil
		}

		return strokes.toCSV()
	})

}
