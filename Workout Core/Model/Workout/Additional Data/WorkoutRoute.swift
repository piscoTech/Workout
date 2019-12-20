//
//  WorkoutRoute.swift
//  Workout Core
//
//  Created by Marco Boschi on 20/12/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit
import MBLibrary
import MapKit

@available(iOS 11.0, *)
public class WorkoutRoute: NSObject, AdditionalDataExtractor, AdditionalDataProvider, MKMapViewDelegate {

	private static let routePadding: CGFloat = 20

	private weak var preferences: Preferences?
	private(set) weak var owner: Workout?
	private var route: [[CLLocation]]? {
		didSet {
			if route == nil {
				routeBounds = nil
				routeSegments = nil
				routeStart = nil
				routeEnd = nil
			}
		}
	}

	private var routeBounds: MKMapRect?
	private var routeSegments: [MKPolyline]?
	private var routeStart: MKPointAnnotation?
	private var routeEnd: MKPointAnnotation?

	init(with preferences: Preferences) {
		self.preferences = preferences
	}

	// MARK: - Extract Data

	func set(workout: Workout) {
		owner = workout
	}

	func extract(from healthStore: HKHealthStore, completion: @escaping (Bool) -> Void) {
		guard let raw = owner?.raw else {
			route = nil
			completion(false)

			return
		}

		let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
		let filter = HKQuery.predicateForObjects(from: raw)
		let routeQuery = HKSampleQuery(sampleType: HKSeriesType.workoutRoute(), predicate: filter, limit: 1, sortDescriptors: [sortDescriptor]) { (_, r, err) in
			guard let route = r?.first as? HKWorkoutRoute else {
				self.route = nil
				// If no result is returned it's fine, the workout simply has no route attached
				completion(r?.isEmpty ?? false)

				return
			}

			var positions: [CLLocation] = []
			let locQuery = HKWorkoutRouteQuery(route: route) { (q, loc, isDone, _) in
				guard let locations = loc else {
					self.route = nil
					completion(false)
					healthStore.stop(q)
					return
				}

				positions.append(contentsOf: locations)

				if isDone {
					self.route = []
					self.routeSegments = []
					self.routeBounds = nil

					// Isolate positions on active intervals
					for i in raw.activeSegments {
						if let startPos = positions.lastIndex(where: { $0.timestamp <= i.start }) {
							var track = positions.suffix(from: startPos)
							if let afterEndPos = track.firstIndex(where: { $0.timestamp > i.end }) {
								track = track.prefix(upTo: afterEndPos)
							}

							if !track.isEmpty {
								let pl = MKPolyline(coordinates: track.map { $0.coordinate }, count: track.count)
								let bounds = pl.boundingMapRect
								self.routeBounds = self.routeBounds?.union(bounds) ?? bounds

								self.route?.append(Array(track))
								self.routeSegments?.append(pl)
							}
						}
					}

					if self.route?.isEmpty ?? true {
						self.route = nil
					} else {
						if let s = self.route?.first?.first {
							self.routeStart = MKPointAnnotation()
							self.routeStart?.coordinate = s.coordinate
							self.routeStart?.title = NSLocalizedString("WRKT_ROUTE_START", comment: "Start")
						}

						if let e = self.route?.last?.last {
							self.routeEnd = MKPointAnnotation()
							self.routeEnd?.coordinate = e.coordinate
							self.routeEnd?.title = NSLocalizedString("WRKT_ROUTE_END", comment: "End")
						}
					}
					completion(true)
				}
			}

			healthStore.execute(locQuery)
		}

		healthStore.execute(routeQuery)
	}

	// MARK: - Display Data

	public let sectionHeader: String? = NSLocalizedString("WRKT_ROUTE_TITLE", comment: "Route")
	public let sectionFooter: String? = nil

	public var numberOfRows: Int {
		route != nil ? 1 : 0
	}

	public func heightForRowAt(_: IndexPath, in _: UITableView) -> CGFloat? {
		return UITableView.automaticDimension
	}

	public func cellForRowAt(_ indexPath: IndexPath, for tableView: UITableView) -> UITableViewCell {
		guard let routeBounds = self.routeBounds, let routeSegments = self.routeSegments else {
			fatalError("The cell should not be displayed when no route is available")
		}

		let c = tableView.dequeueReusableCell(withIdentifier: "map", for: indexPath) as! WorkoutRouteTVCell
		c.mapView.removeOverlays(c.mapView.overlays)
		c.mapView.removeAnnotations(c.mapView.annotations)
		c.mapView.delegate = self

		c.mapView.addOverlays(routeSegments, level: .aboveRoads)
		if let s = self.routeStart {
			c.mapView.addAnnotation(s)
		}
		if let e = self.routeEnd {
			c.mapView.addAnnotation(e)
		}

		DispatchQueue.main.async {
			// Let the cell be added to the table before moving the map
			c.mapView.setVisibleMapRect(routeBounds, edgePadding: UIEdgeInsets(top: Self.routePadding * 2,
																			   left: Self.routePadding,
																			   bottom: Self.routePadding,
																			   right: Self.routePadding), animated: false)
		}

		return c
	}

	public func export(for systemOfUnits: SystemOfUnits, _ callback: @escaping ([URL]?) -> Void) {
		#warning("To Be Implemented")
		callback([])
	}

	// MARK: - Map Delegate

	public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if overlay is MKPolyline {
			let polylineRenderer = MKPolylineRenderer(overlay: overlay)
			polylineRenderer.strokeColor = #colorLiteral(red: 0.7807273327, green: 0, blue: 0.1517053111, alpha: 1)
			polylineRenderer.lineWidth = 6.0
			return polylineRenderer
		}

		return MKPolylineRenderer()
	}

	public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		var view: MKMarkerAnnotationView?
		if let start = routeStart, start === annotation {
			let ann = MKMarkerAnnotationView()
			ann.markerTintColor = MKPinAnnotationView.greenPinColor()

			view = ann
		}

		if let end = routeEnd, end === annotation {
			let ann = MKMarkerAnnotationView()
			ann.markerTintColor = MKPinAnnotationView.redPinColor()

			view = ann
		}

		view?.titleVisibility = .adaptive

		return view
	}

}
