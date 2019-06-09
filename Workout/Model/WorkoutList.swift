//
//  WorkoutList.swift
//  Workout
//
//  Created by Marco Boschi on 08/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import HealthKit
import Combine

typealias WorkoutListFilter = Set<HKWorkoutActivityType>

class WorkoutList {

	enum Error: Swift.Error {
		case missingHealth
	}

	weak var appData: AppData!

	private func didChange() {
		#warning("Force receive on main thread until receive(on:) is not available (Xcode bug)")
		DispatchQueue.main.async {
			self.appData.didChange.send(())
		}
	}

	var filters: WorkoutListFilter = [] {
		didSet {
			updateFilteredList()
		}
	}
	var isFiltering: Bool {
		return !filters.isEmpty
	}

	/// The workout list, if `nil` either there's an error or the initial loading is being performed or it's waiting to be performed.
	private(set) var workouts: [Workout]?
	private(set) var isLoading = false
	private(set) var error: Swift.Error?
	private(set) var canLoadMore = true

	private var allWorkouts: [Workout]?
	private let batchSize = 40
	private let filteredLoadMultiplier = 5

	private func updateFilteredList() {
		#warning("Implement me")
		workouts = filter(workouts: allWorkouts)

		didChange()
	}

	private func filter(workouts wrkts: [Workout]?) -> [Workout]? {
		return wrkts?.filter { filters.isEmpty || filters.contains($0.type) }
	}

	func reload() {
		allWorkouts = nil

		if appData.isHealthDataAvailable {
			error = nil
			isLoading = true

			DispatchQueue.main.asyncAfter(delay: 0.5) {
				self.loadBatch(targetDisplayCount: self.batchSize)
			}
		} else {
			isLoading = false
			error = WorkoutList.Error.missingHealth
		}

		updateFilteredList()
	}

	func loadMore() {
		isLoading = true
		didChange()

		DispatchQueue.main.async {
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
								wrkts.append(Workout.workoutFor(raw: w, basedOn: self.appData))
							}
						}
					}
					let disp = self.filter(workouts: wrkts) ?? []

					self.allWorkouts = (self.allWorkouts ?? []) + wrkts
					self.workouts = (self.workouts ?? []) + disp

					if self.canLoadMore && (self.workouts?.count ?? 0) < target {
						self.didChange()
						DispatchQueue.main.async {
							self.loadBatch(targetDisplayCount: target)
						}
					} else {
						self.isLoading = false
						self.didChange()
					}
				} else {
					self.isLoading = false
					self.canLoadMore = false

					self.allWorkouts = nil
					// This also notifies of updates
					self.updateFilteredList()
				}
			}
		}

		appData.healthStore.execute(workoutQuery)
	}

}
