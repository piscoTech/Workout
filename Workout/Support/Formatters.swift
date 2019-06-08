//
//  Formatters.swift
//  Workout
//
//  Created by Marco Boschi on 08/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation

let distanceF: NumberFormatter = {
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	formatter.usesSignificantDigits = false
	formatter.maximumFractionDigits = 2

	return formatter
}()

let speedF: NumberFormatter = {
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	formatter.usesSignificantDigits = false
	formatter.maximumFractionDigits = 1

	return formatter
}()

let integerF: NumberFormatter = {
	let formatter = NumberFormatter()
	formatter.numberStyle = .decimal
	formatter.usesSignificantDigits = false
	formatter.maximumFractionDigits = 0

	return formatter
}()

