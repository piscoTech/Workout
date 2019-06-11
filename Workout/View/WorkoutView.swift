//
//  WorkoutView.swift
//  Workout
//
//  Created by Marco Boschi on 07/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import SwiftUI
import MBLibrary
import MBHealth

struct WorkoutView : View {
	@EnvironmentObject private var appData: AppData
	@EnvironmentObject private var workout: Workout

	private var systemOfUnits: SystemOfUnits {
		appData.preferences.systemOfUnits
	}

	#warning("Use if-let")
    var body: some View {
		List {
			if workout.hasError {
				if !appData.isHealthDataAvailable {
					MessageCell("WRKT_ERR_NO_HEALTH")
				} else {
					MessageCell("WRKT_ERR_LOADING")
				}
			} else {
				// Basic information
				Section {
					BasicDetailCell("WRKT_TYPE", data: workout.type.name)
					BasicDetailCell("WRKT_START", data: workout.startDate.getFormattedDateTime())
					BasicDetailCell("WRKT_END", data: workout.endDate.getFormattedDateTime())
					BasicDetailCell("WRKT_DURATION", data: workout.duration.getLocalizedDuration())
					BasicDetailCell("WRKT_DISTANCE", data: workout.totalDistance?.formatAsDistance(withUnit: workout.distanceUnit.unit(for: systemOfUnits)))
					BasicDetailCell("WRKT_AVG_HEART", data: workout.avgHeart?.formatAsHeartRate(withUnit: WorkoutUnit.heartRate.unit(for: systemOfUnits)))
					BasicDetailCell("WRKT_MAX_HEART", data: workout.maxHeart?.formatAsHeartRate(withUnit: WorkoutUnit.heartRate.unit(for: systemOfUnits)))
					BasicDetailCell("WRKT_AVG_PACE", data: workout.pace?.formatAsPace(withReferenceLength: workout.paceUnit.unit(for: systemOfUnits)))
					BasicDetailCell("WRKT_AVG_SPEED", data: workout.speed?.formatAsSpeed(withUnit: workout.speedUnit.unit(for: systemOfUnits)))
					if workout.totalEnergy != nil {
						if workout.activeEnergy != nil {
							BasicDetailCell("WRKT_CALORIES", localizedData: "WRKT_SPLIT_CAL_\(workout.activeEnergy!.formatAsEnergy(withUnit: WorkoutUnit.calories.unit(for: systemOfUnits)))_TOTAL_\(workout.totalEnergy!.formatAsEnergy(withUnit: WorkoutUnit.calories.unit(for: systemOfUnits)))")
						} else {
							BasicDetailCell("WRKT_CALORIES", data: workout.totalEnergy?.formatAsEnergy(withUnit: WorkoutUnit.calories.unit(for: systemOfUnits)))
						}
					} else {
						BasicDetailCell("WRKT_CALORIES")
					}
				}

				// Additional Data
				ForEach(workout.additionalProviders) { p in
					p.section
				}
			}
		}.listStyle(.grouped)
			.navigationBarTitle(Text("WRKT_TITLE"), displayMode: .inline)
			.navigationBarItems(trailing: Group {
				if workout.loaded && !workout.hasError {
					Button(action: { print("Export...") }) {
						Image(systemName: "square.and.arrow.up")
					}
				} else if workout.isLoading {
					ActivityIndicator(style: .medium)
				}
			}.imageScale(.large))
			.onAppear {
				self.workout.load()
			}
    }
}

private struct BasicDetailCell: View {
	private let header: LocalizedStringKey
	private let data: LocalizedStringKey?

	init(_ header: LocalizedStringKey, localizedData data: LocalizedStringKey) {
		self.header = header
		self.data = data
	}

	init(_ header: LocalizedStringKey, data: String? = nil) {
		self.header = header

		if let s = data {
			self.data = LocalizedStringKey(s)
		} else {
			self.data = nil
		}
	}

	#warning("The if shout be an if-let")
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			Text(header)
			Spacer()
			Group {
				if data != nil {
					Text(data!)
				} else {
					Text(missingValue)
				}
			}.foregroundColor(.secondary)
		}
	}
}

#if DEBUG
//struct WorkoutView_Previews : PreviewProvider {
//    static var previews: some View {
//        WorkoutView()
//    }
//}
#endif
