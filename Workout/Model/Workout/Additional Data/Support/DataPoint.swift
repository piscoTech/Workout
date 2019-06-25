//
//  DataPoint.swift
//  Workout
//
//  Created by Marco Boschi on 20/07/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import Foundation

protocol DataPoint {

	var value: Double { get }

}

struct InstantDataPoint: DataPoint {
	
	let time: TimeInterval
	let value: Double
	
}

struct RangedDataPoint: DataPoint {
	
	let start, end: TimeInterval
	let value: Double
	
	init(start: TimeInterval, end: TimeInterval, value: Double) {
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

enum DataType {
	case cumulative, average
}
