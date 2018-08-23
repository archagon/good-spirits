//
//  Defaults.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-19.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public struct Defaults
{
    private static let configuredKey = "Configured"
    
    // AB: record-keeping for re-adding drink-free days (and others?)
    private static let limitCountry: String = "LimitCountry"
    private static let limitMale: String = "LimitMale"
    
    private static let weekStartsOnMondayKey: String = "WeekStartsOnMonday"
    private static let standardDrinkSizeKey: String = "StandardDrinkSize"
    private static let weeklyLimitKey: String = "WeeklyLimit"
    private static let peakLimitKey: String = "PeakLimit"
    private static let drinkFreeDaysKey: String = "DrinkFreeDays"
    
    // Having this set means HK was authorized at some point.
    private static let healthKitEnabledKey: String = "HealthKitEnabled"
    
    private static let untappdEnabledKey: String = "UntappdEnabled"
    private static let untappdTokenKey: String = "UntappdToken"
    private static let untappdBaselineKey: String = "UntappdBaseline"
    
    private let defaults: UserDefaults
    
    public init(_ defaults: UserDefaults = UserDefaults.standard)
    {
        self.defaults = defaults
    }
}

extension Defaults
{
    public func registerDefaults()
    {
        self.defaults.register(defaults: [
            Defaults.weekStartsOnMondayKey: false,
            Defaults.standardDrinkSizeKey: Constants.standardDrinkSizeDefault,
            Defaults.healthKitEnabledKey: false,
            Defaults.untappdEnabledKey: false
            ])
    }
    
    public var configured: Bool
    {
        get
        {
            let val = self.defaults.bool(forKey: Defaults.configuredKey)
            return val
        }
        set
        {
            self.defaults.set(newValue, forKey: Defaults.configuredKey)
        }
    }
    
    public var healthKitEnabled: Bool
    {
        get
        {
            let val = self.defaults.bool(forKey: Defaults.healthKitEnabledKey)
            return val
        }
        set
        {
            self.defaults.set(newValue, forKey: Defaults.healthKitEnabledKey)
        }
    }
    
    public var untappdEnabled: Bool
    {
        get
        {
            let val = self.defaults.bool(forKey: Defaults.untappdEnabledKey)
            return val
        }
        set
        {
            self.defaults.set(newValue, forKey: Defaults.untappdEnabledKey)
        }
    }
    
    public var untappdToken: String?
    {
        get
        {
            let val = self.defaults.string(forKey: Defaults.untappdTokenKey)
            return val
        }
        set
        {
            self.defaults.set(newValue, forKey: Defaults.untappdTokenKey)
        }
    }
    
    public var limitCountry: String?
    {
        get
        {
            let val = self.defaults.string(forKey: Defaults.limitCountry)
            return val
        }
        set
        {
            self.defaults.set(newValue, forKey: Defaults.limitCountry)
        }
    }
    
    public var limitMale: Bool?
    {
        get
        {
            if self.defaults.value(forKey: Defaults.limitMale) != nil
            {
                let val = self.defaults.bool(forKey: Defaults.limitMale)
                return val
            }
            else
            {
                return nil
            }
        }
        set
        {
            self.defaults.set(newValue, forKey: Defaults.limitMale)
        }
    }
    
    public var weekStartsOnMonday: Bool
    {
        get
        {
            let val = self.defaults.bool(forKey: Defaults.weekStartsOnMondayKey)
            return val
        }
        set
        {
            self.defaults.set(newValue, forKey: Defaults.weekStartsOnMondayKey)
        }
    }
    
    public var standardDrinkSize: Double
    {
        get
        {
            let val = self.defaults.double(forKey: Defaults.standardDrinkSizeKey)
            return val
        }
        set
        {
            let commitValue = min(max(newValue, Constants.standardDrinkSizeRange.lowerBound), Constants.standardDrinkSizeRange.upperBound)
            self.defaults.setValue(commitValue, forKey: Defaults.standardDrinkSizeKey)
        }
    }
    
    public var weeklyLimit: Double?
    {
        get
        {
            if self.defaults.value(forKey: Defaults.weeklyLimitKey) != nil
            {
                let val = self.defaults.double(forKey: Defaults.weeklyLimitKey)
                return (val == 0 ? nil : val)
            }
            else
            {
                return nil
            }
        }
        set
        {
            if let value = newValue
            {
                let commitValue = min(max(value, Constants.weeklyLimitRange.lowerBound), Constants.weeklyLimitRange.upperBound)
                self.defaults.setValue(commitValue, forKey: Defaults.weeklyLimitKey)
            }
            else
            {
                self.defaults.setValue(nil, forKey: Defaults.weeklyLimitKey)
            }
        }
    }
    
    public var peakLimit: Double?
    {
        get
        {
            if self.defaults.value(forKey: Defaults.peakLimitKey) != nil
            {
                let val = self.defaults.double(forKey: Defaults.peakLimitKey)
                return (val == 0 ? nil : val)
            }
            else
            {
                return nil
            }
        }
        set
        {
            if let value = newValue
            {
                let commitValue = min(max(value, Constants.peakLimitRange.lowerBound), Constants.peakLimitRange.upperBound)
                self.defaults.setValue(commitValue, forKey: Defaults.peakLimitKey)
            }
            else
            {
                self.defaults.setValue(nil, forKey: Defaults.peakLimitKey)
            }
        }
    }
    
    public var drinkFreeDays: Int?
    {
        get
        {
            if self.defaults.value(forKey: Defaults.drinkFreeDaysKey) != nil
            {
                let val = self.defaults.integer(forKey: Defaults.drinkFreeDaysKey)
                return (val == 0 ? nil : val)
            }
            else
            {
                return nil
            }
        }
        set
        {
            if let value = newValue
            {
                let commitValue = min(max(value, Constants.drinkFreeDaysRange.lowerBound), Constants.drinkFreeDaysRange.upperBound)
                self.defaults.setValue(commitValue, forKey: Defaults.drinkFreeDaysKey)
            }
            else
            {
                self.defaults.setValue(nil, forKey: Defaults.drinkFreeDaysKey)
            }
        }
    }
}
    
extension Defaults
{
    public static func registerDefaults()
    {
        Defaults().registerDefaults()
    }
    
    public static var configured: Bool
    {
        get
        {
            return Defaults().configured
        }
        set
        {
            var defaults = Defaults()
            defaults.configured = newValue
        }
    }
    
    public static var healthKitEnabled: Bool
    {
        get
        {
            return Defaults().healthKitEnabled
        }
        set
        {
            var defaults = Defaults()
            defaults.healthKitEnabled = newValue
        }
    }
    
    public static var untappdEnabled: Bool
    {
        get
        {
            return Defaults().untappdEnabled
        }
        set
        {
            var defaults = Defaults()
            defaults.untappdEnabled = newValue
        }
    }
    
    public static var untappdToken: String?
    {
        get
        {
            return Defaults().untappdToken
        }
        set
        {
            var defaults = Defaults()
            defaults.untappdToken = newValue
        }
    }
    
    public static var weekStartsOnMonday: Bool
    {
        get
        {
            return Defaults().weekStartsOnMonday
        }
        set
        {
            var defaults = Defaults()
            defaults.weekStartsOnMonday = newValue
        }
    }
    
    public static var standardDrinkSize: Double
    {
        get
        {
            return Defaults().standardDrinkSize
        }
        set
        {
            var defaults = Defaults()
            defaults.standardDrinkSize = newValue
        }
    }
    
    public static var weeklyLimit: Double?
    {
        get
        {
            return Defaults().weeklyLimit
        }
        set
        {
            var defaults = Defaults()
            defaults.weeklyLimit = newValue
        }
    }
    
    public static var peakLimit: Double?
    {
        get
        {
            return Defaults().peakLimit
        }
        set
        {
            var defaults = Defaults()
            defaults.peakLimit = newValue
        }
    }
    
    public static var drinkFreeDays: Int?
    {
        get
        {
            return Defaults().drinkFreeDays
        }
        set
        {
            var defaults = Defaults()
            defaults.drinkFreeDays = newValue
        }
    }
}
