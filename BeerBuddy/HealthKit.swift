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

class HealthKit
{
    static let shared = HealthKit()
    
    public enum HealthKitError: Error
    {
        case notAvailable
        case notAuthorized
        case notEnabled
        case notReady
    }
    
    private var loginPending: Bool = false
    public enum HealthKitLoginStatus
    {
        case unavailable
        case unauthorized
        case disabled
        case pendingAuthorization
        case enabledAndAuthorized
    }
    
    var loginStatus: HealthKitLoginStatus
    {
        if self.loginPending
        {
            return .pendingAuthorization
        }
        
        if let status = HealthKit.shared.authStatus()
        {
            switch status
            {
            case .notDetermined:
                return .disabled
            case .sharingAuthorized:
                return (Defaults.healthKitEnabled ?.enabledAndAuthorized : .disabled)
            case .sharingDenied:
                return . unauthorized
            }
        }
        else
        {
            return .unavailable
        }
    }
    
    var store: HKHealthStore? =
    {
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
    
    func authStatus() -> HKAuthorizationStatus?
    {
        let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        return self.store?.authorizationStatus(for: type)
    }
}

// Model interface.
extension HealthKit
{
    func delete(model: GlobalID) -> HealthKitError?
    {
        switch self.loginStatus
        {
        case .unavailable:
            return HealthKitError.notAvailable
        case .unauthorized:
            return HealthKitError.notAuthorized
        case .disabled:
            return HealthKitError.notEnabled
        case .pendingAuthorization:
            return HealthKitError.notReady
        case .enabledAndAuthorized:
            break
        }
        
        appDebug("HK: deleting model \(model)")
        
        let id = "\(model.siteID.uuidString).\(model.operationIndex)"
        
        let samplePredicate = HKQuery.predicateForObjects(withMetadataKey: HKMetadataKeySyncIdentifier, operatorType: .equalTo, value: id)
        
        let query = HKCorrelationQuery.init(type: HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!, predicate: samplePredicate, samplePredicates: [HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)! : samplePredicate], completion:
        { [weak `self`] (query, correlations, error) in
            if let error = error
            {
                appWarning("could not complete HealthKit delete -- \(error)")
            }
            else
            {
                for (_, correlation) in (correlations ?? []).enumerated()
                {
                    self?.store?.delete(Array(correlation.objects + [correlation]), withCompletion:
                    { (success, error) in
                        if let error = error as? HKError, error.code == HKError.errorInvalidArgument
                        {
                            appDebug("HK: model already deleted")
                        }
                        else if let error = error
                        {
                            appWarning("could not complete HealthKit delete -- \(error)")
                        }
                        else
                        {
                            appDebug("HK: deleted!")
                        }
                    })
                }
            }
        })
        
        self.store?.execute(query)
        
        return nil
    }
    
    func commit(model: Model, withTimestamp timestamp: NSNumber) -> HealthKitError?
    {
        switch self.loginStatus
        {
        case .unavailable:
            return HealthKitError.notAvailable
        case .unauthorized:
            return HealthKitError.notAuthorized
        case .disabled:
            return HealthKitError.notEnabled
        case .pendingAuthorization:
            return HealthKitError.notReady
        case .enabledAndAuthorized:
            break
        }
        
        appDebug("HK: syncing model \(model.metadata.id)")
        
        let alcoholCalories = (model.checkIn.drink.volume.converted(to: .fluidOunces).value * model.checkIn.drink.abv / 0.6) * 14 * 7 * Constants.calorieMultiplier
        let date = model.checkIn.time
        let id = "\(model.metadata.id.siteID.uuidString).\(model.metadata.id.operationIndex)"
        let v = timestamp
        let style = model.checkIn.drink.style.rawValue
        let name = model.checkIn.drink.name
        
        let type = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        let quantity = HKQuantity.init(unit: HKUnit.kilocalorie(), doubleValue: alcoholCalories)
        
        var sampleMetadata: [String:Any] =
        [
            HKMetadataKeySyncIdentifier: id,
            HKMetadataKeySyncVersion: v,
            HKMetadataKeyFoodType: style
        ]
        if let aName = name
        {
            sampleMetadata[Constants.healthKitFoodNameKey] = aName
        }
        
        let sample = HKQuantitySample.init(type: type, quantity: quantity, start: date, end: date, metadata: sampleMetadata)
        let food = HKCorrelation.init(type: HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!, start: date, end: date, objects: [sample], metadata: sampleMetadata)
        
        self.store?.save(food, withCompletion:
        { (success, error) in
            if let error = error
            {
                appWarning("HK: could not complete HealthKit update -- \(error)")
            }
            else
            {
                appDebug("HK: synced!")
            }
        })
        
        return nil
    }
}
