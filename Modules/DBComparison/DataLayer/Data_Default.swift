//
//  Data_Default.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-8.
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

public protocol DataAccessEasySyncProtocol
{
    func syncInSequence(data: Set<DataModel>, withOperationLog operationLog: DataLayer.OperationLog, completionBlock block: @escaping (Error?)->Void)
}

public protocol DataAccessEasySyncProtocolImmediate
{
    func syncInSequence(data: Set<DataModel>, withOperationLog operationLog: DataLayer.OperationLog) throws
}

extension DataWriteProtocol where Self: DataAccessEasySyncProtocol
{
    // TODO: if it's assumed that the lamport timestamps are correct, then why not assume the wildcard is taken care of, too?
    public func commit(data: DataModel, withSite site: DataLayer.SiteID, completionBlock block: @escaping (MaybeError<GlobalID>)->())
    {
        // new operation
        if data.metadata.id.operationIndex == DataLayer.wildcardIndex
        {
            self.nextOperationIndex(forSite: site)
            {
                switch $0
                {
                case .error(let e):
                    block(.error(e: e))
                case .value(let idx):
                    let id = GlobalID.init(siteID: data.metadata.id.siteID, operationIndex: idx)
                    let metadata = DataModel.Metadata.init(id: id, creationTime: data.metadata.creationTime, deleted: data.metadata.deleted)
                    let newData = DataModel.init(metadata: metadata, checkIn: data.checkIn)
                    
                    let opLog = [site : (idx, [newData.metadata.id])]
                    let wrapBlock: (Error?)->Void = { $0 == nil ? block(.value(v: newData.metadata.id)) : block(.error(e: $0!)) }
                    self.syncInSequence(data: Set([newData]), withOperationLog: opLog, completionBlock: wrapBlock)
                }
            }
        }
        // change
        else
        {
            nextOperationIndex(forSite: site)
            {
                switch $0
                {
                case .error(let e):
                    block(.error(e: e))
                case .value(let idx):
                    self.data(forID: data.metadata.id)
                    {
                        switch $0
                        {
                        case .error(let e):
                            block(.error(e: e))
                        case .value(let v):
                            if let previousData = v
                            {
                                var newData = previousData
                                newData.merge(with: data)
                                
                                let opLog = [site : (idx, [newData.metadata.id])]
                                let wrapBlock: (Error?)->Void = { $0 == nil ? block(.value(v: newData.metadata.id)) : block(.error(e: $0!)) }
                                self.syncInSequence(data: Set([newData]), withOperationLog: opLog, completionBlock: wrapBlock)
                            }
                            else
                            {
                                block(.error(e: DataError.missingPreceedingOperations))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // PERF: very slow
    public func commit(data: [DataModel], withSite site: DataLayer.SiteID, completionBlock block: @escaping (MaybeError<[GlobalID]>)->())
    {
        if data.count == 0
        {
            block(.value(v: []))
            return
        }
        
        var results: [GlobalID] = []
        var error: Error? = nil
        
        let gate = DispatchGroup()
        
        for datum in data
        {
            if error != nil
            {
                break
            }
            
            gate.enter()
            
            self.commit(data: datum, withSite: site)
            {
                switch $0
                {
                case .error(let e):
                    error = e
                case .value(let v):
                    results.append(v)
                }
                
                gate.leave()
            }
            
            gate.wait()
        }
        
        block(error == nil ? .value(v: results) : .error(e: error!))
    }
    
    public func sync(data: Set<DataModel>, withOperationLog operationLog: DataLayer.OperationLog, completionBlock block: @escaping (Error?)->())
    {
        for datum in data
        {
            if datum.metadata.id.operationIndex == DataLayer.wildcardIndex
            {
                block(DataError.wrongSyncCommitChoice)
                return
            }
        }
        
        syncInSequence(data: data, withOperationLog: operationLog, completionBlock: block)
    }
}

extension DataWriteProtocolImmediate where Self: DataAccessEasySyncProtocolImmediate
{
    // TODO: if it's assumed that the lamport timestamps are correct, then why not assume the wildcard is taken care of, too?
    public func commit(data: DataModel, withSite site: DataLayer.SiteID) throws -> GlobalID
    {
        // new operation
        if data.metadata.id.operationIndex == DataLayer.wildcardIndex
        {
            let idx = try self.nextOperationIndex(forSite: site)
            
            let id = GlobalID.init(siteID: data.metadata.id.siteID, operationIndex: idx)
            let metadata = DataModel.Metadata.init(id: id, creationTime: data.metadata.creationTime, deleted: data.metadata.deleted)
            let newData = DataModel.init(metadata: metadata, checkIn: data.checkIn)
            
            let opLog = [site : (idx, [newData.metadata.id])]
            try self.syncInSequence(data: Set([newData]), withOperationLog: opLog)
            
            return newData.metadata.id
        }
        // change
        else
        {
            let idx = try nextOperationIndex(forSite: site)
            let v = try self.data(forID: data.metadata.id)

            if let previousData = v
            {
                var newData = previousData
                newData.merge(with: data)
                
                let opLog = [site : (idx, [newData.metadata.id])]
                try self.syncInSequence(data: Set([newData]), withOperationLog: opLog)
                
                return newData.metadata.id
            }
            else
            {
                throw DataError.missingPreceedingOperations
            }
        }
    }
    
    public func commit(data: [DataModel], withSite site: DataLayer.SiteID) throws -> [GlobalID]
    {
        var returnIDs: [GlobalID] = []
        
        for datum in data
        {
            let id = try self.commit(data: datum, withSite: site)
            returnIDs.append(id)
        }
        
        return returnIDs
    }
    
    public func sync(data: Set<DataModel>, withOperationLog operationLog: DataLayer.OperationLog) throws
    {
        for datum in data
        {
            if datum.metadata.id.operationIndex == DataLayer.wildcardIndex
            {
                throw DataError.wrongSyncCommitChoice
            }
        }
        
        try syncInSequence(data: data, withOperationLog: operationLog)
    }
}

extension DataAccessProtocol where Self: DataAccessProtocolImmediate
{
    public func initialize(_ block: @escaping (Error?)->Void)
    {
        do
        {
            try self.initialize()
            block(nil)
        }
        catch
        {
            block(error)
        }
    }
}

extension DataProtocol where Self: DataProtocolImmediate
{
    public func lamportTimestamp(withCompletionBlock block: @escaping (MaybeError<DataLayer.Time>)->())
    {
        do
        {
            let value = try self.lamportTimestamp()
            block(.value(v: value))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func vectorTimestamp(withCompletionBlock block: @escaping (MaybeError<VectorClock>)->())
    {
        do
        {
            let value = try self.vectorTimestamp()
            block(.value(v: value))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func operationLog(forSite site: DataLayer.SiteID, withCompletionBlock block: @escaping (MaybeError<[GlobalID]>)->())
    {
        do
        {
            let value = try self.operationLog(forSite: site)
            block(.value(v: value))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func operationLog(afterTimestamp timestamp: VectorClock, withCompletionBlock block: @escaping (MaybeError<DataLayer.OperationLog>)->())
    {
        do
        {
            let value = try self.operationLog(afterTimestamp: timestamp)
            block(.value(v: value))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func nextOperationIndex(forSite site: DataLayer.SiteID, withCompletionBlock block: @escaping (MaybeError<DataLayer.Index>)->())
    {
        do
        {
            let value = try self.nextOperationIndex(forSite: site)
            block(.value(v: value))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func data(forID id: GlobalID, withCompletionBlock block: @escaping (MaybeError<DataModel?>)->())
    {
        do
        {
            let value = try self.data(forID: id)
            block(.value(v: value))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func lastAddedData(withCompletionBlock block: @escaping (MaybeError<DataModel?>)->())
    {
        do
        {
            let value = try self.lastAddedData()
            block(.value(v: value))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func data(afterTimestamp timestamp: VectorClock, withCompletionBlock block: @escaping (MaybeError<(Set<DataModel>,VectorClock)>)->())
    {
        do
        {
            let value = try self.data(afterTimestamp: timestamp)
            block(.value(v: value))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func data(fromIncludingDate from: Date, toExcludingDate to: Date, afterTimestamp timestamp: VectorClock?, withCompletionBlock block: @escaping (MaybeError<([DataModel],VectorClock)>)->())
    {
        do
        {
            let value = try self.data(fromIncludingDate: from, toExcludingDate: to, afterTimestamp: timestamp)
            block(.value(v: value))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func pendingUntappd(withCompletionBlock block: @escaping (MaybeError<([DataModel],VectorClock)>)->())
    {
        do
        {
            let value = try self.pendingUntappd()
            block(.value(v: value))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func data(forUntappdID id: DataModel.ID, withCompletionBlock block: @escaping (MaybeError<DataModel?>)->())
    {
        do
        {
            let value = try self.data(forUntappdID: id)
            block(.value(v: value))
        }
        catch
        {
            block(.error(e: error))
        }
    }
}

extension DataWriteProtocol where Self: DataWriteProtocolImmediate
{
    public func commit(data: DataModel, withSite site: DataLayer.SiteID, completionBlock block: @escaping (MaybeError<GlobalID>)->())
    {
        do
        {
            let value = try self.commit(data: data, withSite: site)
            block(.value(v: value))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func commit(data: [DataModel], withSite site: DataLayer.SiteID, completionBlock block: @escaping (MaybeError<[GlobalID]>)->())
    {
        do
        {
            let value = try self.commit(data: data, withSite: site)
            block(.value(v: value))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func sync(data: Set<DataModel>, withOperationLog operationLog: DataLayer.OperationLog, completionBlock block: @escaping (Error?)->())
    {
        do
        {
            try self.sync(data: data, withOperationLog: operationLog)
            block(nil)
        }
        catch
        {
            block(error)
        }
    }
}
