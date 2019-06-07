//
//  WorkoutListView.swift
//  Workout
//
//  Created by Marco Boschi on 07/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import SwiftUI

struct WorkoutListView : View {
	enum Presenting {
		case none, settings, filterSelector
	}

	@State private var presenting = Presenting.none

	var body: some View {
		NavigationView {
			List {
				Button(action: {
					self.presenting = .filterSelector
				}) {
					VStack(alignment: .leading) {
						Text("Filter")
							.foregroundColor(.accentColor)
						Text("Current filter")
							.font(.footnote)
							.foregroundColor(.secondary)
					}
				}

				ForEach(0 ..< 5) { index in
					NavigationButton(destination: WorkoutView()) {
						Text("Test \(index)")
					}
				}
			}
			.navigationBarTitle(Text("Workouts"))
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
