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

extension WorkoutList {

	private static let anyTimeStr = NSLocalizedString("WRKT_FILTER_ANY_TIME", comment: "Any time")
	private static let fromTimeStr = NSLocalizedString("WRKT_FILTER_FROM_%@", comment: "From")
	private static let toTimeStr = NSLocalizedString("WRKT_FILTER_TO_%@", comment: "To")
	private static let fromToTimeStr = NSLocalizedString("WRKT_FILTER_FROM_%@_TO_%@", comment: "From-to")

	var dateFilterString: String? {
		if let f = startDate?.getFormattedDate(), let t = endDate?.getFormattedDate() {
			if f == t {
				return f
			} else {
				return String(format: WorkoutList.fromToTimeStr, f, t)
			}
		} else if let f = startDate {
			return String(format: WorkoutList.fromTimeStr, f.getFormattedDate())
		} else if let t = endDate {
			return String(format: WorkoutList.toTimeStr, t.getFormattedDate())
		} else {
			return nil
		}
	}

	var dateFilterStringEvenNoFilter: String {
		dateFilterString ?? WorkoutList.anyTimeStr
	}

}
