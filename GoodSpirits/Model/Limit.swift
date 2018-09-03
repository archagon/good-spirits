//
//  Limit.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-21.
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

public struct Limit
{
    public let countryCode: String
    public let grams: Double
    public let dailyMen: Double?
    public let dailyWomen: Double?
    public let weeklyMen: Double?
    public let weeklyWomen: Double?
    public let peakMen: Double?
    public let peakWomen: Double?
    
    private struct StandardDrinksData: Decodable
    {
        public let country: String
        public let grams: Double
        public let daily_limit_men: Double?
        public let daily_limit_women: Double?
        public let weekly_limit_men: Double?
        public let weekly_limit_women: Double?
        public let peak_daily_limit_men: Double?
        public let peak_daily_limit_women: Double?
    }
    
    public static func test()
    {
        func f(_ str: CVarArg) -> String
        {
            return String.init(format: "%.1f", str)
        }
        
        let divider = Limit.init(withCountryCode: "US")
        
        for item in Limit.data
        {
            if item.daily_limit_men == nil && item.daily_limit_women == nil && item.weekly_limit_men == nil && item.weekly_limit_women == nil { continue }
            
            let limit = Limit.init(withCountryCode: item.country)
            
            let dm = limit.grams(limit.dailyLimit(forMale: true) ?? Measurement<UnitVolume>.init(value: 0, unit: .fluidOunces))
            let dw = limit.grams(limit.dailyLimit(forMale: false) ?? Measurement<UnitVolume>.init(value: 0, unit: .fluidOunces))
            
            appDebug("daily limit for \(limit.countryName): \(f(dm))g (\(f(dm/divider.grams))) men, \(f(dw))g (\(f(dw/divider.grams))) women")
        }
        
        for item in Limit.data
        {
            if item.daily_limit_men == nil && item.daily_limit_women == nil && item.weekly_limit_men == nil && item.weekly_limit_women == nil { continue }
            
            let limit = Limit.init(withCountryCode: item.country)
            
            let wm = limit.grams(limit.weeklyLimit(forMale: true))
            let ww = limit.grams(limit.weeklyLimit(forMale: false))
            
            appDebug("weekly limit for \(limit.countryName): \(f(wm))g (\(f(wm/divider.grams))) men, \(f(ww))g (\(f(ww/divider.grams))) women")
        }
    }
    
    private static var data: [StandardDrinksData] =
    {
        guard
            let path = Bundle.main.path(forResource: "standard_drinks", ofType: "json"),
            let fileData = FileManager.default.contents(atPath: path) else
        {
            appError("could not load standard drinks file")
            return []
        }
        
        do
        {
            var allUnits = try JSONDecoder.init().decode([StandardDrinksData].self, from: fileData)
            
            allUnits = allUnits.filter
            {
                if $0.daily_limit_men != nil || $0.daily_limit_women != nil || $0.weekly_limit_men != nil || $0.weekly_limit_women != nil
                {
                    return true
                }
                else
                {
                    appDebug("missing data for country \($0.country)")
                    return false
                }
            }
            
            return allUnits
        }
        catch
        {
            appError("could not parse standard drinks file (\(error.localizedDescription))")
            return []
        }
    }()
    
    public static var allAvailableCountries: [String]
    {
        return data.map { $0.country }
    }
    
    public init(withGrams grams: Double, weeklyMen: Double, weeklyWomen: Double)
    {
        self.countryCode = "XX"
        self.grams = grams
        self.weeklyMen = weeklyMen
        self.weeklyWomen = weeklyWomen
        self.dailyMen = nil
        self.dailyWomen = nil
        self.peakMen = nil
        self.peakWomen = nil
    }
    
    public init(withCountryCode code: String)
    {
        for item in Limit.data
        {
            if item.country == code
            {
                precondition(item.daily_limit_men != nil || item.daily_limit_women != nil || item.weekly_limit_men != nil || item.weekly_limit_women != nil, "missing data for country \(item.country)")
                
                self.countryCode = item.country
                self.grams = item.grams
                self.dailyMen = item.daily_limit_men
                self.dailyWomen = item.daily_limit_women
                self.weeklyMen = item.weekly_limit_men
                self.weeklyWomen = item.weekly_limit_women
                self.peakMen = item.peak_daily_limit_men
                self.peakWomen = item.peak_daily_limit_women
                
                return
            }
        }
        
        appError("could not find country \(code) in standard drinks file")
        
        self.countryCode = "XX"
        self.grams = 0
        self.dailyMen = nil
        self.dailyWomen = nil
        self.weeklyMen = nil
        self.weeklyWomen = nil
        self.peakMen = nil
        self.peakWomen = nil
        
        return
    }
    
    public var countryName: String
    {
        let locale = Locale.current.localizedString(forRegionCode: self.countryCode)
        return locale ?? "unknown"
    }
    
    public static var standardLimit: Limit
    {
        let limit = Limit.init(withGrams: 10, weeklyMen: 20 * 7, weeklyWomen: 10 * 7)
        return limit
    }
    
    public var standardDrink: Measurement<UnitVolume>
    {
        return floz(self.grams)
    }
    
    public func dailyLimit(forMale: Bool) -> Measurement<UnitVolume>?
    {
        if forMale
        {
            if let dailyMen = self.dailyMen
            {
                return floz(dailyMen)
            }
            else if let weeklyMen = self.weeklyMen
            {
                return floz(weeklyMen / 7)
            }
            else
            {
                return nil
            }
        }
        else
        {
            if let dailyWomen = self.dailyWomen
            {
                return floz(dailyWomen)
            }
            else if let weeklyWomen = self.weeklyWomen
            {
                return floz(weeklyWomen / 7)
            }
            else
            {
                return dailyLimit(forMale: true)
            }
        }
    }
    
    public func weeklyLimit(forMale: Bool) -> Measurement<UnitVolume>
    {
        if forMale
        {
            if let weeklyMen = self.weeklyMen
            {
                return floz(weeklyMen)
            }
            else if let dailyMen = self.dailyMen
            {
                return floz(dailyMen * 7)
            }
            else
            {
                appError("could not find standard drinks data")
                return Measurement<UnitVolume>.init(value: 0, unit: .fluidOunces)
            }
        }
        else
        {
            if let weeklyWomen = self.weeklyWomen
            {
                return floz(weeklyWomen)
            }
            else if let dailyWomen = self.dailyWomen
            {
                return floz(dailyWomen * 7)
            }
            else
            {
                return weeklyLimit(forMale: true)
            }
        }
    }
    
    public func peakLimit(forMale: Bool) -> Measurement<UnitVolume>?
    {
        // TODO:
        return nil
    }
    
    public func standardUnits(forAlcohol alcohol: Measurement<UnitVolume>) -> Double
    {
        let g = grams(alcohol)
        return g / self.grams
    }
    
    private func floz(_ grams: Double) -> Measurement<UnitVolume>
    {
        return Limit.floz(grams)
    }
    
    private func grams(_ floz: Measurement<UnitVolume>) -> Double
    {
        return Limit.grams(floz)
    }
    
    private static func floz(_ grams: Double) -> Measurement<UnitVolume>
    {
        let val = (0.6 / 14) * grams
        let measure = Measurement<UnitVolume>.init(value: val, unit: .fluidOunces)
        return measure
    }
    
    private static func grams(_ floz: Measurement<UnitVolume>) -> Double
    {
        let std = floz.converted(to: .fluidOunces)
        let val = (14 / 0.6) * std.value
        return val
    }
    
    public static func alcoholToFluidOunces(fromGrams grams: Double) -> Measurement<UnitVolume> { return Limit.floz(grams) }
    public static func alcoholToGrams(fromFluidOunces floz: Measurement<UnitVolume>) -> Double { return Limit.grams(floz) }
}
