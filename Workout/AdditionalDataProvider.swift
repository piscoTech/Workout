//
//  AdditionalDataProvider.swift
//  Workout
//
//  Created by Marco Boschi on 28/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit

protocol AdditionalDataProvider {
	
	/// Whether the section for the provider should appear before or after minute-by-minute details.
	///
	/// Even if minute-by-minute details are not available, providers that specify `true` will appear before those which specify `false`.
	var preferAppearanceBeforeDetails: Bool { get }
	
	var sectionHeader: String? { get }
	var sectionFooter: String? { get }
	var numberOfRows: Int { get }
	func cellForRowAt(_ indexPath: IndexPath, for tableView: UITableView) -> UITableViewCell
	
	/// Export the data in CSV file(s).
	/// - returns: An array of `URL`s for the files that contains the data or `nil` if an error occured. If no data should be exported an empty array is returned.
	func export() -> [URL]?
	
}
