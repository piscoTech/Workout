//
//  WorkoutRouteExporter.swift
//  Workout Core
//
//  Created by Marco Boschi on 22/12/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation
import CoreLocation

protocol WorkoutRouteExporter: AnyObject {

	init(for owner: Workout)

	/// Export the given route data to a file.
	/// - parameter route: The GPS data for the route separated in continuous segments.
	/// - parameter prefix: A prefix to add to the file name.
	/// - returns: A `URL` to the file containing the data or `nil` in case of failure.
	func export(_ route: [[CLLocation]], withPrefix prefix: String) -> URL?

}
