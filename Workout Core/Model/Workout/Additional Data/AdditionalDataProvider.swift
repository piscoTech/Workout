//
//  AdditionalDataProvider.swift
//  Workout
//
//  Created by Marco Boschi on 28/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit

public protocol AdditionalDataProvider {
	
	var sectionHeader: String? { get }
	var sectionFooter: String? { get }
	var numberOfRows: Int { get }
	func cellForRowAt(_ indexPath: IndexPath, for tableView: UITableView) -> UITableViewCell
	
	/// Export the data in CSV file(s).
	/// - returns: An array of `URL`s for the files that contains the data or `nil` if an error occured. If no data should be exported an empty array is returned.
	func export(for systemOfUnits: SystemOfUnits, _ callback: @escaping ([URL]?) -> Void)
	
}

public protocol ElevationChangeProvider: AdditionalDataProvider {
	
	/// The elevation change, divided in distance ascended and descended, during the whole duration of the workout.
	///
	/// The receiver can recompute this value each time it's accessed, make sure to cache it appropriately.
	var elevationChange: (ascended: HKQuantity?, descended: HKQuantity?) { get }
	
}
