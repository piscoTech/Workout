//
//  WorkoutGeneralDataCell.swift
//  Workout
//
//  Created by Marco Boschi on 23/07/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import UIKit

class WorkoutGeneralDataCell: UITableViewCell {
	
	@IBOutlet private weak var stackView: UIStackView!

	@IBOutlet weak private(set) var title: UILabel!
	@IBOutlet private(set) var detail: UILabel!
	
	func setCustomDetails(_ view: UIView?) {
		stackView.arrangedSubviews[1].removeFromSuperview()
		if let v = view {
			stackView.addArrangedSubview(v)
		} else {
			stackView.addArrangedSubview(detail)
		}
	}

}
