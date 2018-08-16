//
//  Data_Access.swift
//  DataLayer
//
//  Created by Alexei Baboulevitch on 2018-8-15.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

// A persistent data store will (in all likelihood) conform to each of the below protocols. The client will only
// see the DataAccessProtocol functions, allowing reads and writes to be internally serialized as needed.

public protocol DataAccessProtocol
{
    func initialize(_ block: @escaping (Error?)->Void)
    
    // Inside these blocks, the view of the store must be consistent!
    func readTransaction(_ block: @escaping (_ data: DataProtocol)->())
    func readWriteTransaction(_ block: @escaping (_ data: DataWriteProtocol)->())
}

// A generic interface for persistent stores, e.g. databases or cloud storage providers.
public protocol DataProtocol
{
    func lamportTimestamp(withCompletionBlock block: @escaping (MaybeError<DataLayer.Time>)->())
    func vectorTimestamp(withCompletionBlock block: @escaping (MaybeError<VectorClock>)->())
    
    // operation log
    func operationLog(forSite site: DataLayer.SiteID, withCompletionBlock block: @escaping (MaybeError<[GlobalID]>)->())
    func operationLog(afterTimestamp timestamp: VectorClock, withCompletionBlock block: @escaping (MaybeError<DataLayer.OperationLog>)->())
    func nextOperationIndex(forSite site: DataLayer.SiteID, withCompletionBlock block: @escaping (MaybeError<DataLayer.Index>)->())
    
    // data
    func data(forID id: GlobalID, withCompletionBlock block: @escaping (MaybeError<DataModel?>)->())
    
    // batch; contains everything > timestamp and includes missing sites
    // AB: this could return more operations than we need, but conflict-free merge should eliminate errors
    func data(afterTimestamp timestamp: VectorClock, withCompletionBlock block: @escaping (MaybeError<Set<DataModel>>)->())
    
    // queries
    func data(fromIncludingDate from: Date, toExcludingDate to: Date, withCompletionBlock block: @escaping (MaybeError<[DataModel]>)->())
}

public protocol DataWriteProtocol: DataProtocol
{
    func commit(data: DataModel, withSite: DataLayer.SiteID, completionBlock block: @escaping (MaybeError<GlobalID>)->())
    func commit(data: [DataModel], withSite: DataLayer.SiteID, completionBlock block: @escaping (MaybeError<[GlobalID]>)->())
    
    func sync(data: Set<DataModel>, withOperationLog: DataLayer.OperationLog, completionBlock block: @escaping (Error?)->())
}

public protocol DataProtocolImmediate
{
    func lamportTimestamp() throws -> DataLayer.Time
    func vectorTimestamp() throws -> VectorClock
    
    // operation log
    func operationLog(forSite site: DataLayer.SiteID) throws -> [GlobalID]
    func operationLog(afterTimestamp timestamp: VectorClock) throws -> DataLayer.OperationLog
    func nextOperationIndex(forSite site: DataLayer.SiteID) throws -> DataLayer.Index
    
    // data
    func data(forID id: GlobalID) throws -> DataModel?
    
    // batch; contains everything >= timestamp and includes missing sites
    func data(afterTimestamp timestamp: VectorClock) throws -> Set<DataModel>
    
    // queries
    func data(fromIncludingDate from: Date, toExcludingDate to: Date) throws -> [DataModel]
}

public protocol DataWriteProtocolImmediate: DataProtocolImmediate
{
    func commit(data: DataModel, withSite: DataLayer.SiteID) throws -> GlobalID
    func commit(data: [DataModel], withSite: DataLayer.SiteID) throws -> [GlobalID]
    
    func sync(data: Set<DataModel>, withOperationLog: DataLayer.OperationLog) throws
}

public protocol DataDebugProtocol
{
    func _asserts()
}
