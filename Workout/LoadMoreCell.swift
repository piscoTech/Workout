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
