//
//  ListTableViewController.swift
//  Workout
//
//  Created by Marco Boschi on 15/01/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit

class ListTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@IBAction func doRefresh(sender: AnyObject) {
		refresh()
	}
	
	func refresh() {
		print("I should reload the table")
	}

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */
	
	@IBAction func authorize(sender: AnyObject) {
//		let healthKitTypesToRead = Set(arrayLiteral:[
//		HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth),
//		HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBloodType),
//		HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex),
//		HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass),
//		HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight),
//		HKObjectType.workoutType()
//		])
		
		healthStore.requestAuthorizationToShareTypes(nil, readTypes: [
			HKObjectType.workoutType(),
			HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
			HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning)!
		]) { (success, err) in
			self.refresh()
		}
	}

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
