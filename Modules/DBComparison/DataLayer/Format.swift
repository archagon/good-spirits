//
//  Formatting.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-31.
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

// Clone of app class for logging purposes.
struct Format
{
    static func format(abv: Double) -> String
    {
        return String.init(format: "%.1f%%", abv * 100)
    }
    
    static func format(volume: Measurement<UnitVolume>) -> String
    {
        let numberFormatter = NumberFormatter.init()
        numberFormatter.maximumFractionDigits = 1
        numberFormatter.minimumIntegerDigits = 1
        
        let measurementFormatter = MeasurementFormatter.init()
        measurementFormatter.unitStyle = .short
        measurementFormatter.unitOptions = .providedUnit
        measurementFormatter.numberFormatter = numberFormatter
        
        return measurementFormatter.string(from: volume)
    }
    
    static func format(unit: UnitVolume) -> String
    {
        let measurementFormatter = MeasurementFormatter.init()
        measurementFormatter.unitStyle = .long
        
        return measurementFormatter.string(from: unit)
    }
    
    static func format(price: Double) -> String
    {
        return String.init(format: (price.truncatingRemainder(dividingBy: 1) == 0 ? "$%.0f" : "$%.2f"), price)
    }
    
    static func format(style: DrinkStyle) -> String
    {
        return style.rawValue
    }
}
