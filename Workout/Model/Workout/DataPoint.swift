//
//  DataPoint.swift
//  Workout
//
//  Created by Marco Boschi on 20/07/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import HealthKit

protocol DataPoint {

	var value: HKQuantity { get }

}

struct InstantDataPoint: DataPoint {
	
	let time: TimeInterval
	let value: HKQuantity
	
}

struct RangedDataPoint: DataPoint {
	
	let start, end: TimeInterval
	let value: HKQuantity
	
	init(start: TimeInterval, end: TimeInterval, value: HKQuantity) {
		self.start = min(start, end)
		self.end = max(start, end)
		self.value = value
	}
	
	var duration: TimeInterval {
		return end - start
	}
	
}

enum DataPointType {
	case instant, ranged
}
