//
//  GPXWorkoutRouteExporter.swift
//  Workout Core
//
//  Created by Marco Boschi on 22/12/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation
import CoreLocation

class GPXWorkoutRouteExporter: WorkoutRouteExporter {

	private weak var owner: Workout!

	required init(for owner: Workout) {
		self.owner = owner
	}
	
	func export(_ route: [[CLLocation]]) -> URL? {
		let routeFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("route.gpx")
		guard let file = OutputStream(url: routeFile, append: false) else {
			return nil
		}

		do {
			file.open()
			defer {
				file.close()
			}

			try file.write(#"""
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1"
	creator="Workout - CSV Exporter - https://marcoboschi.altervista.org/app/workout/"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns="http://www.topografix.com/GPX/1/1"
	xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
	<trk>
		<type>\#(owner.name)</type>

"""#)

			for segment in route {
				try file.write("\t\t<trkseg>\n")

				for point in segment {
					try file.write(#"""
			<trkpt lat="\#(point.coordinate.latitude.toString(forcingPointSeparator: true))"
				lon="\#(point.coordinate.longitude.toString(forcingPointSeparator: true))">
				<ele>\#(point.altitude.toString(forcingPointSeparator: true))</ele>
				<time>\#(point.timestamp.utcISOdescription)</time>
			</trkpt>

"""#)
				}

				try file.write("\t\t</trkseg>\n")
			}

			try file.write("\t</trk>\n</gpx>\n")

			return routeFile
		} catch {
			return nil
		}
	}

}
