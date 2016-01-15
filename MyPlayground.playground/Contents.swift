//: Playground - noun: a place where people can play

import UIKit

var a = NSDate()
var b = NSDate(timeIntervalSince1970: a.timeIntervalSince1970 + 60*10)

extension NSDate: Comparable {}

public func < (lhs: NSDate, rhs: NSDate) -> Bool {
	return lhs.timeIntervalSince1970 < rhs.timeIntervalSince1970
}

a < b
a < a
b > a
b == a
a == a