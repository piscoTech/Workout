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

let unixDateTime = { Void -> NSDateFormatter in
	let formatter = NSDateFormatter()
	formatter.dateFormat = "yyyy-MM-dd HH:mm"
	
	return formatter
}()

let localDate = { Void -> NSDateFormatter in
	let formatter = NSDateFormatter()
	formatter.dateStyle = .MediumStyle
	formatter.timeStyle = .NoStyle
	
	return formatter
}()

let localTime = { Void -> NSDateFormatter in
	let formatter = NSDateFormatter()
	formatter.dateStyle = .NoStyle
	formatter.timeStyle = .ShortStyle
	
	return formatter
}()

let distance = { Void -> NSLengthFormatter in
	let formatter = NSLengthFormatter()
	formatter.numberFormatter.usesSignificantDigits = true
	formatter.numberFormatter.maximumSignificantDigits = 2
	formatter.numberFormatter.minimumSignificantDigits = 0
	
	return formatter
}()

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

extension NSDate {
	
	func getUNIXDateTime() -> String {
		return unixDateTime.stringFromDate(self)
	}
	
	func getFormattedDateTime() -> String {
		return getFormattedDate() + " " + getFormattedTime()
	}
	
	func getFormattedDate() -> String {
		return localDate.stringFromDate(self)
	}
	
	func getFormattedTime() -> String {
		return localTime.stringFromDate(self)
	}
	
}

extension Double {
	
	///- returns: The formatted values, considered in kilometers.
	func getFormattedDistance() -> String {
		return distance.stringFromValue(self, unit: .Kilometer)
	}
	
}
