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
}

public struct Model: Hashable, Equatable
{
    public typealias ID = UInt64
    
    public struct Metadata: Hashable, Equatable
    {
        public let id: GlobalID
        public let creationTime: Date
        public let deleted: Bool
        
        public init(id: GlobalID, creationTime: Date, deleted: Bool = false)
        {
            self.id = id
            
            // BUGFIX: if we don't do this, two dates with the same value can end up unequal, somehow
            self.creationTime = Date.init(timeIntervalSince1970: creationTime.timeIntervalSince1970)
            
            self.deleted = deleted
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
    
    public var id: GlobalID?
    {
        if metadata.id.operationIndex == DataLayer.wildcardIndex
        {
            return nil
        }
        else
        {
            return metadata.id
        }
    }
    
    // This is mostly here for easier merging, etc. If you find yourself with a deleted model object, get rid of it!
    public var deleted: Bool
    {
        return self.metadata.deleted
    }
    
    public var metadata: Metadata
    public var checkIn: CheckIn
    
    public init(metadata: Metadata, checkIn: CheckIn)
    {
        self.metadata = metadata
        self.checkIn = checkIn
    }
    
    public mutating func delete()
    {
        self.metadata = Metadata.init(id: self.metadata.id, creationTime: self.metadata.creationTime, deleted: true)
    }
}

extension Model: CustomStringConvertible
{
    public var description: String
    {
        return "\(metadata.id): \(Format.format(volume: checkIn.drink.volume)) \(Format.format(abv: checkIn.drink.abv)) \(checkIn.drink.name == nil || checkIn.drink.name == "" ? "" : "\"\(checkIn.drink.name!)\" ")\(Format.format(style: checkIn.drink.style)) for \(Format.format(price: checkIn.drink.price ?? 0))"
    }
}
