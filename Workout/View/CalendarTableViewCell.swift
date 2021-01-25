//
//  CalendarTableViewCell.swift
//  Workout
//
//  Created by Maxime Killinger on 18/12/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import UIKit

class CalendarTableViewCell: UITableViewCell {
    @IBOutlet weak var calendarColoredDot: UIView!
    @IBOutlet weak var calendarName: UILabel!
    
    var calendarUniqueIdentifier : String?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        calendarColoredDot.layer.cornerRadius = calendarColoredDot.frame.size.width / 2
        calendarColoredDot.clipsToBounds = true
    }
}
