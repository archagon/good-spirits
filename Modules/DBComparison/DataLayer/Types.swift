//
//  Types.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-6.
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

public struct VectorClock: Equatable, Codable, CustomStringConvertible
{
    public let map: [DataLayer.SiteID:DataLayer.Time]
    
    public init(map: [DataLayer.SiteID:DataLayer.Time])
    {
        self.map = map
    }
    
    public func time(forSite site: DataLayer.SiteID) -> DataLayer.Time?
    {
        return map[site]
    }
    
    public var description: String
    {
        var out = "["
        
        for (i, pair) in map.enumerated()
        {
            out += "\(pair.key.hashValue):\(pair.value)\(i == map.count - 1 ? "" : ", ")"
        }
        
        out += "]"
        
        return out
    }
    
    // TODO: check this logic
    public func includes(_ clock: VectorClock) -> Bool
    {
        for (site, timestamp) in clock.map
        {
            if let localTimestamp = map[site]
            {
                if timestamp > localTimestamp
                {
                    return false
                }
            }
            else
            {
                return false
            }
        }
        
        return true
    }
}

public struct GlobalID: Hashable, Comparable, Encodable, CustomStringConvertible
{
    public let siteID: DataLayer.SiteID
    public let operationIndex: DataLayer.Index
    
    public init(siteID: DataLayer.SiteID, operationIndex: DataLayer.Index)
    {
        self.siteID = siteID
        self.operationIndex = operationIndex
    }
    
    public static var zero: GlobalID
    {
        let uuid: uuid_t = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
        return .init(siteID: UUID.init(uuid: uuid), operationIndex: 0)
    }
    
    public static func < (lhs: GlobalID, rhs: GlobalID) -> Bool
    {
        if lhs.siteID == rhs.siteID
        {
            return lhs.operationIndex < rhs.operationIndex
        }
        else
        {
            return lhs.siteID < rhs.siteID
        }
    }
    
    public var description: String
    {
        return "\(siteID.hashValue):\(operationIndex)"
    }
}

public enum MaybeError<T>
{
    case value(v: T)
    case error(e: Error)
}

public struct LamportValue<T: Hashable & Encodable>: Hashable, LamportQueriable, Encodable, Mergeable
{
    public var v: T
    public var t: DataLayer.Time
    
    public init(v: T, t: DataLayer.Time)
    {
        self.v = v
        self.t = t
    }
    
    public var lamport: DataLayer.Time
    {
        return self.t
    }
    
    mutating public func merge(with: LamportValue<T>)
    {
        if with.t > self.t
        {
            self.v = with.v
            self.t = with.t
        }
    }
}

// NEXT: remove in Swift 4.2
extension Optional: Hashable where Wrapped: Hashable
{
    public var hashValue: Int
    {
        switch self
        {
        case .none: return 0.hashValue
        case .some(let object): return object.hashValue
        }
    }
}

public protocol LamportQueriable
{
    var lamport: DataLayer.Time { get }
}

public protocol Mergeable
{
    mutating func merge(with: Self)
}

extension UUID: Comparable
{
    public static func < (lhs: UUID, rhs: UUID) -> Bool
    {
        return lhs.uuidString < rhs.uuidString
    }
}
