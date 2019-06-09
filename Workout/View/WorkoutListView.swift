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

	fileprivate enum Presenting {
		case none, settings, filterSelector
	}

	@EnvironmentObject private var appData: AppData
	@State private var presenting = Presenting.none

	var body: some View {
		NavigationView {
			Content(presentingStatus: $presenting)
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
	private let presentingStatus: Binding<WorkoutListView.Presenting>
	private var presenting: WorkoutListView.Presenting {
		get {
			return presentingStatus.value
		}
		nonmutating set {
			presentingStatus.value = newValue
		}
	}

	init(presentingStatus: Binding<WorkoutListView.Presenting>) {
		self.presentingStatus = presentingStatus
	}

	var body: some View {
		List {
			// List controls
			Button(action: {
				self.presenting = .filterSelector
			}) {
				FilterStatusView()
			}

			if appData.workoutList.workouts == nil {
				// Errors
				if (appData.workoutList.error as? WorkoutList.Error) == .missingHealth {
					MessageCell("WRKT_LIST_ERR_NO_HEALTH")
				} else if appData.workoutList.error != nil {
					MessageCell("WRKT_LIST_ERR_LOADING")
				} else {
					MessageCell("WRKT_LIST_LOADING")
				}
			} else {
				// Workouts
				ForEach(appData.workoutList.workouts ?? []) { w in
					NavigationButton(destination: WorkoutView()) {
						Text(w.type.name)
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

private struct FilterStatusView: View {
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

private struct MessageCell: View {
	let text: LocalizedStringKey
	#warning("Implement")
	let hasActivityIndicator: Bool

	init(_ text: LocalizedStringKey, withActivityIndicator: Bool = false) {
		self.text = text
		self.hasActivityIndicator = withActivityIndicator
	}

	var body: some View {
		HStack {
			if hasActivityIndicator {
				Circle().fill().frame(width: 20, height: 20)
			}
			Text(text)
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
