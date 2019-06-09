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
import MBLibrary

struct WorkoutListView : View {

	fileprivate enum Presenting {
		case none, settings, filterSelector
	}

	@EnvironmentObject private var appData: AppData
	@State private var presenting = Presenting.none

	var body: some View {
		NavigationView {
			Content(presenting: $presenting)
				.navigationBarTitle(Text("WRKT_LIST_TITLE"))
				.navigationBarItems(leading: Button(action: { self.presenting = .settings }) {
					Image(systemName: "gear")
					}.imageScale(.large), trailing: HStack {
					Button(action: { print("Export...") }) {
						Image(systemName: "square.and.arrow.up")
					}.disabled(true)
					Button(action: { self.appData.workoutList.reload() }) {
						Image(systemName: "arrow.clockwise")
					}
				}.imageScale(.large))
				.presentation(presenting == .filterSelector
					? Modal(Text("Filters")) {
						self.presenting = .none
					}
					: nil)
				.onAppear {
					self.appData.authorizeHealthKitAccess()
					self.appData.workoutList.reload()
				}
		}.presentation(presenting == .settings
			? Modal(SettingsView()) {
				self.presenting = .none
			}
			: nil)
	}
}

private struct Content: View {
	@EnvironmentObject private var appData: AppData
	@Binding fileprivate var presenting: WorkoutListView.Presenting

	var body: some View {
		List {
			// List controls
			Button(action: {
				self.presenting = .filterSelector
			}) {
				FilterStatusCell()
			}.disabled(appData.workoutList.isLoading || appData.workoutList.error != nil)

			if appData.workoutList.workouts == nil {
				// Errors
				if (appData.workoutList.error as? WorkoutList.Error) == .missingHealth {
					MessageCell("WRKT_LIST_ERR_NO_HEALTH")
				} else if appData.workoutList.error != nil {
					MessageCell("WRKT_LIST_ERR_LOADING")
				} else {
					MessageCell("WRKT_LIST_LOADING", withActivityIndicator: true)
				}
			} else {
				// Workouts
				ForEach(appData.workoutList.workouts ?? []) { w in
					NavigationButton(destination: WorkoutView()) {
						WorkoutCell(workout: w)
					}
				}

				if (appData.workoutList.workouts ?? []).isEmpty {
					Text("WRKT_LIST_ERR_NO_WORKOUT")
				}
			}

			// Load more
			if appData.workoutList.workouts != nil && appData.workoutList.canLoadMore { // && !inExportMode
				Button(action: {
					withAnimation { self.appData.workoutList.loadMore() }
				}) {
					MessageCell("WRKT_LIST_MORE", withActivityIndicator: appData.workoutList.isLoading)
						.foregroundColor(.accentColor)
					}.disabled(appData.workoutList.isLoading)
			}
		}
	}

}

private struct FilterStatusCell: View {
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
						Text(textSeparator)
						Text(appData.workoutList.filters.map { $0.name }.joined(separator: ", "))
					}
				}
			}.font(.caption).foregroundColor(.secondary)
		}
	}
}

private struct MessageCell: View {
	let text: LocalizedStringKey
	let hasActivityIndicator: Bool

	init(_ text: LocalizedStringKey, withActivityIndicator: Bool = false) {
		self.text = text
		self.hasActivityIndicator = withActivityIndicator
	}

	var body: some View {
		HStack {
			if hasActivityIndicator {
				ActivityIndicator(style: .medium, animating: Binding.constant(true))
			}
			Text(text)
		}
	}
}

private struct WorkoutCell: View {
	@EnvironmentObject private var appData: AppData
	let workout: Workout

	private var distanceUnit: HKUnit {
		workout.distanceUnit.unit(for: appData.preferences)
	}

	var body: some View {
		VStack(alignment: .leading) {
			Text(workout.type.name)
			HStack {
				Text(workout.startDate.getFormattedDate())
				Text(textSeparator)
				Text(workout.duration.getLocalizedDuration())
				if workout.totalDistance != nil {
					Text(textSeparator)
					Text(workout.totalDistance!.doubleValue(for: distanceUnit).getFormattedDistance(withUnit: distanceUnit))
				}
			}.font(.caption)
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
