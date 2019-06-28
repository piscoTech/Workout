//
//  WorkoutList.swift
//  Workout
//
//  Created by Marco Boschi on 08/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import HealthKit

public typealias WorkoutListFilter = Set<HKWorkoutActivityType>

public protocol WorkoutListDelegate: AnyObject {

	func loadingStatusChanged()
	func listChanged()
	func additionalWorkoutsLoaded(count: Int, oldCount: Int)

}

public class WorkoutList {

	private enum Error: Swift.Error {
		case missingHealth
	}

	private let healthData: Health
	private let preferences: Preferences

	public weak var delegate: WorkoutListDelegate?

	public var filters: WorkoutListFilter = [] {
		didSet {
			updateFilteredList()
		}
	}
	public var isFiltering: Bool {
		return !filters.isEmpty
	}
	public var availableFilters: [HKWorkoutActivityType] {
		guard var types = allWorkouts?.map({ $0.raw.workoutActivityType }) else {
			return []
		}

		types.removeDuplicates()
		return types
	}

	/// The workout list, if `nil` either there's an error or the initial loading is being performed or it's waiting to be performed.
	public private(set) var workouts: [Workout]?
	public private(set) var isLoading = false
	public private(set) var error: Swift.Error?
	public private(set) var canLoadMore = false

	private var allWorkouts: [Workout]?
	private let batchSize = 40
	private let filteredLoadMultiplier = 5

	public init(healthData: Health, preferences: Preferences) {
		self.healthData = healthData
		self.preferences = preferences
	}

	private func updateFilteredList() {
		workouts = filter(workouts: allWorkouts)

		DispatchQueue.main.async {
			self.delegate?.listChanged()
		}
	}

	private func filter(workouts wrkts: [Workout]?) -> [Workout]? {
		return wrkts?.filter { filters.isEmpty || filters.contains($0.type) }
	}

	public func reload() {
		guard !isLoading else {
			return
		}
		
		allWorkouts = nil
		canLoadMore = false

		if healthData.isHealthDataAvailable {
			error = nil
			isLoading = true

			DispatchQueue.main.async {
				self.delegate?.loadingStatusChanged()
			}
			DispatchQueue.main.asyncAfter(delay: 0.5) {
				self.loadBatch(targetDisplayCount: self.batchSize)
			}
		} else {
			isLoading = false
			error = WorkoutList.Error.missingHealth
		}

		updateFilteredList()
	}

	public func loadMore() {
		guard !isLoading else {
			return
		}

		isLoading = true
		DispatchQueue.main.async {
			self.delegate?.loadingStatusChanged()
			self.loadBatch(targetDisplayCount: (self.workouts?.count ?? 0) + self.batchSize)
		}
	}

	private func loadBatch(targetDisplayCount target: Int) {
		let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
		let type = HKObjectType.workoutType()
		let predicate: NSPredicate?
		let limit: Int

		if let last = allWorkouts?.last {
			let allCount = allWorkouts?.count ?? 0
			predicate = NSPredicate(format: "%K <= %@", HKPredicateKeyPathStartDate, last.startDate as NSDate)
			let sameDateCount = allCount - (allWorkouts?.firstIndex { $0.startDate == last.startDate } ?? allCount)
			let missing = target - (workouts?.count ?? 0)
			limit = sameDateCount + min(batchSize, isFiltering ? missing * filteredLoadMultiplier : missing)
		} else {
			predicate = nil
			limit = target
		}

		let workoutQuery = HKSampleQuery(sampleType: type, predicate: predicate, limit: limit, sortDescriptors: [sortDescriptor]) { (_, r, err) in
			// There's no need to call .load() as additional data is not needed here, we just need information about units
			let res = r as? [HKWorkout]

			self.error = err
			DispatchQueue.workout.async {
				if let res = res {
					self.canLoadMore = res.count >= limit

					var wrkts: [Workout] = []
					do {
						wrkts.reserveCapacity(res.count)
						var addAll = false
						// By searching the reversed collection we reduce comparison as both collections are sorted
						let revLoaded = (self.allWorkouts ?? []).reversed()
						for w in res {
							if addAll || !revLoaded.contains(where: { $0.raw == w }) {
								// Stop searching already loaded workouts when the first new workout is not present.
								addAll = true
								wrkts.append(Workout.workoutFor(raw: w, from: self.healthData, and: self.preferences))
							}
						}
					}
					let disp = self.filter(workouts: wrkts) ?? []
					let oldCount = self.workouts?.count ?? 0

					self.allWorkouts = (self.allWorkouts ?? []) + wrkts
					self.workouts = (self.workouts ?? []) + disp

					if self.canLoadMore && (self.workouts?.count ?? 0) < target {
						DispatchQueue.main.async {
							self.delegate?.additionalWorkoutsLoaded(count: disp.count, oldCount: oldCount)
							self.loadBatch(targetDisplayCount: target)
						}
					} else {
						self.isLoading = false
						DispatchQueue.main.async {
							self.delegate?.loadingStatusChanged()
							self.delegate?.additionalWorkoutsLoaded(count: disp.count, oldCount: oldCount)
						}
					}
				} else {
					self.isLoading = false
					self.canLoadMore = false
					DispatchQueue.main.async {
						self.delegate?.loadingStatusChanged()
					}

					self.allWorkouts = nil
					// This also notifies of updates
					self.updateFilteredList()
				}
			}
		}

		healthData.store.execute(workoutQuery)
	}

}
