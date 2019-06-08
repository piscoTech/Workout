//
//  WorkoutListView.swift
//  Workout
//
//  Created by Marco Boschi on 07/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import SwiftUI
import MBHealth
import HealthKit

struct WorkoutListView : View {

	enum Presenting {
		case none, settings, filterSelector
	}

	@EnvironmentObject private var appData: AppData
	@State private var presenting = Presenting.none

	var body: some View {
		NavigationView {
			List {
				Button(action: {
					self.presenting = .filterSelector
				}) {
					FilterStatusView()
				}

				ForEach(0 ..< 5) { index in
					NavigationButton(destination: WorkoutView()) {
						Text("Test \(index)")
					}
				}
			}
			.navigationBarTitle(Text("WRKT_LIST_TITLE"))
				.navigationBarItems(leading: Button(action: { self.presenting = .settings }) {
					Image(systemName: "gear")
						.imageScale(.large)
				})
			.presentation(presenting == .filterSelector
				? Modal(Text("Example")) {
					self.presenting = .none
				}
				: nil)
			.onAppear {
				self.appData.authorizeHealthKitAccess()
				self.appData.workoutList.reloadWorkouts()
			}
		}.presentation(presenting == .settings
			? Modal(SettingsView()) {
				self.presenting = .none
			}
			: nil)
	}
}

struct FilterStatusView: View {
	@EnvironmentObject private var appData: AppData

	var body: some View {
		VStack(alignment: .leading) {
			Text("WRKT_FILTER")
				.foregroundColor(.accentColor)

			Group {
				if appData.workoutList.filters.isEmpty {
					Text("WRKT_FILTER_ALL")
				} else {
					HStack(alignment: .firstTextBaseline) {
						Text("\(appData.workoutList.filters.count)_WRKT_FILTERS")
						Text("–")
						Text(appData.workoutList.filters.map { $0.name }.joined(separator: ", "))
					}
				}
			}.font(.caption).foregroundColor(.secondary)
		}
	}
}

#if DEBUG
struct WorkoutListView_Previews : PreviewProvider {
	static var previews: some View {
		WorkoutListView()
	}
}
#endif
