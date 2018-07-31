//
//  Defaults.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-19.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public class Defaults
{
    private static let weekStartsOnMondayKey: String = "WeekStartsOnMonday"
    private static let untappdTokenKey: String = "UntappdToken"
    private static let standardDrinkSizeKey: String = "StandardDrinkSize"
    private static let weeklyLimitKey: String = "WeeklyLimit"
    private static let peakLimitKey: String = "PeakLimit"
    private static let drinkFreeDaysKey: String = "DrinkFreeDays"
    
    public static func registerDefaults()
    {
        UserDefaults.standard.register(defaults: [
            weekStartsOnMondayKey:false,
            standardDrinkSizeKey:14
            ])
    }
    
    public static var weekStartsOnMonday: Bool
    {
        get
        {
            let val = UserDefaults.standard.bool(forKey: weekStartsOnMondayKey)
            return val
        }
        set
        {
            UserDefaults.standard.set(newValue, forKey: weekStartsOnMondayKey)
        }
    }
    
    public static var untappdToken: String?
    {
        get
        {
            let val = UserDefaults.standard.string(forKey: untappdTokenKey)
            return val
        }
        set
        {
            UserDefaults.standard.setValue(newValue, forKey: untappdTokenKey)
        }
    }
    
    public static var standardDrinkSize: Double?
    {
        get
        {
            let val = UserDefaults.standard.double(forKey: standardDrinkSizeKey)
            return val
        }
        set
        {
            UserDefaults.standard.setValue(newValue, forKey: standardDrinkSizeKey)
        }
    }
    
    public static var weeklyLimit: Double?
    {
        get
        {
            let val = UserDefaults.standard.double(forKey: weeklyLimitKey)
            return val
        }
        set
        {
            UserDefaults.standard.setValue(newValue, forKey: weeklyLimitKey)
        }
    }
    
    public static var peakLimit: Double?
    {
        get
        {
            let val = UserDefaults.standard.double(forKey: peakLimitKey)
            return val
        }
        set
        {
            UserDefaults.standard.setValue(newValue, forKey: peakLimitKey)
        }
    }
    
    public static var drinkFreeDays: Double?
    {
        get
        {
            let val = UserDefaults.standard.double(forKey: drinkFreeDaysKey)
            return val
        }
        set
        {
            UserDefaults.standard.setValue(newValue, forKey: drinkFreeDaysKey)
        }
    }
}
