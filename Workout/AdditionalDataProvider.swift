//
//  AdditionalDataProvider.swift
//  Workout
//
//  Created by Marco Boschi on 28/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit

protocol AdditionalDataProvider {
	
	var preferAppearanceBeforeDetails: Bool { get }
	var sectionHeader: String? { get }
	var sectionFooter: String? { get }
	var numberOfRows: Int { get }
	
	func cellForRowAt(_ indexPath: IndexPath, for tableView: UITableView) -> UITableViewCell
	func export() -> [URL]?
	
}
