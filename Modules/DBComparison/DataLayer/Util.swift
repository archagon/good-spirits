//
//  Util.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-7.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import QuartzCore

func onMain(_ block: @escaping ()->Void)
{
    if !Thread.current.isMainThread
    {
        DispatchQueue.main.async(execute: block)
    }
    else
    {
        block()
    }
}

func synced(_ block: @escaping (_ done: @escaping ()->Void)->Void)
{
    let gate = DispatchGroup()
    let doneBlock = { gate.leave() }
    gate.enter()
    block(doneBlock)
    gate.wait()
}

// http://mpclarkson.github.io/2015/11/30/swift-dictionary-keys-snake-case-to-camel-case/
extension String
{
    var underscoreToCamelCase: String
    {
        let items = self.components(separatedBy: "_")
        var camelCase = ""
        items.enumerated().forEach
        { pair in
            camelCase += (0 == pair.0 ? pair.1 : pair.1.capitalized)
        }
        return camelCase
    }
    
    var capitalizedFirstLetter: String
    {
        return prefix(1).uppercased() + dropFirst()
    }
}

// BUGFIX: kludge for "Cannot convert measurements of differing unit types! self: NSUnitVolume unit: NSUnitAcceleration"
extension UnitVolume
{
    static func unit(withSymbol symbol: String) -> UnitVolume
    {
        if symbol == UnitVolume.megaliters.symbol
        {
            return UnitVolume.megaliters
        }
        else if symbol == UnitVolume.kiloliters.symbol
        {
            return UnitVolume.kiloliters
        }
        else if symbol == UnitVolume.liters.symbol
        {
            return UnitVolume.liters
        }
        else if symbol == UnitVolume.deciliters.symbol
        {
            return UnitVolume.deciliters
        }
        else if symbol == UnitVolume.centiliters.symbol
        {
            return UnitVolume.centiliters
        }
        else if symbol == UnitVolume.milliliters.symbol
        {
            return UnitVolume.milliliters
        }
        else if symbol == UnitVolume.cubicKilometers.symbol
        {
            return UnitVolume.cubicKilometers
        }
        else if symbol == UnitVolume.cubicMeters.symbol
        {
            return UnitVolume.cubicMeters
        }
        else if symbol == UnitVolume.cubicDecimeters.symbol
        {
            return UnitVolume.cubicDecimeters
        }
        else if symbol == UnitVolume.cubicCentimeters.symbol
        {
            return UnitVolume.cubicCentimeters
        }
        else if symbol == UnitVolume.cubicMillimeters.symbol
        {
            return UnitVolume.cubicMillimeters
        }
        else if symbol == UnitVolume.cubicInches.symbol
        {
            return UnitVolume.cubicInches
        }
        else if symbol == UnitVolume.cubicFeet.symbol
        {
            return UnitVolume.cubicFeet
        }
        else if symbol == UnitVolume.cubicYards.symbol
        {
            return UnitVolume.cubicYards
        }
        else if symbol == UnitVolume.cubicMiles.symbol
        {
            return UnitVolume.cubicMiles
        }
        else if symbol == UnitVolume.acreFeet.symbol
        {
            return UnitVolume.acreFeet
        }
        else if symbol == UnitVolume.bushels.symbol
        {
            return UnitVolume.bushels
        }
        else if symbol == UnitVolume.teaspoons.symbol
        {
            return UnitVolume.teaspoons
        }
        else if symbol == UnitVolume.tablespoons.symbol
        {
            return UnitVolume.tablespoons
        }
        else if symbol == UnitVolume.fluidOunces.symbol
        {
            return UnitVolume.fluidOunces
        }
        else if symbol == UnitVolume.cups.symbol
        {
            return UnitVolume.cups
        }
        else if symbol == UnitVolume.pints.symbol
        {
            return UnitVolume.pints
        }
        else if symbol == UnitVolume.quarts.symbol
        {
            return UnitVolume.quarts
        }
        else if symbol == UnitVolume.gallons.symbol
        {
            return UnitVolume.gallons
        }
        else if symbol == UnitVolume.imperialTeaspoons.symbol
        {
            return UnitVolume.imperialTeaspoons
        }
        else if symbol == UnitVolume.imperialTablespoons.symbol
        {
            return UnitVolume.imperialTablespoons
        }
        else if symbol == UnitVolume.imperialFluidOunces.symbol
        {
            return UnitVolume.imperialFluidOunces
        }
        else if symbol == UnitVolume.imperialPints.symbol
        {
            return UnitVolume.imperialPints
        }
        else if symbol == UnitVolume.imperialQuarts.symbol
        {
            return UnitVolume.imperialQuarts
        }
        else if symbol == UnitVolume.imperialGallons.symbol
        {
            return UnitVolume.imperialGallons
        }
        else if symbol == UnitVolume.metricCups.symbol
        {
            return UnitVolume.metricCups
        }
        else
        {
            fatalError("invalid unit")
        }
    }
}
