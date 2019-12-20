//
//  AdditionalDataManager.swift
//  Workout Core
//
//  Created by Marco Boschi on 20/12/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation

protocol AdditionalDataManager {

	/// Pass the parent workout if needed. The default implementation does nothing.
	func set(workout: Workout)
	
}

extension AdditionalDataManager {

	func set(workout: Workout) {}

}
