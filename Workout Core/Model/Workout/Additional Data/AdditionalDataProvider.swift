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
	/// The number of rows the section assigned to the data provider shall contain. A section without rows will be hidden altogether.
	var numberOfRows: Int { get }
	/// The height of the specified cell.
	/// - returns: The height of the given cell or `nil` to use the default height.
	func heightForRowAt(_ indexPath: IndexPath, in tableView: UITableView) -> CGFloat?
	func cellForRowAt(_ indexPath: IndexPath, for tableView: UITableView) -> UITableViewCell
	
	/// Export the data in CSV file(s).
	/// - returns: An array of `URL`s for the files that contains the data or `nil` if an error occured. If no data should be exported an empty array is returned.
	func export(for preferences: Preferences, withPrefix prefix: String, _ callback: @escaping ([URL]?) -> Void)
	
}

extension AdditionalDataProvider {

	public func heightForRowAt(_ indexPath: IndexPath, in tableView: UITableView) -> CGFloat? {
		return nil
	}

}

public protocol ElevationChangeProvider: AdditionalDataProvider {
	
	/// The elevation change, divided in distance ascended and descended, during the whole duration of the workout.
	///
	/// The receiver can recompute this value each time it's accessed, make sure to cache it appropriately.
	var elevationChange: (ascended: HKQuantity?, descended: HKQuantity?) { get }
	
}

public protocol AverageCadenceProvider: AdditionalDataProvider {

	/// The average cadence, i.e. step count per unit time, of the workout.
	///
	/// The receiver can recompute this value each time it's accessed, make sure to cache it appropriately.
	var averageCadence: HKQuantity? { get }

}
