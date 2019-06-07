//
//  WorkoutView.swift
//  Workout
//
//  Created by Marco Boschi on 07/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import SwiftUI

struct WorkoutView : View {
    var body: some View {
        Text("I'm a workout")
			.navigationBarTitle(Text("Workout"), displayMode: .inline)
    }
}

#if DEBUG
struct WorkoutView_Previews : PreviewProvider {
    static var previews: some View {
        WorkoutView()
    }
}
#endif
