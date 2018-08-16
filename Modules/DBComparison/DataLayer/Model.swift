//
//  Model.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-5.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public enum DrinkStyle: String, RawRepresentable
{
    case beer
    case wine
    case sake
    
    public static var defaultStyle: DrinkStyle
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

public struct Model: Hashable, Equatable
{
    public typealias ID = UInt64
    
    public struct Metadata: Hashable, Equatable
    {
        public let id: GlobalID
        public let creationTime: Date
        
        public init(id: GlobalID, creationTime: Date)
        {
            self.id = id
            
            // BUGFIX: if we don't do this, two dates with the same value can end up unequal, somehow
            self.creationTime = Date.init(timeIntervalSince1970: creationTime.timeIntervalSince1970)
        }
    }
    
    public struct CheckIn: Hashable, Equatable
    {
        public var untappdId: ID?
        public var time: Date
        public var drink: Drink
        
        public init(untappdId: ID?, time: Date, drink: Drink)
        {
            self.untappdId = untappdId
            self.time = Date.init(timeIntervalSince1970: time.timeIntervalSince1970)
            self.drink = drink
        }
    }
    
    public struct Drink: Hashable, Equatable
    {
        public var name: String?
        public var style: DrinkStyle
        public var abv: Double
        public var price: Double?
        public var volume: Measurement<UnitVolume>
        
        public init(name: String?, style: DrinkStyle, abv: Double, price: Double?, volume: Measurement<UnitVolume>)
        {
            self.name = name
            self.style = style
            self.abv = abv
            self.price = price
            self.volume = volume
        }
    }
    
    public let metadata: Metadata
    public var checkIn: CheckIn
    
    public init(metadata: Metadata, checkIn: CheckIn)
    {
        self.metadata = metadata
        self.checkIn = checkIn
    }
}

extension Model: CustomStringConvertible
{
    public var description: String
    {
        return "\(metadata.id): \(Format.format(volume: checkIn.drink.volume)) \(Format.format(abv: checkIn.drink.abv)) \(checkIn.drink.name == nil || checkIn.drink.name == "" ? "" : "\"\(checkIn.drink.name!)\" ")\(Format.format(style: checkIn.drink.style)) for \(Format.format(price: checkIn.drink.price ?? 0))"
    }
}
