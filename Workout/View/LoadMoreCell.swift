//
//  LoadMoreCell.swift
//  Workout
//
//  Created by Marco Boschi on 04/08/2018.
//  Copyright © 2018 Marco Boschi. All rights reserved.
//

import UIKit

class LoadMoreCell: UITableViewCell {
	
	@IBOutlet private weak var loadIndicator: UIActivityIndicatorView!
	@IBOutlet private weak var loadBtn: UIButton!

	override func awakeFromNib() {
		super.awakeFromNib()

		if #available(iOS 13.0, *) {
			loadIndicator.style = .medium
		} else {
			loadIndicator.style = .gray
		}
		loadIndicator.color = .systemGray
	}
	
	var isEnabled: Bool {
		get {
			return loadBtn.isEnabled
		}
		set {
			loadBtn.isEnabled = newValue
			loadIndicator.isHidden = newValue
			if !newValue {
				loadIndicator.startAnimating()
			} else {
				loadIndicator.stopAnimating()
			}
		}
	}
	
}
