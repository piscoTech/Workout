//
//  WorkoutMinuteTableViewCell.swift
//  Workout
//
//  Created by Marco Boschi on 15/01/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import UIKit

class WorkoutMinuteTableViewCell: UITableViewCell {

	@IBOutlet weak var stack: UIStackView!
	
	func update(for details: [WorkoutDetail], withData data: WorkoutMinute) {
		for v in stack.arrangedSubviews {
			v.removeFromSuperview()
		}
		
		for d in [.time] + details {
			let view = d.newView()
			d.update(view: view, with: data)
			
			stack.addArrangedSubview(view)
		}
	}

}
