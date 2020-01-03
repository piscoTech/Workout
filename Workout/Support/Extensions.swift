//
//  Extensions.swift
//  Workout
//
//  Created by Marco Boschi on 01/07/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary
import WorkoutCore
import UIKit

extension WorkoutList {

	private static let anyTimeStr = NSLocalizedString("WRKT_FILTER_ANY_TIME", comment: "Any time")
	private static let fromTimeStr = NSLocalizedString("WRKT_FILTER_FROM_%@", comment: "From")
	private static let toTimeStr = NSLocalizedString("WRKT_FILTER_TO_%@", comment: "To")
	private static let fromToTimeStr = NSLocalizedString("WRKT_FILTER_FROM_%@_TO_%@", comment: "From-to")

	var dateFilterString: String? {
		if let f = startDate?.formattedDate, let t = endDate?.formattedDate {
			if f == t {
				return f
			} else {
				return String(format: WorkoutList.fromToTimeStr, f, t)
			}
		} else if let f = startDate?.formattedDate {
			return String(format: WorkoutList.fromTimeStr, f)
		} else if let t = endDate?.formattedDate {
			return String(format: WorkoutList.toTimeStr, t)
		} else {
			return nil
		}
	}

	var dateFilterStringEvenNoFilter: String {
		dateFilterString ?? WorkoutList.anyTimeStr
	}

}

extension UIView {
    func fadeIn(_ duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 1.0
            }, completion: completion)  }
    
    func fadeOut(_ duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.0
            }, completion: completion)
    }
}

extension String {
    /// Converts HTML string to a `NSAttributedString`

    var htmlAttributedString: NSAttributedString? {
        return try? NSAttributedString(data: Data(utf8), options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
    }
}
