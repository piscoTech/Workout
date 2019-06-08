//
//  AppData.swift
//  Workout
//
//  Created by Marco Boschi on 08/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import HealthKit
import Combine
import SwiftUI

class AppData: BindableObject {

	#warning("Use receive(on:) (Xcode bug)")
	let didChange = PassthroughSubject<Void, Never>() //.receive(on: RunLoop.main)

	let healthStore: HKHealthStore
	let preferences: Preferences
	private(set) var workoutList: WorkoutList

	/// List of health data to require access to.
	private let healthReadData: Set<HKObjectType> = [
		.workoutType(),
		.quantityType(forIdentifier: .heartRate)!,

		.quantityType(forIdentifier: .activeEnergyBurned)!,
		.quantityType(forIdentifier: .basalEnergyBurned)!,

		.quantityType(forIdentifier: .distanceWalkingRunning)!,
		.quantityType(forIdentifier: .stepCount)!,

		.quantityType(forIdentifier: .distanceSwimming)!,
		.quantityType(forIdentifier: .swimmingStrokeCount)!
	]

	init() {
		healthStore = HKHealthStore()
		preferences = Preferences()
		workoutList = WorkoutList()

		workoutList.appData = self
	}

	func authorizeHealthKitAccess() {
		healthStore.getRequestStatusForAuthorization(toShare: [], read: healthReadData) { status, _ in
			if status != .unnecessary {
				self.healthStore.requestAuthorization(toShare: nil, read: self.healthReadData) { _, _ in
					self.workoutList.reloadWorkouts()
				}
			}
		}
	}

	var isHealthDataAvailable: Bool {
		HKHealthStore.isHealthDataAvailable()
	}

}
