//
//  AdditionalDataExtractor.swift
//  Workout Core
//
//  Created by Marco Boschi on 20/12/2019.
//  Copyright © 2019 Marco Boschi. All rights reserved.
//

import Foundation
import HealthKit

protocol AdditionalDataExtractor: AdditionalDataManager {

	func extract(from healthStore: HKHealthStore, completion: @escaping (Bool) -> Void)

}
