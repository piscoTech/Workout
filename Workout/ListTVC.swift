//
//  ListTableViewController.swift
//  Workout
//
//  Created by Marco Boschi on 15/01/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import UIKit
import HealthKit
import MBLibrary
import GoogleMobileAds

class ListTableViewController: UITableViewController, GADBannerViewDelegate {
	
	var workouts: [HKWorkout]!

    override func viewDidLoad() {
        super.viewDidLoad()

        refresh()
		initializeAds()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if !preferences.bool(forKey: PreferenceKey.authorized) || preferences.integer(forKey: PreferenceKey.authVersion) < authRequired {
			authorize(self)
		}
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@IBAction func doRefresh(_ sender: AnyObject) {
		refresh()
	}
	
	private func refresh() {
		let sortDescriptor = SortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
		let type = HKObjectType.workoutType()
		let predicate =  HKQuery.predicateForWorkouts(with: .running)
		let workoutQuery = HKSampleQuery(sampleType: type, predicate: predicate, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [sortDescriptor]) { (_, r, _) in
			self.workouts = nil
			if let res = r as? [HKWorkout] {
				self.workouts = res
			}
			
			DispatchQueue.main.async { self.tableView.reloadData() }
		}
		
		healthStore.execute(workoutQuery)
	}

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts?.count ?? 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if workouts == nil {
			return tableView.dequeueReusableCell(withIdentifier: "error", for: indexPath)
		}

		let cell = tableView.dequeueReusableCell(withIdentifier: "workout", for: indexPath)
		let w = workouts[indexPath.row]
		
		cell.textLabel?.text = w.startDate.getFormattedDateTime()
		
		var detail = w.duration.getDuration()
		if let dist = w.totalDistance {
			detail += " - " + (dist.doubleValue(for: .meter()) / 1000).getFormattedDistance()
		}
		cell.detailTextLabel?.text = detail

        return cell
    }
	
	func authorize(_ sender: AnyObject) {
		healthStore.requestAuthorization(toShare: nil, read: [
			HKObjectType.workoutType(),
			HKObjectType.quantityType(forIdentifier: .heartRate)!,
			HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
			HKObjectType.quantityType(forIdentifier: .stepCount)!
		]) { (success, _) in
			if success {
				preferences.set(true, forKey: PreferenceKey.authorized)
				preferences.set(authRequired, forKey: PreferenceKey.authVersion)
				preferences.synchronize()
			}
			
			self.refresh()
		}
	}
	
	// MARK: - Ads stuff
	
	private var adView: GADBannerView!
	private var adRetryDelay = 1.0
	
	private func initializeAds() {
		navigationController?.isToolbarHidden = true
		
		guard areAdsEnabled else {
			return
		}
		
		adView = GADBannerView(adSize: kGADAdSizeBanner)
		adView.translatesAutoresizingMaskIntoConstraints = false
		adView.rootViewController = self
		adView.delegate = self
		adView.adUnitID = adsID
		
		adView.load(getAdRequest())
		navigationController?.toolbar.addSubview(adView)
		var constraint = NSLayoutConstraint(item: adView, attribute: .centerX, relatedBy: .equal, toItem: navigationController!.toolbar, attribute: .centerX, multiplier: 1, constant: 0)
		constraint.isActive = true
		constraint = NSLayoutConstraint(item: adView, attribute: .top, relatedBy: .equal, toItem: navigationController!.toolbar, attribute: .top, multiplier: 1, constant: 0)
		constraint.isActive = true
	}
	
	func adViewDidReceiveAd(_ bannerView: GADBannerView!) {
		//Display ad
		navigationController?.setToolbarHidden(false, animated: true)
	}
	
	func adView(_ bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
		//Remove ad view
		DispatchQueue.main.after(delay: adRetryDelay) {
			self.adView.load(self.getAdRequest())
			self.adRetryDelay *= 2
		}
	}
	
	func terminateAds() {
		guard adView != nil else {
			//Ads already removed
			return
		}

		navigationController?.setToolbarHidden(true, animated: true)
		DispatchQueue.main.after(delay: 2) {
			self.adView?.removeFromSuperview()
			self.adView = nil
		}
	}
	
	private func getAdRequest() -> GADRequest {
		let req = GADRequest()
		req.testDevices = [kGADSimulatorID]
		return req
	}

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
		guard let id = segue.identifier else {
			return
		}
		
		switch id {
		case "showWorkout":
			if let dest = segue.destinationViewController as? WorkoutTableViewController, let indexPath = tableView.indexPathForSelectedRow {
				dest.rawWorkout = workouts[indexPath.row]
			}
		case "info":
			if let dest = segue.destinationViewController as? UINavigationController, let root = dest.topViewController as? AboutViewController {
				root.delegate = self
			}
		default:
			return
		}
    }

}
