//
//  Formatting.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-31.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import DataLayer

public struct Format
{
    public static func format(abv: Double) -> String
    {
        return String.init(format: "%.1f%%", abv * 100)
    }
    
    public static func format(volume: Measurement<UnitVolume>) -> String
    {
        let numberFormatter = NumberFormatter.init()
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.minimumIntegerDigits = 1
        
        let measurementFormatter = MeasurementFormatter.init()
        measurementFormatter.unitStyle = .medium
        measurementFormatter.unitOptions = .providedUnit
        measurementFormatter.numberFormatter = numberFormatter
        
        return measurementFormatter.string(from: volume)
    }
    
    public static func format(unit: UnitVolume) -> String
    {
        let measurementFormatter = MeasurementFormatter.init()
        measurementFormatter.unitStyle = .long
        
        return measurementFormatter.string(from: unit)
    }
    
    // TODO: currency
    public static func format(price: Double) -> String
    {
        return String.init(format: (price.truncatingRemainder(dividingBy: 1) == 0 ? "$%.0f" : "$%.2f"), price)
    }
    
    public static func format(style: DrinkStyle) -> String
    {
        return style.description
    }
}
