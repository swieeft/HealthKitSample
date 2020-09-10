//
//  ViewController.swift
//  HealthKitSample
//
//  Created by Park GilNam on 2020/09/10.
//  Copyright © 2020 swieeft. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    let healthStore = HKHealthStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func buttonAction(_ sender: Any) {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }

        let healthKitTypes: Set<HKSampleType> = [HKObjectType.quantityType(forIdentifier: .stepCount)!, HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!]
        
        healthStore.requestAuthorization(toShare: nil, read: healthKitTypes) { (result, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                self.getWeekSteps()
                self.getTodaySteps()
                self.getSleep()
            }
        }
    }
    
    // 일주일 치 걸음 수 가져오기
    func getWeekSteps() {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let calendar = Calendar.current
        var interval = DateComponents()
        interval.day = 1
        
        let anchorComponents = calendar.dateComponents([.day, .month, .year], from: Date())
        
        let anchorDate = calendar.date(from: anchorComponents)
        
        let stepsQurey = HKStatisticsCollectionQuery(quantityType: stepsQuantityType, quantitySamplePredicate: nil, options: .cumulativeSum, anchorDate: anchorDate!, intervalComponents: interval)
        
        stepsQurey.initialResultsHandler = { query, results, error in
            let endDate = Date()
            let startDate = calendar.date(byAdding: .day, value: -7, to: endDate, wrappingComponents: false)
            
            if let myResults = results {
                myResults.enumerateStatistics(from: startDate!, to: endDate) { statistics, stop in
                    if let quantity = statistics.sumQuantity() {
                        let dateFormatter = DateFormatter()
                        dateFormatter.timeZone = .current
                        dateFormatter.timeZone = TimeZone(identifier: "UTC")
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        
                        let steps = quantity.doubleValue(for: HKUnit.count())
                        print("\(dateFormatter.string(from: statistics.startDate)): steps = \(steps)")
                    }
                }
            }
        }

        healthStore.execute(stepsQurey)
    }
    
    // 오늘 걸음 수 가져오기
    func getTodaySteps() {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                return
            }
            
            print("today : \(sum.doubleValue(for: HKUnit.count()))")
        }

        healthStore.execute(query)
    }
    
    // 수면
    func getSleep() {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: nil, limit: 30, sortDescriptors: [sortDescriptor]) { query, tmpResult, error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                guard let result = tmpResult else {
                    return
                }
                
                for item in result {
                    if let sample = item as? HKCategorySample {
                        let dateFormatter = DateFormatter()
                        dateFormatter.timeZone = .current
                        dateFormatter.timeZone = TimeZone(identifier: "UTC")
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                        
                        let value = sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue ? "취침" : "수면"
                        print("sleep : \(dateFormatter.string(from: sample.startDate)) ~ \(dateFormatter.string(from: sample.endDate)), value : \(value)")
                    }
                }
            }
        }
        
        healthStore.execute(query)
    }
}

