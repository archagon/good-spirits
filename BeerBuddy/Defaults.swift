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
    public func registerDefaults()
    {
        self.defaults.register(defaults: [
            Defaults.weekStartsOnMondayKey:false,
            Defaults.standardDrinkSizeKey:14
            ])
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
    
    public var standardDrinkSize: Double?
    {
        get
        {
            let val = self.defaults.double(forKey: Defaults.standardDrinkSizeKey)
            return val
        }
        set
        {
            self.defaults.setValue(newValue, forKey: Defaults.standardDrinkSizeKey)
        }
    }
    
    public var weeklyLimit: Double?
    {
        get
        {
            let val = self.defaults.double(forKey: Defaults.weeklyLimitKey)
            return val
        }
        set
        {
            self.defaults.setValue(newValue, forKey: Defaults.weeklyLimitKey)
        }
    }
    
    public var peakLimit: Double?
    {
        get
        {
            let val = self.defaults.double(forKey: Defaults.peakLimitKey)
            return val
        }
        set
        {
            self.defaults.setValue(newValue, forKey: Defaults.peakLimitKey)
        }
    }
    
    public var drinkFreeDays: Double?
    {
        get
        {
            let val = self.defaults.double(forKey: Defaults.drinkFreeDaysKey)
            return val
        }
        set
        {
            self.defaults.setValue(newValue, forKey: Defaults.drinkFreeDaysKey)
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
    
    public static var standardDrinkSize: Double?
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
    
    public static var drinkFreeDays: Double?
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
