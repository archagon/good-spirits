//
//  Data_Debug.swift
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

// Unsafe, mostly for debugging purposes. Likely to be very slow.
extension DataAccessProtocol
{
    public func _lamportTimestamp() -> DataLayer.Time
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: DataLayer.Time! = nil
        
        self.readTransaction
        {
            returnValue = $0._lamportTimestamp()
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _vectorTimestamp() -> VectorClock
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: VectorClock! = nil
        
        self.readTransaction
        {
            returnValue = $0._vectorTimestamp()
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _operationLog(forSite site: DataLayer.SiteID) -> [GlobalID]
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: [GlobalID]! = nil
        
        self.readTransaction
        {
            returnValue = $0._operationLog(forSite: site)
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _nextOperationIndex(forSite site: DataLayer.SiteID) -> DataLayer.Index
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: DataLayer.Index! = nil
        
        self.readTransaction
        {
            returnValue = $0._nextOperationIndex(forSite: site)
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _data(forID id: GlobalID) -> DataModel?
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: DataModel?! = nil
        
        self.readTransaction
        {
            returnValue = $0._data(forID: id)
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _data(afterTimestamp timestamp: VectorClock) -> Set<DataModel>
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: Set<DataModel>! = nil
        
        self.readTransaction
        {
            returnValue = $0._data(afterTimestamp: timestamp)
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _data(fromIncludingDate from: Date, toExcludingDate to: Date) -> [DataModel]
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: [DataModel]! = nil
        
        self.readTransaction
        {
            returnValue = $0._data(fromIncludingDate: from, toExcludingDate: to)
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _allData() -> Set<DataModel>
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: Set<DataModel>! = nil
        
        self.readTransaction
        {
            returnValue = $0._data(afterTimestamp: VectorClock.init(map: [:]))
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _allOperations() -> [(DataLayer.SiteID, Int, GlobalID)]
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: [(DataLayer.SiteID, Int, GlobalID)]! = nil
        
        self.readTransaction
        {
            returnValue = $0._allOperations()
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _print()
    {
        let group = DispatchGroup()
        group.enter()
        
        self.readTransaction
        {
            $0._print()
            group.leave()
        }
        
        group.wait()
    }
}

extension DataProtocol
{
    public func _lamportTimestamp() -> DataLayer.Time
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: DataLayer.Time! = nil
        
        self.lamportTimestamp
        { time in
            switch time
            {
            case .error(let e):
                assert(false, e.localizedDescription)
            case .value(let v):
                returnValue = v
            }
            
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _vectorTimestamp() -> VectorClock
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: VectorClock! = nil
        
        self.vectorTimestamp
        { time in
            switch time
            {
            case .error(let e):
                assert(false, e.localizedDescription)
            case .value(let v):
                returnValue = v
            }
            
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _operationLog(forSite site: DataLayer.SiteID) -> [GlobalID]
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: [GlobalID]! = nil
        
        self.operationLog(forSite: site)
        { time in
            switch time
            {
            case .error(let e):
                assert(false, e.localizedDescription)
            case .value(let v):
                returnValue = v
            }
            
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _nextOperationIndex(forSite site: DataLayer.SiteID) -> DataLayer.Index
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: DataLayer.Index! = nil
        
        self.nextOperationIndex(forSite: site)
        { time in
            switch time
            {
            case .error(let e):
                assert(false, e.localizedDescription)
            case .value(let v):
                returnValue = v
            }
            
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _data(forID id: GlobalID) -> DataModel?
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: DataModel?! = nil
        
        self.data(forID: id)
        { time in
            switch time
            {
            case .error(let e):
                assert(false, e.localizedDescription)
            case .value(let v):
                returnValue = v
            }
            
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _data(afterTimestamp timestamp: VectorClock) -> Set<DataModel>
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: Set<DataModel>! = nil
        
        self.data(afterTimestamp: timestamp)
        { time in
            switch time
            {
            case .error(let e):
                assert(false, e.localizedDescription)
            case .value(let v):
                returnValue = v
            }
            
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _data(fromIncludingDate from: Date, toExcludingDate to: Date) -> [DataModel]
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: [DataModel]! = nil
        
        self.data(fromIncludingDate: from, toExcludingDate: to)
        { time in
            switch time
            {
            case .error(let e):
                assert(false, e.localizedDescription)
            case .value(let v):
                returnValue = v
            }
            
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _allData() -> Set<DataModel>
    {
        let group = DispatchGroup()
        group.enter()
        
        var returnValue: Set<DataModel>! = nil
        
        self.data(afterTimestamp: VectorClock.init(map: [:]))
        { time in
            switch time
            {
            case .error(let e):
                assert(false, e.localizedDescription)
            case .value(let v):
                returnValue = v
            }
            
            group.leave()
        }
        
        group.wait()
        
        return returnValue
    }
    
    public func _allOperations() -> [(DataLayer.SiteID, Int, GlobalID)]
    {
        var retVal: [(DataLayer.SiteID, Int, GlobalID)] = []
        
        let vector = _vectorTimestamp()
        for (site, _) in vector.map
        {
            let log = _operationLog(forSite: site)
            retVal += log.enumerated().map { return (site, $0.offset, $0.element) }
        }
        
        return retVal
    }
    
    public func _print()
    {
        print("💙 All Data 💙")
        _data(fromIncludingDate: Date.distantPast, toExcludingDate: Date.distantFuture).forEach
        {
            print($0.debugDescription)
        }
        print("\n")
        
        print("💙 All Operations 💙")
        let operations = _allOperations()
        for op in operations
        {
            print("\(op.0.hashValue) \(op.1): \(op.2)")
        }
        print("\n")
    }
}
