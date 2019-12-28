//
//  WorkoutRouteExporter.swift
//  Workout Core
//
//  Created by Marco Boschi on 22/12/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation
import CoreLocation

protocol WorkoutRouteExporter {

	func export(_ route: [[CLLocation]], _ callback: @escaping (URL?) -> Void)

}
