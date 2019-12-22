//
//  WorkoutBulkExporter.swift
//  Workout Core
//
//  Created by Marco Boschi on 29/06/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation
import MBLibrary

public protocol WorkoutBulkExporterDelegate: AnyObject {

	/// Tells the delegate that the selection has changed for the workouts at the given offsets.
	/// - parameter offsets: The offsets of the changed workouts, if `nil` the selection changed for _all_ workouts.
	func exportSelectionChanged(for offsets: [Int]?)

	/// Tells the delegate that the export process has progressed.
	/// - parameter progress: The current progress as a percentage in the range [0,1].
	func exportProgressChanged(_ progress: Float)

	/// Tells the delegate that the export process has completed.
	/// - parameter data: The `URL` of the file containit the exported data or `nil` if the process failed.
	/// - parameter failures: The list of start time of the workouts that failed to export or `nil` if the process failed.
	func exportCompleted(data: URL?, individualFailures failures: [Date]?)

}

public class WorkoutBulkExporter: WorkoutDelegate {

	private var workouts: WorkoutList
	public private(set) var selection: [Bool]

	public weak var delegate: WorkoutBulkExporterDelegate?

	public init?(_ workouts: WorkoutList) {
		guard !workouts.isLoading, workouts.workouts != nil, workouts.error == nil, !workouts.locked else {
			return nil
		}
		workouts.locked = true

		self.workouts = workouts
		selection = [Bool](repeating: true, count: workouts.workouts?.count ?? 0)
	}

	deinit {
		workouts.locked = false
		fileStream?.close()
	}

	// MARK: - Selection

	public subscript(_ offset: Int) -> Bool {
		get {
			selection[offset]
		}
		set {
			guard !isExporting, !exportCompleted else {
				return
			}

			selection[offset] = newValue
			delegate?.exportSelectionChanged(for: [offset])
		}
	}

	public func selectAll(_ select: Bool) {
		guard !isExporting, !exportCompleted else {
			return
		}

		selection = [Bool](repeating: select, count: selection.count)
		delegate?.exportSelectionChanged(for: nil)
	}

	/// Whether it's possible to proceed with the export process.
	///
	/// This value is `true` when at least one workout is selected.
	public var canExport: Bool {
		selection.firstIndex(of: true) != nil
	}

	// MARK: - Exporting

	public private(set) var isExporting = false
	public private(set) var exportCompleted = false

	private let maximumConcurrentLoad = 10
	private let filePath = URL(fileURLWithPath: NSString(string: NSTemporaryDirectory()).appendingPathComponent("allWorkouts.csv"))
	private var fileStream: OutputStream?

	private var exported: Float = 0
	private var toBeExported: Float = 0
	private var failures: [Date] = []
	/// The list of workouts currently being loaded or waiting to be written to file.
	private var loading: [Workout]?
	/// The queue of workouts waiting to be loaded.
	private var queue: [Workout]?

	private var systemOfUnits: SystemOfUnits?

	public func export(from healthData: Health, and preferences: Preferences) -> Bool {
		// Ensure that there's at least a workout to export
		guard canExport else {
			return false
		}

		guard let fileStream = OutputStream(url: filePath, append: false) else {
			completeExport(success: false)
			return true
		}
		self.fileStream = fileStream
		fileStream.open()

		// Prepare the file with the header
		do {
			let sep = CSVSeparator
			let header = "Type\(sep)Start\(sep)End\(sep)Duration\(sep)Distance\(sep)\("Average Heart Rate".toCSV())\(sep)\("Max Heart Rate".toCSV())\(sep)\("Average Pace".toCSV())\(sep)\("Average Speed".toCSV())\(sep)\("Active Energy".toCSV())\(sep)\("Total Energy".toCSV())\(sep)\("Elevation Ascended".toCSV())\(sep)\("Elevation Descended".toCSV())\n"

			try fileStream.write(header)
		} catch {
			completeExport(success: false)
			return true
		}

		isExporting = true
		systemOfUnits = preferences.systemOfUnits
		let wrkts = Array(zip(workouts.workouts ?? [], selection).lazy
			.filter { $0.1 }
			.map { Workout.workoutFor(raw: $0.0.raw, from: healthData, and: preferences, delegate: self) }
		)
		toBeExported = Float(wrkts.count)

		// Load firt batch
		loading = wrkts.prefix(maximumConcurrentLoad).map { w in
			// Avoid loading additional (and useless) detail
			w.load(quickly: true)
			return w
		}

		// Queue the rest
		queue = wrkts.count > maximumConcurrentLoad ? Array(wrkts[maximumConcurrentLoad...]) : []

		return true
	}

	public func workoutLoaded(_: Workout) {
		// Move to a serial queue to synchronize access to counter
		DispatchQueue.workout.async {
			guard self.isExporting, !self.exportCompleted,
				var loading = self.loading, var queue = self.queue,
				let fh = self.fileStream, let sys = self.systemOfUnits else {
				return
			}
			defer {
				self.loading = loading
				self.queue = queue
			}

			// Consume loaded workouts
			let loaded = loading.prefix(while: { $0.isLoaded })
			self.exported += Float(loaded.count)
			loading = loaded.count < loading.count ? Array(loading[loaded.count...]) : []

			for w in loaded {
				if w.hasError {
					self.failures.append(w.startDate)
				} else {
					do {
						try fh.write((w.exportGeneralData(for: sys) + "\n"))
					} catch {
						self.completeExport(success: false)
						return
					}
				}
			}

			self.delegate?.exportProgressChanged(self.exported / self.toBeExported)

			// Load other
			if !queue.isEmpty, loading.count < self.maximumConcurrentLoad {
				let load: [Workout] = queue.prefix(self.maximumConcurrentLoad - loading.count).map { w in
					// Avoid loading additional (and useless) detail
					w.load(quickly: true)
					return w
				}
				loading += load
				queue = Array(queue[load.count...])
			}

			// Check for completion
			if queue.isEmpty && loading.isEmpty {
				self.completeExport(success: true)
			}
		}
	}

	private func completeExport(success: Bool) {
		if !self.exportCompleted {
			delegate?.exportCompleted(data: success ? filePath : nil, individualFailures: success ? failures : nil)
		}

		exportCompleted = true
		isExporting = false
		loading = nil
		queue = nil
		fileStream?.close()
		fileStream = nil
	}

}
