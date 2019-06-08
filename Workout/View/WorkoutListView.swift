//
//  WorkoutListView.swift
//  Workout
//
//  Created by Marco Boschi on 07/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import SwiftUI
import MBHealth

struct WorkoutListView : View {

	enum Presenting {
		case none, settings, filterSelector
	}

	@EnvironmentObject private var list: WorkoutList
	@State private var presenting = Presenting.none

	var body: some View {
		NavigationView {
			List {
				Button(action: {
					self.presenting = .filterSelector
				}) {
					VStack(alignment: .leading) {
						Text("WRKT_FILTER")
							.foregroundColor(.accentColor)

						Group {
							if list.filters.isEmpty {
								Text("WRKT_FILTER_ALL")
							} else {
								HStack(alignment: .firstTextBaseline) {
									Text("\(list.filters.count)_WRKT_FILTERS")
									Text("–")
									Text(list.filters.map { $0.name }.joined(separator: ", "))
								}
							}
						}.font(.caption).foregroundColor(.secondary)
					}
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
		}.presentation(presenting == .settings
			? Modal(SettingsView()) {
				self.presenting = .none
			}
			: nil)
	}
}

#if DEBUG
struct WorkoutListView_Previews : PreviewProvider {
	static var previews: some View {
		WorkoutListView()
	}
}
#endif
