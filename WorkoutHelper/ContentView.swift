//
//  ContentView.swift
//  WorkoutHelper
//
//  Created by Marco Boschi on 27/10/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import SwiftUI
import HealthKit

let hkStore = HKHealthStore()

struct ContentView: View {
	@State var result: Bool? = nil

    var body: some View {
		VStack {
			Button(action: {
				self.createSamples()
			}) {
				Text("Add samples...")
			}

			if result != nil {
				Text(result == true ? "Ok!" : "Failed")
			} else {
				Text("Waiting...")
			}
		}
    }

	func createSamples() {
		hkStore.requestAuthorization(toShare: [HKObjectType.workoutType()], read: nil) { _, _ in
			let s = Date()

			let ri = HKWorkout(activityType: .running, start: s, end: s.advanced(by: 30 * 60), duration: 0, totalEnergyBurned: nil, totalDistance: nil, metadata: [HKMetadataKeyIndoorWorkout : true])
			let ro = HKWorkout(activityType: .running, start: s, end: s.advanced(by: 30 * 60), duration: 0, totalEnergyBurned: nil, totalDistance: nil, metadata: [HKMetadataKeyIndoorWorkout : false])
			let r = HKWorkout(activityType: .running, start: s, end: s.advanced(by: 30 * 60))

			let ci = HKWorkout(activityType: .cycling, start: s, end: s.advanced(by: 30 * 60), duration: 0, totalEnergyBurned: nil, totalDistance: nil, metadata: [HKMetadataKeyIndoorWorkout : true])
			let co = HKWorkout(activityType: .cycling, start: s, end: s.advanced(by: 30 * 60), duration: 0, totalEnergyBurned: nil, totalDistance: nil, metadata: [HKMetadataKeyIndoorWorkout : false])
			let c = HKWorkout(activityType: .cycling, start: s, end: s.advanced(by: 30 * 60))

			let wi = HKWorkout(activityType: .walking, start: s, end: s.advanced(by: 30 * 60), duration: 0, totalEnergyBurned: nil, totalDistance: nil, metadata: [HKMetadataKeyIndoorWorkout : true])
			let wo = HKWorkout(activityType: .walking, start: s, end: s.advanced(by: 30 * 60), duration: 0, totalEnergyBurned: nil, totalDistance: nil, metadata: [HKMetadataKeyIndoorWorkout : false])
			let w = HKWorkout(activityType: .walking, start: s, end: s.advanced(by: 30 * 60))

			let si = HKWorkout(activityType: .swimming, start: s, end: s.advanced(by: 30 * 60), duration: 0, totalEnergyBurned: nil, totalDistance: nil, metadata: [HKMetadataKeySwimmingLocationType : HKWorkoutSwimmingLocationType.pool.rawValue])
			let so = HKWorkout(activityType: .swimming, start: s, end: s.advanced(by: 30 * 60), duration: 0, totalEnergyBurned: nil, totalDistance: nil, metadata: [HKMetadataKeySwimmingLocationType : HKWorkoutSwimmingLocationType.openWater.rawValue])
			let su = HKWorkout(activityType: .swimming, start: s, end: s.advanced(by: 45 * 60), duration: 0, totalEnergyBurned: nil, totalDistance: nil, metadata: [HKMetadataKeySwimmingLocationType : HKWorkoutSwimmingLocationType.unknown.rawValue])
			let swim = HKWorkout(activityType: .swimming, start: s, end: s.advanced(by: 30 * 60))

			hkStore.save([ri, ro, r, ci, co, c, wi, wo, w, si, so, su, swim]) { (r, err) in
				self.result = r
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
