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
	
	func update(for details: [WorkoutDetail], withData data: WorkoutMinute, andSystemOfUnits sysUnits: SystemOfUnits) {
		for v in stack.arrangedSubviews {
			v.removeFromSuperview()
		}
		
		for d in [.time] + details {
			let view = d.display(data, withSystemOfUnits: sysUnits)
			
			stack.addArrangedSubview(view)
		}
	}

}
