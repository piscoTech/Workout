//
//  RunningWorkout.swift
//  Workout
//
//  Created by Marco Boschi on 04/03/2017.
//  Copyright © 2017 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit
import MBLibrary

class RunninWorkout: Workout {
	
	required init(_ raw: HKWorkout, delegate del: WorkoutDelegate?) {
		super.init(raw, delegate: del)
		
		self.addDetails([.pace, .heart, .steps])
		self.addRequest(for: .distanceWalkingRunning, withUnit: .kilometer(), andTimeType: .ranged, searchingBy: .workout)
		self.addRequest(for: .stepCount, withUnit: .steps(), andTimeType: .ranged, searchingBy: .time)
	}
	
}
