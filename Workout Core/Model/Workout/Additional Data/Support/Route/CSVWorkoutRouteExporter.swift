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

	required init(for _: Workout) {
		// Not needed
	}

	func export(_ route: [[CLLocation]], withPrefix prefix: String) -> URL? {
		guard prefix.range(of: "/") == nil else {
			fatalError("Prefix must not contain '/'")
		}

		let sep = CSVSeparator
		let routeFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(prefix)route.csv")
		guard let file = OutputStream(url: routeFile, append: false) else {
			return nil
		}

		do {
			file.open()
			defer {
				file.close()
			}

			let header = ["Segment", "Latitude", "Longitude", "Altitude (m)", "Time (UTC ISO)", "Time (UTC)", "Time (Local)", "UNIX Epoch Time"].map { $0.toCSV() }.joined(separator: sep) + "\n"
			try file.write(header)

			for (sId, segment) in route.enumerated() {
				let sIdCsv = "\(sId + 1)"

				for p in segment {
					let pointRow = [sIdCsv,
									p.coordinate.latitude.toCSV(forcingPointSeparator: true),
									p.coordinate.longitude.toCSV(forcingPointSeparator: true),
									p.altitude.toCSV(forcingPointSeparator: true),
									p.timestamp.utcISOdescription.toCSV(),
									p.timestamp.utcTimestamp.toCSV(),
									p.timestamp.unixTimestamp.toCSV(),
									p.timestamp.timeIntervalSince1970.toCSV(forcingPointSeparator: true)
						].joined(separator: sep) + "\n"
					try file.write(pointRow)
				}
			}

			return routeFile
		} catch {
			return nil
		}
	}
	
}
