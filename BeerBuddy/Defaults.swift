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
    // AB: record-keeping for re-adding drink-free days (and others?)
    private static let limitCountry: String = "LimitCountry"
    private static let limitMale: String = "LimitMale"
    
    private static let weekStartsOnMondayKey: String = "WeekStartsOnMonday"
    private static let untappdTokenKey: String = "UntappdToken"
    private static let standardDrinkSizeKey: String = "StandardDrinkSize"
    private static let weeklyLimitKey: String = "WeeklyLimit"
    private static let peakLimitKey: String = "PeakLimit"
    private static let drinkFreeDaysKey: String = "DrinkFreeDays"
    
    private let defaults: UserDefaults
    
    public init(_ defaults: UserDefaults = UserDefaults.standard)
    {
        self.defaults = defaults
    }
}

extension Defaults
{
    public static let standardDrinkSizeDefault: Double = 14
    public static let standardDrinkSizeRange: ClosedRange<Double> = 3...30
    public static let weeklyLimitRange: ClosedRange<Double> = 0...999
    public static let peakLimitRange: ClosedRange<Double> = 0...999
    public static let drinkFreeDaysRange: ClosedRange<Int> = 0...8
}

extension Defaults
{
    public func registerDefaults()
    {
        self.defaults.register(defaults: [
            Defaults.weekStartsOnMondayKey:false,
            Defaults.standardDrinkSizeKey:Defaults.standardDrinkSizeDefault
            ])
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
    
    public var untappdToken: String?
    {
        get
        {
            let val = self.defaults.string(forKey: Defaults.untappdTokenKey)
            return val
        }
        set
        {
            self.defaults.setValue(newValue, forKey: Defaults.untappdTokenKey)
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
            let commitValue = min(max(newValue, Defaults.standardDrinkSizeRange.lowerBound), Defaults.standardDrinkSizeRange.upperBound)
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
                let commitValue = min(max(value, Defaults.weeklyLimitRange.lowerBound), Defaults.weeklyLimitRange.upperBound)
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
                let commitValue = min(max(value, Defaults.peakLimitRange.lowerBound), Defaults.peakLimitRange.upperBound)
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
                let commitValue = min(max(value, Defaults.drinkFreeDaysRange.lowerBound), Defaults.drinkFreeDaysRange.upperBound)
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
