//
//  SettingsViewController_HealthKit.swift
//  Good Spirits
//
//  Created by Alexei Baboulevitch on 2018-8-26.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import HealthKit

// Quick and dirty HealthKit state machine.
extension SettingsViewController
{
    var healthKitLoginStatus: HealthKitLoginStatus
    {
        if self.healthKitLoginPending
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
    
    func transitionHealthKitStatus(_ enabled: Bool)
    {
        switch self.healthKitLoginStatus
        {
        case .unavailable:
        break //no-op, can't do anything
        case .unauthorized:
        break //no-op, can't do anything
        case .disabled:
            if enabled
            {
                // TODO: move this to HealthKit proper
                authorizeHealthKit: do
                {
                    // no need to authorize, already done
                    if HealthKit.shared.authStatus() == .sharingAuthorized
                    {
                        Defaults.healthKitEnabled = true
                    }
                        // need to attempt authorization
                    else
                    {
                        self.healthKitLoginPending = true
                        //self.updateHealthKitToggleAppearance() happens below
                        
                        let allTypes: Set<HKSampleType> = [ HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)! ]
                        HealthKit.shared.store?.requestAuthorization(toShare: allTypes, read: nil)
                        { [weak `self`] (success, error) in
                        onMain
                            {
                                if success
                                {
                                    Defaults.healthKitEnabled = true
                                }
                                else
                                {
                                    if let error = error
                                    {
                                        appWarning("HealthKit error -- \(error)")
                                    }
                                }
                                
                                self?.healthKitLoginPending = false
                                self?.updateHealthKitToggleAppearance()
                            }
                        }
                    }
                }
            }
        case .pendingAuthorization:
        break //can't do anything until login completes
        case .enabledAndAuthorized:
            if !enabled
            {
                Defaults.healthKitEnabled = false
            }
        }
        
        self.updateHealthKitToggleAppearance()
    }
}
