//
//  WorkoutListView.swift
//  Workout
//
//  Created by Marco Boschi on 07/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import HealthKit
import Combine
import SwiftUI
import StoreKit
import MBLibrary
import MBHealth

struct WorkoutListView : View {

	fileprivate enum Presenting {
		case none, settings, filterSelector
	}

	@EnvironmentObject private var healthData: Health
	@EnvironmentObject private var preferences: Preferences
	@EnvironmentObject private var workoutList: WorkoutList
	
	@State private var presenting = Presenting.none

	var body: some View {
		NavigationView {
			Content(presenting: $presenting)
				.navigationBarTitle(Text("WRKT_LIST_TITLE"))
				.navigationBarItems(leading: Button(action: { self.presenting = .settings }) {
					Image(systemName: "gear")
				}.imageScale(.large), trailing: HStack {
					Button(action: {
						print("Exporting...")
					}) {
						Image(systemName: "square.and.arrow.up")
					}
					Button(action: { self.workoutList.reload() }) {
						Image(systemName: "arrow.clockwise")
					}
				}.imageScale(.large))
				.presentation(presenting == .filterSelector
					? Modal(Text("Filters")) {
						self.presenting = .none
					}
					: nil)
				.onAppear {
					self.healthData.authorizeHealthKitAccess {
						self.workoutList.reload()
					}
					self.workoutList.reload()

					#if !DEBUG
					if self.preferences.reviewRequestCounter >= self.preferences.reviewRequestThreshold {
						SKStoreReviewController.requestReview()
					}
					#endif
				}
		}.presentation(presenting == .settings
			? Modal(SettingsView()) {
				self.presenting = .none
			}
			: nil)
	}
}

private struct Content: View {
	@EnvironmentObject private var workoutList: WorkoutList

	@Binding var presenting: WorkoutListView.Presenting

	#warning("The Workout objects created for viewing the details are leaking if the WorkoutView is opened (it seems to be the use of List there) and then the WorkoutList reloaded. Revert to separate obbjects when this bug is fixed.")
	var body: some View {
		List {
			// List controls
			Button(action: {
				self.presenting = .filterSelector
			}) {
				FilterStatusCell()
			}.disabled(workoutList.isLoading || workoutList.error != nil)

			if workoutList.workouts == nil {
				// Errors
				if (workoutList.error as? WorkoutList.Error) == .missingHealth {
					MessageCell("WRKT_ERR_NO_HEALTH")
				} else if workoutList.error != nil {
					MessageCell("WRKT_ERR_LOADING")
				} else {
					MessageCell("WRKT_LIST_LOADING", withActivityIndicator: true)
				}
			} else {
				// Workouts
				ForEach(workoutList.workouts ?? []) { w in
					NavigationButton(destination: WorkoutView()
						.environmentObject(w)
					) {
						WorkoutCell(workout: w)
					}
				}

				if (workoutList.workouts ?? []).isEmpty {
					Text("WRKT_LIST_ERR_NO_WORKOUT")
				}
			}

			// Load more
			if workoutList.workouts != nil && workoutList.canLoadMore { // && !inExportMode
				Button(action: {
					withAnimation { self.workoutList.loadMore() }
				}) {
					MessageCell("WRKT_LIST_MORE", withActivityIndicator: workoutList.isLoading)
						.foregroundColor(.accentColor)
				}.disabled(workoutList.isLoading)
			}
		}
	}

}

private struct FilterStatusCell: View {
	@EnvironmentObject private var workoutList: WorkoutList

	var body: some View {
		VStack(alignment: .leading) {
			Text("WRKT_FILTER")
				.foregroundColor(.accentColor)

			Group {
				if workoutList.filters.isEmpty {
					Text("WRKT_FILTER_ALL")
				} else {
					HStack(alignment: .firstTextBaseline) {
						Text("\(workoutList.filters.count)_WRKT_FILTERS")
						Text(textSeparator)
						Text(workoutList.filters.map { $0.name }.joined(separator: ", "))
					}
				}
			}.font(.caption).foregroundColor(.secondary)
		}
	}
}

private struct WorkoutCell: View {
	@EnvironmentObject private var preferences: Preferences

	let workout: Workout

	#warning("The if shout be an if-let")
	var body: some View {
		VStack(alignment: .leading) {
			Text(workout.type.name)
			HStack {
				Text(workout.startDate.getFormattedDate())
				Text(textSeparator)
				Text(workout.duration.getLocalizedDuration())
				if workout.totalDistance != nil {
					Text(textSeparator)
					Text(workout.totalDistance!.formatAsDistance(withUnit: workout.distanceUnit.unit(for: preferences.systemOfUnits)))
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
