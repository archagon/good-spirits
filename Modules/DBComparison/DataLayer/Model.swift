//
//  Model.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-5.
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

public enum DrinkStyle: String, RawRepresentable, Encodable
{
    case beer
    case wine
    case fortifiedWine
    case mead
    case cider
    case sake
    case vodka
    case gin
    case tequilla
    case rum
    case whisky
    case brandy
    case liqueur
    case cocktail
    case other
    case placeholder
    case overflow
    
    public var fermented: Bool
    {
        switch self
        {
        case .beer:
            fallthrough
        case .wine:
            fallthrough
        case .fortifiedWine:
            fallthrough
        case .mead:
            fallthrough
        case .cider:
            fallthrough
        case .sake:
            return true
            
        case .vodka:
            fallthrough
        case .gin:
            fallthrough
        case .tequilla:
            fallthrough
        case .rum:
            fallthrough
        case .whisky:
            fallthrough
        case .brandy:
            fallthrough
        case .liqueur:
            fallthrough
        case .cocktail:
            return false
            
        case .other:
            fallthrough
        case .placeholder:
            fallthrough
        case .overflow:
            return false
        }
    }
    
    public var distilled: Bool
    {
        switch self
        {
        case .beer:
            fallthrough
        case .wine:
            fallthrough
        case .fortifiedWine:
            fallthrough
        case .mead:
            fallthrough
        case .cider:
            fallthrough
        case .sake:
            return false
            
        case .vodka:
            fallthrough
        case .gin:
            fallthrough
        case .tequilla:
            fallthrough
        case .rum:
            fallthrough
        case .whisky:
            fallthrough
        case .brandy:
            fallthrough
        case .liqueur:
            fallthrough
        case .cocktail:
            return true
            
        case .other:
            fallthrough
        case .placeholder:
            fallthrough
        case .overflow:
            return false
        }
    }
    
    public var displayable: Bool
    {
        switch self
        {
        case .beer:
            fallthrough
        case .wine:
            fallthrough
        case .fortifiedWine:
            fallthrough
        case .mead:
            fallthrough
        case .cider:
            fallthrough
        case .sake:
            fallthrough
        case .vodka:
            fallthrough
        case .gin:
            fallthrough
        case .tequilla:
            fallthrough
        case .rum:
            fallthrough
        case .whisky:
            fallthrough
        case .brandy:
            fallthrough
        case .liqueur:
            fallthrough
        case .cocktail:
            fallthrough
        case .other:
            return true
            
        case .placeholder:
            fallthrough
        case .overflow:
            return false
        }
    }
    
    public static var allStyles: [DrinkStyle]
    {
        var styles: [DrinkStyle] = []
        
        switch DrinkStyle.beer
        {
        case .beer:
            styles.append(.beer)
            fallthrough
        case .wine:
            styles.append(.wine)
            fallthrough
        case .fortifiedWine:
            styles.append(.fortifiedWine)
            fallthrough
        case .mead:
            styles.append(.mead)
            fallthrough
        case .cider:
            styles.append(.cider)
            fallthrough
        case .sake:
            styles.append(.sake)
            fallthrough
        case .vodka:
            styles.append(.vodka)
            fallthrough
        case .gin:
            styles.append(.gin)
            fallthrough
        case .tequilla:
            styles.append(.tequilla)
            fallthrough
        case .rum:
            styles.append(.rum)
            fallthrough
        case .whisky:
            styles.append(.whisky)
            fallthrough
        case .brandy:
            styles.append(.brandy)
            fallthrough
        case .liqueur:
            styles.append(.liqueur)
            fallthrough
        case .cocktail:
            styles.append(.cocktail)
            fallthrough
        case .other:
            styles.append(.other)
            fallthrough
        case .placeholder:
            styles.append(.placeholder)
            fallthrough
        case .overflow:
            styles.append(.overflow)
        }
        
        return styles
    }
    
    public static var displayableStyles: [DrinkStyle]
    {
        return allStyles.filter { $0.displayable }
    }
}

public struct Model: Hashable, Equatable, Encodable
{
    public typealias ID = UInt64
    
    public struct Metadata: Hashable, Equatable, Encodable
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
    
    public struct CheckIn: Hashable, Equatable, Encodable
    {
        public var untappdId: ID?
        public var untappdApproved: Bool
        public var time: Date
        public var drink: Drink
        
        public init(untappdId: ID?, untappdApproved: Bool, time: Date, drink: Drink)
        {
            self.untappdId = untappdId
            self.untappdApproved = untappdApproved
            self.time = Date.init(timeIntervalSince1970: time.timeIntervalSince1970)
            self.drink = drink
        }
    }
    
    public struct Drink: Hashable, Equatable, Encodable
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
    
    public mutating func approve()
    {
        if self.checkIn.untappdId != nil
        {
            self.checkIn.untappdApproved = true
        }
    }
}

extension Model: CustomStringConvertible
{
    public var description: String
    {
        return "\(metadata.id): \(Format.format(volume: checkIn.drink.volume)) \(Format.format(abv: checkIn.drink.abv)) \(checkIn.drink.name == nil || checkIn.drink.name == "" ? "" : "\"\(checkIn.drink.name!)\" ")\(Format.format(style: checkIn.drink.style)) for \(Format.format(price: checkIn.drink.price ?? 0))"
    }
}
