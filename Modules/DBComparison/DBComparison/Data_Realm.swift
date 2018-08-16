//
//  Data_Realm.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-8.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public class Data_Realm
{
}

extension Data_Realm: DataAccessProtocol
{
    public func readTransaction(_ block: @escaping (_ data: DataProtocol)->())
    {
    }
    
    public func readWriteTransaction(_ block: @escaping (_ data: DataWriteProtocol)->())
    {
    }
}

extension Data_Realm: DataProtocol
{
    public func lamportTimestamp(withCompletionBlock block: @escaping (MaybeError<Data.Time>)->())
    {
    }
    
    public func vectorTimestamp(withCompletionBlock block: @escaping (MaybeError<VectorClock>)->())
    {
    }
    
    public func operationLog(forSite site: Data.SiteID, withCompletionBlock block: @escaping (MaybeError<[GlobalID]>)->())
    {
    }
    
    public func operationLog(afterTimestamp timestamp: VectorClock, withCompletionBlock block: @escaping (MaybeError<OperationLog>)->())
    {
    }
    
    public func nextOperationIndex(forSite site: Data.SiteID, withCompletionBlock block: @escaping (MaybeError<Data.Index>)->())
    {
    }
    
    public func data(forID id: GlobalID, withCompletionBlock block: @escaping (MaybeError<DataModel?>)->())
    {
    }
    
    public func data(afterTimestamp timestamp: VectorClock, withCompletionBlock block: @escaping (MaybeError<Set<DataModel>>)->())
    {
    }
    
    public func data(fromIncludingDate from: Date, toExcludingDate to: Date, withCompletionBlock block: @escaping (MaybeError<[DataModel]>)->())
    {
    }
}

extension Data_Realm: DataWriteProtocol
{
    public func commit(data: DataModel, withCompletionBlock block: @escaping (Error?)->())
    {
    }
    
    public func sync(data: DataModel, withCompletionBlock block: @escaping (Error?)->())
    {
    }
    
    public func commit(data: Set<DataModel>, withCompletionBlock block: @escaping (Error?)->())
    {
    }
    
    public func sync(data: Set<DataModel>, withOperationLog: OperationLog, completionBlock block: @escaping (Error?)->())
    {
    }
}

extension Data_Realm: DataDebugProtocol
{
    public func _asserts()
    {
    }
}

