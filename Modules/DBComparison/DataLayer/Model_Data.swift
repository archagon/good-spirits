//
//  ModelData.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-15.
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

public struct DataModel: Hashable, Equatable, Encodable, LamportQueriable, Mergeable
{
    public typealias ID = UInt64
    
    public struct Metadata: Hashable, Equatable, Encodable, LamportQueriable, Mergeable
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
            // AB: Deletes are exempt from regular LWW rules, since a delete cannot be overriden.
            self.deleted = LamportValue.init(v: self.deleted.v || with.deleted.v, t: max(self.deleted.t, with.deleted.t))
        }
    }
    
    public struct CheckIn: Hashable, Equatable, Encodable, LamportQueriable, Mergeable
    {
        public var untappdId: LamportValue<ID?>
        public var untappdApproved: LamportValue<Bool>
        public var time: LamportValue<Double>
        public var drink: Drink
        
        public init(untappdId: LamportValue<ID?>, untappdApproved: LamportValue<Bool>, time: LamportValue<Double>, drink: Drink)
        {
            self.untappdId = untappdId
            self.untappdApproved = untappdApproved
            self.time = time
            self.drink = drink
        }
        
        public var lamport: DataLayer.Time
        {
            return max(untappdId.lamport, untappdApproved.lamport, time.lamport, drink.lamport)
        }
        
        mutating public func merge(with: DataModel.CheckIn)
        {
            self.untappdId.merge(with: with.untappdId)
            self.time.merge(with: with.time)
            self.drink.merge(with: with.drink)
            
            // AB: Untappd approvals are exempt from regular LWW rules, since an approval cannot be overriden.
            self.untappdApproved = LamportValue.init(v: self.untappdApproved.v || with.untappdApproved.v, t: max(self.untappdApproved.t, with.untappdApproved.t))
        }
    }
    
    public struct Drink: Hashable, Equatable, Encodable, LamportQueriable, Mergeable
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
        assert(self.metadata.id == with.metadata.id)
        
        // AB: Untappd approval is a special merge case. These checkins are saved to the database on receipt, and we
        // don't want a device that receives an Untappd checkin to overwrite an already approved checkin on another
        // device with the default data, just because the Lamport timestamp is higher. Ergo, the approved flag trumps all.
        // TODO: This is a quick and dirty solution. Ideally, we need to update the Lamport timestamps as well. This
        // only works because we're updating models atomically, not streaming individual LWW changes.
        if self.checkIn.untappdApproved.v && !with.checkIn.untappdApproved.v
        {
            return
        }
        else if !self.checkIn.untappdApproved.v && with.checkIn.untappdApproved.v
        {
            self.metadata = with.metadata
            self.checkIn = with.checkIn
        }
        else
        {
            self.metadata.merge(with: with.metadata)
            self.checkIn.merge(with: with.checkIn)
        }
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
        let untappdString: String
        if let untappd = checkIn.untappdId.v
        {
            untappdString = " (Untappd \(untappd)\(checkIn.untappdApproved.v ? " ✓" : "")"
        }
        else
        {
            untappdString = ""
        }
        
        return "\(metadata.id)\(untappdString): \(Format.format(volume: checkIn.drink.volume.v)) \(Format.format(abv: checkIn.drink.abv.v)) \(checkIn.drink.name.v == nil || checkIn.drink.name.v == "" ? "" : "\"\(checkIn.drink.name.v!)\" ")\(Format.format(style: checkIn.drink.style.v)) for \(Format.format(price: checkIn.drink.price.v ?? 0))"
    }
    
    public var debugDescription: String
    {
        let untappdString: String
        if let untappd = checkIn.untappdId.v
        {
            untappdString = " (Untappd \(untappd)(\(checkIn.untappdId.t))\(checkIn.untappdApproved.v ? " ✓" : "")"
        }
        else
        {
            untappdString = ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "y-MM-dd H:m:ss.SSSS"
        
        return "\(metadata.id)\(untappdString): \(Format.format(volume: checkIn.drink.volume.v))(\(checkIn.drink.volume.t)) \(Format.format(abv: checkIn.drink.abv.v))(\(checkIn.drink.abv.t)) \"\(checkIn.drink.name.v ?? "")\"(\(checkIn.drink.name.t)) \(Format.format(style: checkIn.drink.style.v))(\(checkIn.drink.style.t)) for \(Format.format(price: checkIn.drink.price.v ?? 0))(\(checkIn.drink.price.t)) on \(formatter.string(from: Date.init(timeIntervalSince1970: checkIn.time.v)))(\(checkIn.time.t))"
    }
}

