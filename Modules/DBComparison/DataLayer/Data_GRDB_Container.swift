//
//  Data_GRDB_Container.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-14.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import GRDB

public class DatabaseContainer
{
    private unowned var database: Database
    
    private var readyBlock: (()->Void)?
    
    public init(withDatabase database: Database)
    {
        self.database = database
    }
    
    func error() -> Error?
    {
    }
    
    func callback()
    {
        readyBlock()
    }
}

extension DatabaseContainer: DataProtocol
{
    public func lamportTimestamp(withCompletionBlock block: @escaping (MaybeError<DataLayer.Time>)->())
    {
        do
        {
            let val = try self.database.lamportTimestamp()
            self.readyBlock = { block(.value(v: val))
        }
        catch
        {
            self.readyBlock
        }
    }
    
    public func vectorTimestamp(withCompletionBlock block: @escaping (MaybeError<VectorClock>)->())
    {
        self.database.vectorTimestamp { val in
            self.readyBlock = { block(val) }
        }
    }
    
    public func operationLog(forSite site: DataLayer.SiteID, withCompletionBlock block: @escaping (MaybeError<[GlobalID]>)->())
    {
        self.database.operationLog(forSite: site) { val in
            self.readyBlock = { block(val) }
        }
    }
    
    public func operationLog(afterTimestamp timestamp: VectorClock, withCompletionBlock block: @escaping (MaybeError<DataLayer.OperationLog>)->())
    {
        self.database.operationLog(afterTimestamp: timestamp) { val in
            self.readyBlock = { block(val) }
        }
    }
    
    public func nextOperationIndex(forSite site: DataLayer.SiteID, withCompletionBlock block: @escaping (MaybeError<DataLayer.Index>)->())
    {
        self.database.nextOperationIndex(forSite: site) { val in
            self.readyBlock = { block(val) }
        }
    }
    
    public func data(forID id: GlobalID, withCompletionBlock block: @escaping (MaybeError<DataModel?>)->())
    {
        self.database.data(forID: id) { val in
            self.readyBlock = { block(val) }
        }
    }
    
    public func data(afterTimestamp timestamp: VectorClock, withCompletionBlock block: @escaping (MaybeError<Set<DataModel>>)->())
    {
        self.database.data(afterTimestamp: timestamp) { val in
            self.readyBlock = { block(val) }
        }
    }
    
    public func data(fromIncludingDate from: Date, toExcludingDate to: Date, withCompletionBlock block: @escaping (MaybeError<[DataModel]>)->())
    {
        self.database.data(data(fromIncludingDate: from, toExcludingDate: to) { val in
            self.readyBlock = { block(val) }
        }
    }
}

extension DatabaseContainer: DataWriteProtocol
{
    public func commit(data: DataModel, withSite: DataLayer.SiteID, completionBlock block: @escaping (Error?)->())
    {
    }
    
    public func commit(data: Set<DataModel>, withSite: DataLayer.SiteID, completionBlock block: @escaping (Error?)->())
    {
    }
    
    public func sync(data: Set<DataModel>, withOperationLog: DataLayer.OperationLog, completionBlock block: @escaping (Error?)->())
    {
    }
}
