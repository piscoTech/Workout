//
//  SwimmingWorkout.swift
//  Workout
//
//  Created by Marco Boschi on 04/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit
import MBLibrary

class SwimmingWorkout: Workout {
	
	required init(_ raw: HKWorkout, delegate del: WorkoutDelegate?) {
		super.init(raw, delegate: del)
		self.setLengthPrefixFor(distance: .none, speed: .kilo, pace: .kilo)
		
		if #available(iOS 10, *) {
			self.addDetails([.pace, .heart, .strokes])
			
			if let distance = WorkoutDataQuery(typeID: .distanceSwimming, withUnit: .meter(), andTimeType: .ranged, searchingBy: .workout(fallbackToTime: true)) {
				self.addQuery(distance)
			}
			if let strokes = WorkoutDataQuery(typeID: .swimmingStrokeCount, withUnit: .strokes(), andTimeType: .ranged, searchingBy: .time) {
				self.addQuery(strokes)
			}
		}
	}
	
}
