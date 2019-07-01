//
//  FilterCells.swift
//  Workout
//
//  Created by Marco Boschi on 01/07/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import UIKit

class DateFilterCell: UITableViewCell {

	@IBOutlet weak var title: UILabel!
	@IBOutlet weak var date: UILabel!

	@IBOutlet private weak var clearButton: UIButton!
	var clearAction: (() -> Void)?

	override func awakeFromNib() {
		super.awakeFromNib()

		if #available(iOS 13, *) {} else {
			clearButton.setImage(#imageLiteral(resourceName: "Clear"), for: [])
		}
		clearButton.addTarget(self, action: #selector(clear), for: .primaryActionTriggered)
	}

	@objc private func clear() {
		clearAction?()
	}

}

class DatePickerCell: UITableViewCell {

	@IBOutlet private weak var picker: UIDatePicker!
	var date: Date {
		get {
			return picker.date
		}
		set {
			picker.date = newValue
		}
	}
	var dateChanged: ((Date) -> Void)?

	override func awakeFromNib() {
		super.awakeFromNib()

		picker.addTarget(self, action: #selector(dateHasChanged), for: .valueChanged)
	}

	@objc private func dateHasChanged() {
		dateChanged?(picker.date)
	}
}
