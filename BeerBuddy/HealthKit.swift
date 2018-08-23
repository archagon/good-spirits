//
//  HealthKitViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-22.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import UIKit
import HealthKit
import DataLayer

// NEXT:
// STATES:
//  * token not set, auth status not determined
//  * token not set, auth status ???
//  * token set, but calls fail
//  * token set, calls succeed

class HealthKit
{
    static let shared = HealthKit()
    
    var store: HKHealthStore? =
    {
        // NEXT: add this check to settings
        if HKHealthStore.isHealthDataAvailable()
        {
            let store = HKHealthStore()
            return store
        }
        else
        {
            return nil
        }
    }()
    
    var testUUID = UUID()
    
    func authStatus() -> HKAuthorizationStatus?
    {
        let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        return self.store?.authorizationStatus(for: type)
    }
    
    func test()
    {
        let allTypes: Set<HKSampleType> = [ HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)! ]
        
        HealthKit.shared.store?.requestAuthorization(toShare: allTypes, read: nil)
        { (success, error) in
            if !success
            {
                appError("\(error!)")
            }
            else
            {
                let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
                let quantity = HKQuantity.init(unit: HKUnit.kilocalorie(), doubleValue: Double.random(in: 75..<200))
                let date = Date()
                
                let id = self.testUUID.uuidString
                let v = Date().timeIntervalSince1970
                let style = "beer"
                let name = "Random Beve"
                let alcohol = 14 * 1.5
                
                let sampleMetadata: [String:Any] =
                [
                    HKMetadataKeySyncIdentifier: id,
                    HKMetadataKeySyncVersion: v,
                    HKMetadataKeyFoodType: style,
                    "BBMetadataKeyFoodName": name,
                    "BBMetadataKeyAlcoholGrams": alcohol
                ]
                let foodMetadata: [String:Any] =
                [
                    HKMetadataKeyFoodType: style,
                    "BBMetadataKeyFoodName": name,
                    "BBMetadataKeyAlcoholGrams": alcohol,
                    HKMetadataKeySyncIdentifier: id,
                    HKMetadataKeySyncVersion: v,
                ]
                
                let sample = HKQuantitySample.init(type: type, quantity: quantity, start: date, end: date, metadata: sampleMetadata)
                //let sample = HKQuantitySample.init(type: type, quantity: quantity, start: date, end: date, metadata: sampleMetadata)
                let food = HKCorrelation.init(type: HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!, start: date, end: date, objects: [sample], metadata: sampleMetadata)
                
                let authType = HealthKit.shared.store?.authorizationStatus(for: type) ?? .sharingDenied
                
                if authType == .sharingAuthorized
                {
                    HealthKit.shared.store?.save(food, withCompletion:
                    { (success, error) in
                        if !success
                        {
                            appError("\(error!)")
                        }
                        else
                        {
                            print("hk: success!!!")
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute:
                            {
                                let samplePredicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeySyncIdentifier, operatorType: .equalTo, value: id)
                                
                                let query = HKCorrelationQuery.init(type: HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!, predicate: samplePredicate, samplePredicates: [HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)! : samplePredicate], completion:
                                { (query, correlations, error) in
                                    if let error = error
                                    {
                                        appError("\(error)")
                                    }
                                    else
                                    {
                                        DispatchQueue.main.async
                                        {
                                            print("correlations retrieved")
                                            
                                            for (i, correlation) in (correlations ?? []).enumerated()
                                            {
                                                print("found correlation \(i)")
                                                
                                                HealthKit.shared.store?.delete(Array(correlation.objects + [correlation]), withCompletion:
                                                { (success, error) in
                                                    if !success
                                                    {
                                                        if let aError = error as? HKError, aError.code == HKError.errorInvalidArgument
                                                        {
                                                            print("object already deleted")
                                                        }
                                                        else
                                                        {
                                                            appError("\(error!)")
                                                        }
                                                    }
                                                    else
                                                    {
                                                        print("deleted!")
                                                    }
                                                })
                                            }
                                        }
                                    }
                                })
                                
                                HealthKit.shared.store?.execute(query)
                            })
                        }
                    })
                }
                else
                {
                    appError("healthkit not authorized")
                }
            }
        }
    }
}

// Model interface.
extension HealthKit
{
    func commit(model: Model)
    {
    }
}
