//
//  Preferences.swift
//  Workout
//
//  Created by Marco Boschi on 03/08/16.
//  Copyright © 2016 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

private enum PreferenceKeys: String, KeyValueStoreKey {

	case systemOfUnits = "systemOfUnits"
	case stepSource = "stepSource"
	case maxHeartRate = "maxHeartRate"
	case runningHeartZones = "runningHeartZones"
	case exportRouteType = "exportRouteType"

	case reviewRequestCounter = "reviewRequestCounter"

	var description: String {
		return rawValue
	}

}

@objc
public protocol PreferencesDelegate: AnyObject {

	@objc optional func preferencesChanged()

	@objc optional func preferredSystemOfUnitsChanged()
	@objc optional func stepSourceChanged()
	@objc optional func runningHeartZonesConfigChanged()
	@objc optional func routeTypeChanged()

	@objc optional func reviewCounterUpdated()

}

public class Preferences {

	private enum Change {
		case generic, systemOfUnits, stepSource, hzConfig, reviewCounter, routeType
	}

	public let local = KeyValueStore(userDefaults: UserDefaults.standard)
	private var delegates: [WeakReference<PreferencesDelegate>] = []

	public init() {}

	public func add(delegate d: PreferencesDelegate) {
		delegates.append(WeakReference(d))
		delegates.compact()
	}

	private func saveChanges(_ change: Change = .generic) {
		local.synchronize()

		for d in delegates {
			guard let d = d.value else {
				continue
			}
			
			switch change {
			case .systemOfUnits:
				d.preferredSystemOfUnitsChanged?()
			case .stepSource:
				d.stepSourceChanged?()
			case .hzConfig:
				d.runningHeartZonesConfigChanged?()
			case .reviewCounter:
				d.reviewCounterUpdated?()
			case .routeType:
				d.routeTypeChanged?()
			case .generic:
				d.preferencesChanged?()
			}
		}
	}

	public let reviewRequestThreshold = 3
	public var reviewRequestCounter: Int {
		get {
			return local.integer(forKey: PreferenceKeys.reviewRequestCounter)
		}
		set {
			local.set(newValue, forKey: PreferenceKeys.reviewRequestCounter)
			saveChanges(.reviewCounter)
		}
	}

	/// Filter for step count source name.
	public var stepSourceFilter: StepSource {
		get {
			return StepSource.getSource(for: local.string(forKey: PreferenceKeys.stepSource) ?? "")
		}
		set {
			local.set(newValue.description, forKey: PreferenceKeys.stepSource)
			saveChanges(.stepSource)
		}
	}

	/// Max heart rate for calculating running heart zones.
	///
	/// Any value less than 60bpm (a normal resting heart rate) is considered invalid.
	public var maxHeartRate: Int? {
		get {
			let hr = local.integer(forKey: PreferenceKeys.maxHeartRate)
			return hr >= 60 ? hr : nil
		}
		set {
			if let hr = newValue {
				local.set(hr, forKey: PreferenceKeys.maxHeartRate)
			} else {
				local.removeObject(forKey: PreferenceKeys.maxHeartRate)
			}
			saveChanges(.hzConfig)
		}
	}

	/// The thresholds, i.e. lower bound, for each running heart zone.
	///
	/// The upper bound for each zone is the threshold for the next one or 100 for the last. Each threshold is in the range `0 ..< 100` and the array is sorted. Setting a value that does not respect this conditions will result in `nil` being set instead.
	public var runningHeartZones: [Int]? {
		get {
			return local.array(forKey: PreferenceKeys.runningHeartZones) as? [Int]
		}
		set {
			if let hz = newValue, hz.first(where: { $0 < 0 || $0 >= 100 }) == nil, hz == hz.sorted() {
				local.set(hz, forKey: PreferenceKeys.runningHeartZones)
			} else {
				local.removeObject(forKey: PreferenceKeys.runningHeartZones)
			}
			saveChanges(.hzConfig)
		}
	}

	/// The system of units, e.g. metric or imperial, the user wants to use.
	public var systemOfUnits: SystemOfUnits {
		get {
			return SystemOfUnits(rawValue: local.integer(forKey: PreferenceKeys.systemOfUnits)) ?? .default
		}
		set {
			local.set(newValue.rawValue, forKey: PreferenceKeys.systemOfUnits)
			saveChanges(.systemOfUnits)
		}
	}

	/// The format to use when exporting a workout route.
	public var routeType: RouteType {
		get {
			return RouteType(rawValue: local.string(forKey: PreferenceKeys.exportRouteType) ?? "") ?? .default
		}
		set {
			local.set(newValue.rawValue, forKey: PreferenceKeys.exportRouteType)
			saveChanges(.routeType)
		}
	}

}
