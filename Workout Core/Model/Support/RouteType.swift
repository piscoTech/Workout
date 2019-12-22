//
//  RouteType.swift
//  Workout Core
//
//  Created by Marco Boschi on 22/12/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation

public enum RouteType: String, CaseIterable {
	case csv = "csv", gpx = "gpx"

	public var displayName: String {
		self.rawValue.uppercased()
	}

	/// The default system of units, the metric one.
	public static let `default` = RouteType.csv

}
