//
//  SelectCalendarTVC.swift
//  Workout
//
//  Created by Maxime Killinger on 16/12/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import UIKit
import EventKit

class SelectCalendarTableViewController: UITableViewController {
        
    var calendars: [EKCalendar]?
    let refreshC = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCalendarAuthorizationStatus()

        // Configure Refresh Control
        self.tableView.refreshControl = self.refreshC
        refreshC.addTarget(self, action: #selector(calendarDidAdd(_:)), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        checkCalendarAuthorizationStatus()
    }
    
    func checkCalendarAuthorizationStatus() {
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        
        switch (status) {
        case EKAuthorizationStatus.notDetermined:
            requestAccessToCalendar()
        case EKAuthorizationStatus.authorized:
            loadCalendars()
            refreshTableView()
        case EKAuthorizationStatus.restricted, EKAuthorizationStatus.denied:
            loadCalendars()
            refreshTableView()
        @unknown default:
            loadCalendars()
            refreshTableView()
        }
    }
    
    func requestAccessToCalendar() {
        EKEventStore().requestAccess(to: .event, completion: {
            (accessGranted: Bool, error: Error?) in
            
            if accessGranted == true {
                DispatchQueue.main.async(execute: {
                    self.loadCalendars()
                    self.refreshTableView()
                })
            } else {
                DispatchQueue.main.async(execute: {
                    return
                })
            }
        })
    }
    
    func loadCalendars() {
        self.calendars = EKEventStore().calendars(for: EKEntityType.event)
        calendars?.forEach {
            if !$0.allowsContentModifications {
                calendars?.removeElement($0)
            }
        }
        self.calendars = self.calendars?.sorted() { (cal1, cal2) -> Bool in
            return cal1.title < cal2.title
        }
    }
    
    func refreshTableView() {
        self.tableView.reloadData()
    }
        
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let calendars = self.calendars {
            return calendars.count == 0 ? 1 : calendars.count
        }
        
        return 0
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "basicCell")! as! CalendarTableViewCell
        
        if calendars != nil && !(calendars?.isEmpty ?? true), let calendars = self.calendars {
            let calendarName = calendars[(indexPath as NSIndexPath).row].title
            let calendarIdentifier = calendars[(indexPath as NSIndexPath).row].calendarIdentifier
            
            cell.calendarName?.text = calendarName.htmlAttributedString?.string
            cell.calendarUniqueIdentifier = calendarIdentifier
            if preferences.defaultCalendarSelected == "" && calendarIdentifier == EKEventStore().defaultCalendarForNewEvents?.calendarIdentifier {
                cell.accessoryType = .checkmark
                preferences.defaultCalendarSelected = EKEventStore().defaultCalendarForNewEvents?.calendarIdentifier ?? ""
            }
            if calendarIdentifier == preferences.defaultCalendarSelected {
                cell.accessoryType = .checkmark
            }
            cell.calendarColoredDot.backgroundColor = UIColor(cgColor: calendars[(indexPath as NSIndexPath).row].cgColor)
        } else {
            cell.textLabel?.text = "Unknown Calendar Name"
            cell.calendarUniqueIdentifier = nil
            cell.isUserInteractionEnabled = false
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? CalendarTableViewCell {
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none
                if EKEventStore().defaultCalendarForNewEvents != nil {
                    preferences.defaultCalendarSelected = EKEventStore().defaultCalendarForNewEvents?.calendarIdentifier ?? ""
                    for i in 0..<(tableView.numberOfRows(inSection: 0)) {
                        if ((tableView.cellForRow(at: IndexPath(row: i, section: 0)) as! CalendarTableViewCell).calendarUniqueIdentifier == preferences.defaultCalendarSelected) {
                            tableView.cellForRow(at: IndexPath(row: i, section: 0))?.accessoryType = .checkmark
                        }
                    }
                }
            } else {
                for i in 0..<(tableView.numberOfRows(inSection: 0)) {
                    tableView.cellForRow(at: IndexPath(row: i, section: 0))?.accessoryType = .none
                }
                cell.accessoryType = .checkmark
                preferences.defaultCalendarSelected = cell.calendarUniqueIdentifier ?? ""
            }
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: Calendar Added Delegate
    @objc func calendarDidAdd(_ sender: Any) {
        self.loadCalendars()
        self.refreshTableView()
        self.refreshC.endRefreshing()
    }
}
