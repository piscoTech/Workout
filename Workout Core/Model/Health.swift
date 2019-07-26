//
//  Health.swift
//  Workout
//
//  Created by Marco Boschi on 08/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import HealthKit

public class Health {

	let store = HKHealthStore()

	public init() {}

	/// List of health data to require access to.
	private let readData: Set<HKObjectType> = [
			HKObjectType.workoutType(),
			HKObjectType.quantityType(forIdentifier: .heartRate)!,

			HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
			HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,

			HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
			HKObjectType.quantityType(forIdentifier: .stepCount)!,

			HKObjectType.quantityType(forIdentifier: .distanceSwimming)!,
			HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)!,
			
			HKObjectType.quantityType(forIdentifier: .distanceCycling)!
		]

	public func authorizeHealthKitAccess(_ callback: @escaping () -> Void) {
		let req = {
			self.store.requestAuthorization(toShare: nil, read: self.readData) { _, _ in
				DispatchQueue.main.async {
					callback()
				}
			}
		}

		if #available(iOS 12.0, *) {
			store.getRequestStatusForAuthorization(toShare: [], read: readData) { status, _ in
				if status != .unnecessary {
					req()
				}
			}
		} else {
			req()
		}
	}

	public var isHealthDataAvailable: Bool {
		HKHealthStore.isHealthDataAvailable()
	}

}
