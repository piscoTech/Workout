//
//  InfoViewController.swift
//  Matrix
//
//  Created by Marco Boschi on 03/11/14.
//  Copyright (c) 2014 Marco Boschi. All rights reserved.
//

import UIKit

class AboutViewController: UITableViewController {
	
	private var appInfo: String!
	var delegate: ListTableViewController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let appVers = Bundle.main.objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
		let build = Bundle.main.objectForInfoDictionaryKey("CFBundleVersion") as! String

		appInfo = "Workout v\(appVers) (\(build))\n© 2016 Marco Boschi"
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if section == 1 {
			return appInfo
		}
		
		return nil
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch (indexPath.section, indexPath.row) {
		case (0, 0):
			delegate.authorize(self)
		case (1, 0):
			UIApplication.shared().openURL(URL(string: "https://github.com/Pisco95/Workout")!)
		default:
			break
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	// MARK: - Navigation
	
	@IBAction func done(_ sender: AnyObject) {
		dismiss(animated: true, completion: nil)
	}
	
}
