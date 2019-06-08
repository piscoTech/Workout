//
//  Units.swift
//  Workout
//
//  Created by Marco Boschi on 08/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation

enum Units: Int, CaseIterable {
	case metric = 0, imperial

	var displayName: String {
		return NSLocalizedString("UNITS_NAME_\(self.rawValue)", comment: "Unit name")
	}

	/// The default system of units, the metric one.
	static let `default` = Units.metric

}
