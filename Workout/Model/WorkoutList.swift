//
//  WorkoutList.swift
//  Workout
//
//  Created by Marco Boschi on 08/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import HealthKit
import SwiftUI
import Combine

class WorkoutList: BindableObject {

	#warning("Use receive(on:) (Xcode bug)")
	let didChange = PassthroughSubject<Void, Never>()//.receive(on: RunLoop.main)

	var filters: Set<HKWorkoutActivityType> = [] {
		didSet {
			updateList()
		}
	}

//	private(set) var workouts: [Workout]
//	private var allWorkouts: [Workout]

	private func updateList() {
		#warning("Implement me")
		// Recompute `workouts`

		#warning("Force receive on main thread until receive(on:) is not available (Xcode bug)")
		DispatchQueue.main.async {
			self.didChange.send(())
		}
	}

}
