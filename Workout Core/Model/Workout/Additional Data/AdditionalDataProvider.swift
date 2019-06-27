//
//  AdditionalDataProvider.swift
//  Workout
//
//  Created by Marco Boschi on 28/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit

public protocol AdditionalDataProvider {
	
	var sectionHeader: String? { get }
	var sectionFooter: String? { get }
	var numberOfRows: Int { get }
	func cellForRowAt(_ indexPath: IndexPath, for tableView: UITableView) -> UITableViewCell
	
	/// Export the data in CSV file(s).
	/// - returns: An array of `URL`s for the files that contains the data or `nil` if an error occured. If no data should be exported an empty array is returned.
	func export() -> [URL]?
	
}
