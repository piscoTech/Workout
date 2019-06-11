//
//  AdditionalDataProvider.swift
//  Workout
//
//  Created by Marco Boschi on 28/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import SwiftUI

class AdditionalDataProvider: Identifiable {

	let id = UUID()

	/// The section to be inserted into the workout view, the view must be a `Section`.
	var section: AnyView {
		fatalError("Must provide the section")
	}

	/// Export the data in CSV file(s).
	/// - returns: An array of `URL`s for the files that contains the data or `nil` if an error occured. If no data should be exported an empty array is returned.
	func export() -> [URL]? {
		return []
	}
	
}
