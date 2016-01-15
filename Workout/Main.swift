//
//  Main.swift
//  Workout
//
//  Created by Marco Boschi on 15/01/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit

let healthStore = HKHealthStore()

let unixDateTimeF = { Void -> NSDateFormatter in
	let formatter = NSDateFormatter()
	formatter.dateFormat = "yyyy-MM-dd HH:mm"
	
	return formatter
}()

let localDateF = { Void -> NSDateFormatter in
	let formatter = NSDateFormatter()
	formatter.dateStyle = .MediumStyle
	formatter.timeStyle = .NoStyle
	
	return formatter
}()

let localTimeF = { Void -> NSDateFormatter in
	let formatter = NSDateFormatter()
	formatter.dateStyle = .NoStyle
	formatter.timeStyle = .ShortStyle
	
	return formatter
}()

let distanceF = { Void -> NSLengthFormatter in
	let formatter = NSLengthFormatter()
	formatter.numberFormatter.usesSignificantDigits = false
	formatter.numberFormatter.maximumFractionDigits = 3
	
	return formatter
}()

let heartRateF = { Void -> NSNumberFormatter in
	let formatter = NSNumberFormatter()
	formatter.numberStyle = .DecimalStyle
	formatter.usesSignificantDigits = false
	formatter.maximumFractionDigits = 0
	
	return formatter
}()

func delay(delay: Double, closure:() -> Void) {
	dispatch_after(
		dispatch_time(
			DISPATCH_TIME_NOW,
			Int64(delay * Double(NSEC_PER_SEC))
		),
		dispatch_get_main_queue(), closure)
}

func dispatchMainQueue(block: () -> Void) {
	dispatch_async(dispatch_get_main_queue(), block)
}

func dispatchInBackground(block: () -> Void) {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
}

extension NSTimeInterval {
	
	func getDuration() -> String {
		var s = Int(floor(self))
		let neg = s < 0
		if neg {
			s *= -1
		}
		
		var m = s / 60
		s = s % 60
		
		let h = m / 60
		m = m % 60
		
		let sec = (s < 10 ? "0" : "") + "\(s)"
		let min = (m < 10 ? "0" : "") + "\(m)"
		
		return (neg ? "-" : "") + "\(h):\(min):\(sec)"
	}
	
	func getUNIXDateTime() -> String {
		let date = NSDate(timeIntervalSince1970: self)
		
		return date.getUNIXDateTime()
	}
	
	func getFormattedDateTime() -> String {
		let date = NSDate(timeIntervalSince1970: self)
		
		return date.getFormattedDate() + " " + date.getFormattedTime()
	}
	
	func getFormattedDate() -> String {
		let date = NSDate(timeIntervalSince1970: self)
		
		return date.getFormattedDate()
	}
	
	func getFormattedTime() -> String {
		let date = NSDate(timeIntervalSince1970: self)
		
		return date.getFormattedTime()
	}
	
}

public func < (lhs: NSDate, rhs: NSDate) -> Bool {
	return lhs.timeIntervalSince1970 < rhs.timeIntervalSince1970
}

extension NSDate: Comparable {
	
	func getUNIXDateTime() -> String {
		return unixDateTimeF.stringFromDate(self)
	}
	
	func getFormattedDateTime() -> String {
		return getFormattedDate() + " " + getFormattedTime()
	}
	
	func getFormattedDate() -> String {
		return localDateF.stringFromDate(self)
	}
	
	func getFormattedTime() -> String {
		return localTimeF.stringFromDate(self)
	}
	
}

extension Double {
	
	///- returns: The formatted values, considered in kilometers.
	func getFormattedDistance() -> String {
		return distanceF.stringFromValue(self, unit: .Kilometer)
	}
	
	func getFormattedHeartRate() -> String {
		return heartRateF.stringFromNumber(self)! + " bpm"
	}
	
}

extension HKUnit {
	
	class func heartRateUnit() -> HKUnit {
		return HKUnit.countUnit().unitDividedByUnit(HKUnit.minuteUnit())
	}
	
}
