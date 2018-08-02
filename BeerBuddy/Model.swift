//
//  Model.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public struct Model
{
    public typealias ID = UInt64
    
    public struct CheckIn
    {
        public let id: ID
        public let untappdId: ID?
        public let time: Date
        public let added: Date
        public let drink: Drink
    }
    
    public struct Drink
    {
        public enum Style: String, RawRepresentable
        {
            case beer
            case wine
            case sake
            
            public static var defaultStyle: Style
            {
                return .beer
            }
            
            // TODO: move to data file?
            public var defaultABV: Double
            {
                get
                {
                    switch self
                    {
                    case .beer: return 0.05
                    case .wine: return 0.15
                    case .sake: return 0.17
                    }
                }
            }
            
            public var defaultVolume: Measurement<UnitVolume>
            {
                get
                {
                    switch self
                    {
                    case .beer: return Measurement<UnitVolume>.init(value: 12, unit: .fluidOunces)
                    case .wine: return Measurement<UnitVolume>.init(value: 4, unit: .fluidOunces)
                    case .sake: return Measurement<UnitVolume>.init(value: 3.5, unit: .fluidOunces)
                    }
                }
            }
        }
        
        public let name: String?
        public let style: Style
        public let abv: Double
        public let price: Double?
        public let volume: Measurement<UnitVolume>
    }
}

public extension Model
{
    // TODO: maybe this does not belong here
    public static func assetNameForDrink(_ drink: Model.Drink) -> String
    {
        let epsilon = Measurement<UnitVolume>.init(value: 0.5, unit: .fluidOunces)
        
        switch drink.style
        {
        case .beer:
            if drink.volume >= Measurement<UnitVolume>.init(value: 200, unit: .milliliters) && drink.volume <= Measurement<UnitVolume>.init(value: 300, unit: .milliliters)
            {
                return "lowball"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 8, unit: .fluidOunces), delta: Measurement<UnitVolume>.init(value: 2, unit: .fluidOunces))
            {
                return "snifter"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 12, unit: .fluidOunces), delta: Measurement<UnitVolume>.init(value: 1, unit: .fluidOunces))
            {
                return "tulip"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 500, unit: .milliliters), delta: Measurement<UnitVolume>.init(value: 10, unit: .milliliters))
            {
                return "weizen_glass"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 16, unit: .fluidOunces), delta: epsilon)
            {
                return "pint_shaker"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 20, unit: .fluidOunces), delta: epsilon)
            {
                return "pint_nonic"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 1000, unit: .milliliters), delta: epsilon)
            {
                return "beer_mug"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 2000, unit: .milliliters), delta: epsilon)
            {
                return "beer_boot"
            }
        case .wine:
            if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 3, unit: .fluidOunces), delta: epsilon)
            {
                return "wine_glass_small"
            }
            else if drink.volume >= Measurement<UnitVolume>.init(value: 4.5, unit: .fluidOunces) && drink.volume <= Measurement<UnitVolume>.init(value: 8, unit: .fluidOunces)
            {
                return "wine_glass_big"
            }
        case .sake:
            if drink.volume <= Measurement<UnitVolume>.init(value: 2, unit: .fluidOunces)
            {
                return "shot_glass"
            }
        }
        
        return "tall_glass"
    }
}

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
        for item in Limit.data
        {
            if item.daily_limit_men == nil && item.daily_limit_women == nil && item.weekly_limit_men == nil && item.weekly_limit_women == nil { continue }
            
            let limit = Limit.init(withCountryCode: item.country)
            
            let dm = limit.grams(limit.dailyLimit(forMale: true) ?? Measurement<UnitVolume>.init(value: 0, unit: .fluidOunces))
            let dw = limit.grams(limit.dailyLimit(forMale: false) ?? Measurement<UnitVolume>.init(value: 0, unit: .fluidOunces))
            let wm = limit.grams(limit.weeklyLimit(forMale: true))
            let ww = limit.grams(limit.weeklyLimit(forMale: false))
            
            print("Daily limit for \(limit.countryName): \(dm)g (\(dm/limit.grams)) men, \(dw)g (\(dw/limit.grams)) women")
            print("Weekly limit for \(limit.countryName): \(wm)g (\(wm/limit.grams)) men, \(ww)g (\(ww/limit.grams)) women")
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
            let allUnits = try JSONDecoder.init().decode([StandardDrinksData].self, from: fileData)
            return allUnits
        }
        catch
        {
            appError("could not parse standard drinks file (\(error.localizedDescription))")
            return []
        }
    }()
    
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
        let val = (0.6 / 14) * grams
        let measure = Measurement<UnitVolume>.init(value: val, unit: .fluidOunces)
        return measure
    }
    
    private func grams(_ floz: Measurement<UnitVolume>) -> Double
    {
        let std = floz.converted(to: .fluidOunces)
        let val = (14 / 0.6) * std.value
        return val
    }
    
    public func alcoholToFluidOunces(fromGrams grams: Double) -> Measurement<UnitVolume> { return floz(grams) }
    public func alcoholToGrams(fromFluidOunces floz: Measurement<UnitVolume>) -> Double { return grams(floz) }
}
