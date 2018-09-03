//
//  HealthKitViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-22.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//
//  This file is part of Good Spirits.
//
//  Good Spirits is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Good Spirits is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import UIKit
import HealthKit
import DataLayer

class HealthKit
{
    static let shared = HealthKit()
    
    public enum HealthKitError: StringLiteralType, Error, LocalizedError
    {
        case notAvailable
        case notAuthorized
        case notEnabled
        case notReady
        case unknown
        
        public var errorDescription: String?
        {
            return self.rawValue
        }
    }
    
    // TOOD: should have enabledAndUnauthorized so that we can still disable HK even when unauthorized
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
                return .unauthorized
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
    func authorize(_ val: Bool, block: @escaping (Error?)->Void)
    {
        switch self.loginStatus
        {
        case .unavailable:
            block(HealthKitError.notAvailable)
            return
        case .unauthorized:
            block(HealthKitError.notAuthorized)
            return
        case .disabled:
            break
        case .pendingAuthorization:
            block(HealthKitError.notReady)
        case .enabledAndAuthorized:
            Defaults.healthKitEnabled = val
            block(nil)
            return
        }
        
        if val == false
        {
            block(nil)
            return
        }
        
        appDebug("authorizing HK...")
        
        authorizeHealthKit: do
        {
            // no need to authorize, already done
            if HealthKit.shared.authStatus() == .sharingAuthorized
            {
                Defaults.healthKitEnabled = true
                block(nil)
            }
            // need to attempt authorization
            else
            {
                self.loginPending = true
                
                let allTypes: Set<HKSampleType> = [ HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)! ]
                HealthKit.shared.store?.requestAuthorization(toShare: allTypes, read: nil)
                { [weak `self`] (success, error) in
                    onMain
                    {
                        self?.loginPending = false
                        
                        if success
                        {
                            appDebug("HK authorized!")
                            Defaults.healthKitEnabled = true
                            block(nil)
                        }
                        else
                        {
                            if let error = error
                            {
                                block(error)
                            }
                            else
                            {
                                block(HealthKitError.unknown)
                            }
                        }
                    }
                }
            }
        }
    }
    
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
        
        //let query = HKCorrelationQuery.init(type: HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!, predicate: samplePredicate, samplePredicates: [HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)! : samplePredicate])
        let query = HKSampleQuery.init(sampleType: HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!, predicate: samplePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil)
        { [weak `self`] (query, items, error) in
            if let error = error
            {
                appWarning("could not complete HealthKit delete -- \(error)")
            }
            else
            {
                for (_, item) in (items ?? []).enumerated()
                {
                    //self?.store?.delete(Array(correlation.objects + [correlation]), withCompletion:
                    self?.store?.delete(item, withCompletion:
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
        }
        
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
        
        // BUGFIX: I was getting an unclearable error 100 about not being able to delete something or other after doing
        // a bunch of check-ins, and this seems to work a lot better anyway
        let sample = HKQuantitySample.init(type: type, quantity: quantity, start: date, end: date, metadata: sampleMetadata)
        //let food = HKCorrelation.init(type: HKCorrelationType.correlationType(forIdentifier: HKCorrelationTypeIdentifier.food)!, start: date, end: date, objects: [sample], metadata: sampleMetadata)
        
        self.store?.save(sample, withCompletion:
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
