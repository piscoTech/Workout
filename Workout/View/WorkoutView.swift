//
//  WorkoutView.swift
//  Workout
//
//  Created by Marco Boschi on 07/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import SwiftUI
import MBHealth

struct WorkoutView : View {
	@EnvironmentObject private var appData: AppData
	@EnvironmentObject private var workout: Workout

	private var systemOfUnits: SystemOfUnits {
		appData.preferences.systemOfUnits
	}

    var body: some View {
		List {
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
				// title = "CALORIES"
			}
		}.listStyle(.grouped)
			.navigationBarTitle(Text("WRKT_TITLE"), displayMode: .inline)
    }
}

private struct BasicDetailCell: View {
	private let header: LocalizedStringKey
	private let data: String?

	init(_ header: LocalizedStringKey, data: String? = nil) {
		self.header = header
		self.data = data
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
