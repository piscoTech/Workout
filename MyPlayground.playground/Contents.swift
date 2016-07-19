//: Playground - noun: a place where people can play

import Foundation

extension String {

	subscript (i: Int) -> String {
		let j = i < 0 ? self.characters.count + i : i
		return self[j ..< j + 1]
	}
	
	///Element at last index is _not_ included.
	subscript (r: CountableRange<Int>) -> String {
		return substring(with: r)
	}
//
	///Element at last index is _not_ included.
	func substring(with r: CountableRange<Int>) -> String {
		let start = self.index(startIndex, offsetBy: r.lowerBound)
		let end = self.index(startIndex, offsetBy: r.upperBound)
		
		return substring(with: start ..< end)
	}
//
//	func substring(from i: Int) -> String {
//		let j = i < 0 ? self.characters.count + i : i
//		return substring(from: self.index(startIndex, offsetBy: j))
//	}
//	
//	func substring(to i: Int) -> String {
//		let j = i < 0 ? self.characters.count + i : i
//		return substring(to: self.index(startIndex, offsetBy: j))
//	}
//	
}

var decimalPoint: String {
	get {
		let nFormat = NumberFormatter()
		nFormat.numberStyle = .decimal
		let n = nFormat.string(from: 0.1)!
		
		return n[1]
	}
}

//"d!" == ("Hello World!").substring(from: -2)
//"!" == ("Hello World!").substring(from: -1)
//
//"H" == ("Hello World!").substring(to: 1)
//"He" == ("Hello World!").substring(to: 2)
//
//"llo World!" == ("Hello World!").substring(from: 2)
//"Hello Worl" == ("Hello World!").substring(to: -2)
//
//"ll" == ("Hello World!").substring(with: 2 ..< 4)
//"ll" == ("Hello World!")[2..<4]
//"l" == ("Hello World!")[2]

decimalPoint
