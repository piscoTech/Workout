//
//  CSVWorkoutRouteExporter.swift
//  Workout Core
//
//  Created by Marco Boschi on 22/12/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation
import CoreLocation
import MBLibrary

class CSVWorkoutRouteExporter: WorkoutRouteExporter {

	func export(_ route: [[CLLocation]], _ callback: @escaping (URL?) -> Void) {
		let sep = CSVSeparator
		let routeFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("route.csv")
		guard let file = OutputStream(url: routeFile, append: false) else {
			callback(nil)
			return
		}

		do {
			file.open()
			defer {
				file.close()
			}

			let header = ["Segment", "Latitude", "Longitude", "Altitude (m)", "Time UTC"].map { $0.toCSV() }.joined(separator: sep) + "\n"
			try file.write(header)

			for (sId, segment) in route.enumerated() {
				let sIdCsv = "\(sId + 1)"

				for p in segment {
					let pointRow = [sIdCsv,
									p.coordinate.latitude.toCSV(forcingPointSeparator: true),
									p.coordinate.longitude.toCSV(forcingPointSeparator: true),
									p.altitude.toCSV(forcingPointSeparator: true),
									p.timestamp.utcISOdescription.toCSV()
						].joined(separator: sep) + "\n"
					try file.write(pointRow)
				}
			}

			callback(routeFile)
		} catch {
			callback(nil)
		}
	}
	
}
