//
//  ModelData.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-15.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public struct DataModel: Hashable, Equatable, LamportQueriable, Mergeable
{
    public typealias ID = UInt64
    
    public struct Metadata: Hashable, Equatable, LamportQueriable, Mergeable
    {
        // AB: these already contain an implicit lamport value, and can only be created when the other lamport values
        // are initialized, so it's unnecessary to add a LamportValue wrapper here.
        public let id: GlobalID
        public let creationTime: Double
        
        public var deleted: LamportValue<Bool>
        
        public init(id: GlobalID, creationTime: Double, deleted: LamportValue<Bool>)
        {
            self.id = id
            self.creationTime = creationTime
            self.deleted = deleted
        }
        
        public var lamport: DataLayer.Time
        {
            return deleted.lamport
        }
        
        mutating public func merge(with: DataModel.Metadata)
        {
            // AB: deletes are exempt from regular LWW rules, since a delete cannot be overriden.
            self.deleted = LamportValue.init(v: self.deleted.v || with.deleted.v, t: max(self.deleted.t, with.deleted.t))
        }
    }
    
    public struct CheckIn: Hashable, Equatable, LamportQueriable, Mergeable
    {
        public var untappdId: LamportValue<ID?>
        public var time: LamportValue<Double>
        public var drink: Drink
        
        public init(untappdId: LamportValue<ID?>, time: LamportValue<Double>, drink: Drink)
        {
            self.untappdId = untappdId
            self.time = time
            self.drink = drink
        }
        
        public var lamport: DataLayer.Time
        {
            return max(untappdId.lamport, time.lamport, drink.lamport)
        }
        
        mutating public func merge(with: DataModel.CheckIn)
        {
            self.untappdId.merge(with: with.untappdId)
            self.time.merge(with: with.time)
            self.drink.merge(with: with.drink)
        }
    }
    
    public struct Drink: Hashable, Equatable, LamportQueriable, Mergeable
    {
        public var name: LamportValue<String?>
        public var style: LamportValue<DrinkStyle>
        public var abv: LamportValue<Double>
        public var price: LamportValue<Double?>
        public var volume: LamportValue<Measurement<UnitVolume>>
        
        public init(name: LamportValue<String?>, style: LamportValue<DrinkStyle>, abv: LamportValue<Double>, price: LamportValue<Double?>, volume: LamportValue<Measurement<UnitVolume>>)
        {
            self.name = name
            self.style = style
            self.abv = abv
            self.price = price
            self.volume = volume
        }
        
        public var lamport: DataLayer.Time
        {
            return max(name.lamport, style.lamport, abv.lamport, price.lamport, volume.lamport)
        }
        
        mutating public func merge(with: DataModel.Drink)
        {
            self.name.merge(with: with.name)
            self.style.merge(with: with.style)
            self.abv.merge(with: with.abv)
            self.price.merge(with: with.price)
            self.volume.merge(with: with.volume)
        }
    }
    
    public var metadata: Metadata
    public var checkIn: CheckIn
    
    public init(metadata: Metadata, checkIn: CheckIn)
    {
        self.metadata = metadata
        self.checkIn = checkIn
    }
    
    public var lamport: DataLayer.Time
    {
        return max(metadata.lamport, checkIn.lamport)
    }
    
    mutating public func merge(with: DataModel)
    {
        self.metadata.merge(with: with.metadata)
        self.checkIn.merge(with: with.checkIn)
    }
}

public struct DataModelLogEntry
{
    let site: DataLayer.SiteID
    let index: DataLayer.Index
    let operation: GlobalID
}

extension DataModel: CustomStringConvertible, CustomDebugStringConvertible
{
    public var description: String
    {
        return "\(metadata.id): \(Format.format(volume: checkIn.drink.volume.v)) \(Format.format(abv: checkIn.drink.abv.v)) \(checkIn.drink.name.v == nil || checkIn.drink.name.v == "" ? "" : "\"\(checkIn.drink.name.v!)\" ")\(Format.format(style: checkIn.drink.style.v)) for \(Format.format(price: checkIn.drink.price.v ?? 0))"
    }
    
    public var debugDescription: String
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd H:m:ss.SSSS"
        
        return "\(metadata.id): \(Format.format(volume: checkIn.drink.volume.v))(\(checkIn.drink.volume.t)) \(Format.format(abv: checkIn.drink.abv.v))(\(checkIn.drink.abv.t)) \"\(checkIn.drink.name.v ?? "")\"(\(checkIn.drink.name.t)) \(Format.format(style: checkIn.drink.style.v))(\(checkIn.drink.style.t)) for \(Format.format(price: checkIn.drink.price.v ?? 0))(\(checkIn.drink.price.t)) on \(formatter.string(from: Date.init(timeIntervalSince1970: checkIn.time.v)))(\(checkIn.time.t))"
    }
}

