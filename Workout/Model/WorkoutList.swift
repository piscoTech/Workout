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

	private(set) var workouts: [Workout]?
	private(set) var isLoading = false
	private(set) var error: Error?
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
		return wrkts?.filter { filters.isEmpty || filters.contains($0.raw.workoutActivityType) }
	}

	func reloadWorkouts() {
		allWorkouts = nil
		error = nil
		isLoading = true

		if appData.isHealthDataAvailable {
			DispatchQueue.main.asyncAfter(delay: 0.7) {
				self.loadBatch(targetDisplayCount: self.batchSize)
			}
		}

		updateFilteredList()
	}

	func loadMore() {
		isLoading = true
		loadBatch(targetDisplayCount: (workouts?.count ?? 0) + batchSize)
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
					}
				} else {
					self.canLoadMore = false

					self.allWorkouts = nil
					// This also notifies of updates
					self.updateFilteredList()
				}
			}

//				actions.insert({
//					self.isLoadingMore = loadingMore
//					self.tableView.beginUpdates()
//					if let added = addedLineCount {
//						if wasEmpty {
//							self.tableView.reloadSections([0], with: .automatic)
//						} else {
//							let oldCount = self.tableView.numberOfRows(inSection: 0)
//							self.tableView.insertRows(at: (oldCount ..< (oldCount + added)).map { IndexPath(row: $0, section: 0) }, with: .automatic)
//						}
//
//						self.loadMoreCell?.isEnabled = !loadingMore
//					} else {
//						self.tableView.reloadSections([0], with: .automatic)
//					}
//
//					if self.moreToBeLoaded && self.tableView.numberOfSections == 1 {
//						self.tableView.insertSections([1], with: .automatic)
//					} else if !self.moreToBeLoaded && self.tableView.numberOfSections > 1 {
//						self.tableView.deleteSections([1], with: .automatic)
//					}
//					self.tableView.endUpdates()
//				}, at: 0)
		}

		appData.healthStore.execute(workoutQuery)
	}

}
