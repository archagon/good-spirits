//
//  Model.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import DataLayer

public extension DrinkStyle
{
    public static var defaultStyle: DrinkStyle
    {
        return .beer
    }
    
    public var defaultABV: Double
    {
        switch self
        {
        case .beer:
            return 0.065
        case .wine:
            return 0.135
        case .fortifiedWine:
            return 0.18
        case .mead:
            return 0.12
        case .cider:
            return 0.6
        case .sake:
            return 0.17
        case .vodka:
            return 0.4
        case .gin:
            return 0.45
        case .tequilla:
            return 0.4
        case .rum:
            return 0.4
        case .whisky:
            return 0.45
        case .brandy:
            return 0.4
        case .liqueur:
            return 0.22
            
        case .other:
            fallthrough
        case .placeholder:
            fallthrough
        case .overflow:
            return 0.05 //doesn't matter
        }
    }
    
    public var defaultVolume: Measurement<UnitVolume>
    {
        get
        {
            switch self
            {
            case .beer:
                return .init(value: 12, unit: .fluidOunces)
            case .wine:
                return .init(value: 5, unit: .fluidOunces)
            case .fortifiedWine:
                return .init(value: 3, unit: .fluidOunces)
            case .mead:
                return .init(value: 5, unit: .fluidOunces)
            case .cider:
                return .init(value: 12, unit: .fluidOunces)
            case .sake:
                return .init(value: 1.5, unit: .fluidOunces)
            case .vodka:
                return .init(value: 1.5, unit: .fluidOunces)
            case .gin:
                return .init(value: 1.5, unit: .fluidOunces)
            case .tequilla:
                return .init(value: 1.5, unit: .fluidOunces)
            case .rum:
                return .init(value: 1.5, unit: .fluidOunces)
            case .whisky:
                return .init(value: 1.5, unit: .fluidOunces)
            case .brandy:
                return .init(value: 1.5, unit: .fluidOunces)
            case .liqueur:
                return .init(value: 1.5, unit: .fluidOunces)
                
            case .other:
                fallthrough
            case .placeholder:
                fallthrough
            case .overflow:
                return .init(value: 12, unit: .fluidOunces) //doesn't matter
            }
        }
    }
    
    public var assortedVolumes: [Measurement<UnitVolume>]
    {
        get
        {
            switch self
            {
            case .beer:
                fallthrough
            case .cider:
                return [
                    //.init(value: 1.5, unit: .fluidOunces),
                    .init(value: 250, unit: .milliliters),
                    //.init(value: 350, unit: .milliliters),
                    .init(value: 12, unit: .fluidOunces),
                    //.init(value: 375, unit: .milliliters),
                    .init(value: 16, unit: .fluidOunces),
                    //.init(value: 500, unit: .milliliters),
                    .init(value: 20, unit: .fluidOunces),
                    .init(value: 32, unit: .fluidOunces)
                ]
            case .mead:
                return [
                    .init(value: 5, unit: .fluidOunces),
                    .init(value: 250, unit: .milliliters)
                ]
            
            case .fortifiedWine:
                fallthrough
            case .wine:
                return [
                    //.init(value: 2, unit: .fluidOunces),
                    .init(value: 3, unit: .fluidOunces),
                    .init(value: 5, unit: .fluidOunces),
                    .init(value: 6, unit: .fluidOunces)
                ]
                
            case .sake:
                return [
                    .init(value: 1.5, unit: .fluidOunces),
                    .init(value: 5, unit: .fluidOunces),
                ]
            
            default:
                return [self.defaultVolume]
            }
        }
    }
}

extension DrinkStyle: CustomStringConvertible
{
    public var description: String
    {
        switch self
        {
        case .beer:
            return self.rawValue
        case .wine:
            return self.rawValue
        case .fortifiedWine:
            return "fortified wine"
        case .mead:
            return self.rawValue
        case .cider:
            return self.rawValue
        case .sake:
            return self.rawValue
        case .vodka:
            return self.rawValue
        case .gin:
            return self.rawValue
        case .tequilla:
            return self.rawValue
        case .rum:
            return self.rawValue
        case .whisky:
            return self.rawValue
        case .brandy:
            return self.rawValue
        case .liqueur:
            return self.rawValue
        case .other:
            return self.rawValue
        case .placeholder:
            return self.rawValue
        case .overflow:
            return self.rawValue
        }
    }
}

public extension Model
{
    // TODO: maybe this does not belong here
    // TODO: this is a giant mess
    public static func assetNameForDrink(_ drink: Model.Drink) -> String
    {
        let epsilon = Measurement<UnitVolume>.init(value: 0.25, unit: .fluidOunces)
        
        if drink.style == .beer || drink.style == .cider || drink.style == .mead
        {
            if drink.volume <= Measurement<UnitVolume>.init(value: 4, unit: .fluidOunces)
            {
                return "lowball"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 8, unit: .fluidOunces), delta: .init(value: 2, unit: .fluidOunces))
            {
                return "snifter"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 12, unit: .fluidOunces), delta: .init(value: 1, unit: .fluidOunces))
            {
                return "tulip"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 500, unit: .milliliters), delta: .init(value: 10, unit: .milliliters))
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
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 1000, unit: .milliliters), delta: .init(value: 5, unit: .fluidOunces))
            {
                return "beer_mug"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 2000, unit: .milliliters), delta: .init(value: 10, unit: .fluidOunces))
            {
                return "beer_boot"
            }
            else
            {
                return "pint_shaker"
            }
        }
        else if drink.style == .wine || drink.style == .fortifiedWine
        {
            if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 3, unit: .fluidOunces), delta: epsilon)
            {
                return "flute_glass"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 5, unit: .fluidOunces), delta: epsilon)
            {
                return "wine_glass_small"
            }
            else if drink.volume >= Measurement<UnitVolume>.init(value: 5.5, unit: .fluidOunces)
            {
                return "wine_glass_big"
            }
            else
            {
                return "wine_glass_big"
            }
        }
        else if drink.style == .sake || drink.style.distilled
        {
            if drink.volume <= Measurement<UnitVolume>.init(value: 2, unit: .fluidOunces)
            {
                return "shot_glass"
            }
            else if equalish(first: drink.volume, second: Measurement<UnitVolume>.init(value: 5, unit: .fluidOunces), delta: .init(value: 1, unit: .fluidOunces))
            {
                return "highball"
            }
            else
            {
                return "shot_glass"
            }
        }
        else
        {
            if drink.volume <= Measurement<UnitVolume>.init(value: 2, unit: .fluidOunces)
            {
                return "shot_glass"
            }
            else if equalish(first: drink.volume, second: .init(value: 5, unit: .fluidOunces), delta: .init(value: 1, unit: .fluidOunces))
            {
                return "wine_glass_big"
            }
            else if equalish(first: drink.volume, second: .init(value: 16, unit: .fluidOunces), delta: .init(value: 2, unit: .fluidOunces))
            {
                return "pint_shaker"
            }
            else if equalish(first: drink.volume, second: .init(value: 1000, unit: .milliliters), delta: .init(value: 8, unit: .fluidOunces))
            {
                return "beer_mug"
            }
            else
            {
                return "highball"
            }
        }
    }
}
