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
	
	override init(_ raw: HKWorkout, delegate del: WorkoutDelegate?) {
		super.init(raw, delegate: del)
		
		if #available(iOS 10, *) {
			self.addDetails()
			self.addRequest(for: HKQuantityTypeIdentifier.distanceSwimming.getType()!, withUnit: .kilometer(), andTimeType: .ranged, searchingBy: .workout)
			self.addRequest(for: HKQuantityTypeIdentifier.swimmingStrokeCount.getType()!, withUnit: .strokes(), andTimeType: .ranged, searchingBy: .time)
		}
	}
	
	// TODO: Define an array with the content of details, the order in which they should appear and if they're a cumulative or average data using `DataType`.
	
}
