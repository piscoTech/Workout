//
//  DataPoint.swift
//  Workout
//
//  Created by Marco Boschi on 20/07/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import HealthKit

protocol MetadataHolder {
	
	var metadata: [String: Any]? { get }
	
}

protocol DataPoint: MetadataHolder {

	var value: HKQuantity { get }

}

enum DataPointType {
	case instant, ranged
}

struct InstantDataPoint: DataPoint {

	let time: TimeInterval
	let value: HKQuantity
	let metadata: [String : Any]?

}

struct RangedDataPoint: DataPoint {

	let start, end: TimeInterval
	let value: HKQuantity
	var metadata: [String : Any]?

	init(start: TimeInterval, end: TimeInterval, value: HKQuantity, metadata: [String : Any]?) {
		self.start = min(start, end)
		self.end = max(start, end)
		self.value = value
		self.metadata = metadata
	}

	var duration: TimeInterval {
		return end - start
	}

}
