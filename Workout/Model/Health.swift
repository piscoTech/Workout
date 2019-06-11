//
//  Health.swift
//  Workout
//
//  Created by Marco Boschi on 08/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import HealthKit
import Combine
import SwiftUI

class Health: BindableObject {

	#warning("Use receive(on:) (Xcode bug)")
	let didChange = PassthroughSubject<Void, Never>() //.receive(on: RunLoop.main)

	let store = HKHealthStore()

	/// List of health data to require access to.
	private let readData: Set<HKObjectType> = [
		.workoutType(),
		.quantityType(forIdentifier: .heartRate)!,

		.quantityType(forIdentifier: .activeEnergyBurned)!,
		.quantityType(forIdentifier: .basalEnergyBurned)!,

		.quantityType(forIdentifier: .distanceWalkingRunning)!,
		.quantityType(forIdentifier: .stepCount)!,

		.quantityType(forIdentifier: .distanceSwimming)!,
		.quantityType(forIdentifier: .swimmingStrokeCount)!
	]

	func authorizeHealthKitAccess(_ callback: @escaping () -> Void) {
		store.getRequestStatusForAuthorization(toShare: [], read: readData) { status, _ in
			if status != .unnecessary {
				self.store.requestAuthorization(toShare: nil, read: self.readData) { _, _ in
					callback()
				}
			}
		}
	}

	var isHealthDataAvailable: Bool {
		HKHealthStore.isHealthDataAvailable()
	}

}
