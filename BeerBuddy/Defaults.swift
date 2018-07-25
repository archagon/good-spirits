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
    private static let limitCountryCodeKey: String = "LimitCountry"
    private static let weekStartsOnMondayKey: String = "WeekStartsOnMonday"
    private static let untappdTokenKey: String = "UntappdToken"
    
    public static func registerDefaults()
    {
        UserDefaults.standard.register(defaults: [
            weekStartsOnMondayKey:false,
            limitCountryCodeKey:"US"
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
    
    public static var limitCountryCode: String?
    {
        get
        {
            let val = UserDefaults.standard.string(forKey: limitCountryCodeKey)
            return val
        }
        set
        {
            UserDefaults.standard.setValue(newValue, forKey: limitCountryCodeKey)
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
}
