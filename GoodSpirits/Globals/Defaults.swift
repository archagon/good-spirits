//
//  Defaults.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-19.
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
import DataLayer

public struct Defaults
{
    private static let configuredKey = "Configured"
    private static let donatedKey: String = "DonatedKey"
    
    // AB: record-keeping for re-adding drink-free days (and others?)
    private static let limitCountry: String = "LimitCountry"
    private static let limitMale: String = "LimitMale"
    
    private static let weekStartsOnMondayKey: String = "WeekStartsOnMonday"
    private static let standardDrinkSizeKey: String = "StandardDrinkSize"
    private static let weeklyLimitKey: String = "WeeklyLimit"
    private static let peakLimitKey: String = "PeakLimit"
    private static let drinkFreeDaysKey: String = "DrinkFreeDays"
    
    #if HEALTH_KIT
    // Having this set means HK was authorized at some point.
    private static let healthKitEnabledKey: String = "HealthKitEnabled"
    private static let healthKitBaselineKey: String = "HealthKitBaseline" //TODO: ONLY to be used from RootViewController!
    #endif
    
    // Having this set means Untappd was authorized.
    private static let untappdTokenKey: String = "UntappdToken"
    private static let untappdBaselineKey: String = "UntappdBaseline" //TODO: ONLY to be used from RootViewController!
    private static let untappdDisplayNameKey: String = "UntappdDisplayName"
    private static let untappdRateLimitKey: String = "UntappdRateLimit"
    private static let untappdRateLimitRemainingKey: String = "UntappdRateLimitRemaining"
    
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
            Defaults.standardDrinkSizeKey: Constants.standardDrinkSizeDefault
            ])
        #if HEALTH_KIT
        self.defaults.register(defaults: [
            Defaults.healthKitEnabledKey: false
            ])
        #endif
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
    
    public var donated: Bool
    {
        get
        {
            let val = self.defaults.bool(forKey: Defaults.donatedKey)
            return val
        }
        set
        {
            self.defaults.set(newValue, forKey: Defaults.donatedKey)
        }
    }

    #if HEALTH_KIT
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
    
    public var healthKitBaseline: VectorClock?
    {
        get
        {
            guard let data = self.defaults.data(forKey: Defaults.healthKitBaselineKey) else
            {
                return nil
            }
            let val = try? PropertyListDecoder().decode(VectorClock.self, from: data)
            return val
        }
        set
        {
            let data = try? PropertyListEncoder().encode(newValue)
            self.defaults.set(data, forKey: Defaults.healthKitBaselineKey)
        }
    }
    #endif
    
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
    
    public var untappdBaseline: Int?
    {
        get
        {
            if self.defaults.value(forKey: Defaults.untappdBaselineKey) != nil
            {
                let val = self.defaults.integer(forKey: Defaults.untappdBaselineKey)
                return val
            }
            else
            {
                return nil
            }
        }
        set
        {
            self.defaults.set(newValue, forKey: Defaults.untappdBaselineKey)
        }
    }
    
    public var untappdDisplayName: String?
    {
        get
        {
            let val = self.defaults.string(forKey: Defaults.untappdDisplayNameKey)
            return val
        }
        set
        {
            self.defaults.set(newValue, forKey: Defaults.untappdDisplayNameKey)
        }
    }
    
    public var untappdRateLimit: Int?
    {
        get
        {
            if self.defaults.value(forKey: Defaults.untappdRateLimitKey) != nil
            {
                let val = self.defaults.integer(forKey: Defaults.untappdRateLimitKey)
                return val
            }
            else
            {
                return nil
            }
        }
        set
        {
            self.defaults.set(newValue, forKey: Defaults.untappdRateLimitKey)
        }
    }
    
    public var untappdRateLimitRemaining: Int?
    {
        get
        {
            if self.defaults.value(forKey: Defaults.untappdRateLimitRemainingKey) != nil
            {
                let val = self.defaults.integer(forKey: Defaults.untappdRateLimitRemainingKey)
                return val
            }
            else
            {
                return nil
            }
        }
        set
        {
            self.defaults.set(newValue, forKey: Defaults.untappdRateLimitRemainingKey)
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
    
    public static var donated: Bool
    {
        get
        {
            return Defaults().donated
        }
        set
        {
            var defaults = Defaults()
            defaults.donated = newValue
        }
    }
    
    #if HEALTH_KIT
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
    
    public static var healthKitBaseline: VectorClock?
    {
        get
        {
            return Defaults().healthKitBaseline
        }
        set
        {
            var defaults = Defaults()
            defaults.healthKitBaseline = newValue
        }
    }
    #endif
    
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
    
    public static var untappdBaseline: Int?
    {
        get
        {
            return Defaults().untappdBaseline
        }
        set
        {
            var defaults = Defaults()
            defaults.untappdBaseline = newValue
        }
    }
    
    public static var untappdDisplayName: String?
    {
        get
        {
            return Defaults().untappdDisplayName
        }
        set
        {
            var defaults = Defaults()
            defaults.untappdDisplayName = newValue
        }
    }
    
    public static var untappdRateLimit: Int?
    {
        get
        {
            return Defaults().untappdRateLimit
        }
        set
        {
            var defaults = Defaults()
            defaults.untappdRateLimit = newValue
        }
    }
    
    public static var untappdRateLimitRemaining: Int?
    {
        get
        {
            return Defaults().untappdRateLimitRemaining
        }
        set
        {
            var defaults = Defaults()
            defaults.untappdRateLimitRemaining = newValue
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
