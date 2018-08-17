//
//  Data_GRDB.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-8.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import GRDB

extension Database
{
    // TODO:
    public func explain<T>(request: QueryInterfaceRequest<T>) throws
    {
        //sqlite3_stmt_status
        //
        //let sqlRequest = try SQLRequest(self, request: request)
        ////print(sqlRequest.sql)
        //// Prints SELECT * FROM wine WHERE origin = ? ORDER BY price
        ////print(sqlRequest.arguments)
        //// Prints ["Burgundy"]
        //
        //
        ////let (statement, _) = try request.prepare(self)
        //let sql = "EXPLAIN \(sqlRequest.sql)"
        //
        //sqlRequest.fetch
        //
        //try self.execute(sql, arguments: sqlRequest.arguments).
    }
}

extension Database: DataProtocol {}
extension Database: DataWriteProtocol {}

extension Database: DataProtocolImmediate
{
    public func allSites() throws -> Set<DataLayer.SiteID>
    {
        let request = DataModelLogEntry.select(DataModelLogEntry.Columns.action_uuid).distinct()
        let sites = try String.fetchAll(self, request)
        
        var returnSet: Set<UUID> = Set()
        for site in sites
        {
            guard let uuid = UUID.init(uuidString: site) else
            {
                throw DataError.internalError
            }
            returnSet.insert(uuid)
        }
        
        return returnSet
    }
    
    public func lamportTimestamp() throws -> DataLayer.Time
    {
        let lamportColumns = DataModel.Columns.allCases.filter { $0.isLamport }
        let lamportMaxes = lamportColumns.map { max($0) }
        
        var lamport: DataLayer.Time = 0
        
        for maxQuery in lamportMaxes
        {
            let localMax = try DataLayer.Time.fetchOne(self, DataModel.select(maxQuery)) ?? 0
            lamport = max(localMax, lamport)
        }
        
        return lamport
    }
    
    public func vectorTimestamp() throws -> VectorClock
    {
        //SELECT site, max([index]) FROM log GROUP BY site;
        
        let request = DataModelLogEntry.select(DataModelLogEntry.Columns.action_uuid, max(DataModelLogEntry.Columns.action_index)).group(DataModelLogEntry.Columns.action_uuid)
        let rows = try Row.fetchAll(self, request)
        
        var map: [DataLayer.SiteID:DataLayer.Time] = [:]
        
        for row in rows
        {
            guard let uuid = DataLayer.SiteID.init(uuidString: row[0]) else
            {
                throw DataError.internalError
            }
            map[uuid] = row[1]
        }
        
        let clock = VectorClock.init(map: map)
        
        return clock
    }
    
    private func operationLogQuery(afterTimestamp timestamp: VectorClock, includingMissing: Bool, onlyGreaterThan: Bool) throws -> (String, StatementArguments)
    {
        var sites = try allSites()
        let siteColumn = DataModelLogEntry.Columns.action_uuid.rawValue
        let indexColumn = DataModelLogEntry.Columns.action_index.rawValue
        
        if !includingMissing
        {
            sites.formIntersection(timestamp.map.keys)
        }
        
        var query = ""
        var vals: StatementArguments = []
        
        for (i, site) in sites.enumerated()
        {
            let maybeIndex = timestamp.time(forSite: site)
            let index = maybeIndex ?? 0
            
            let sign = onlyGreaterThan && maybeIndex != nil ? ">" : ">="
            query += "(\(siteColumn) = ? AND \(indexColumn) \(sign) ?)"
            vals += [site.uuidString, index]
            
            if i < sites.count - 1
            {
                query += " OR "
            }
        }
        
        return (query, vals)
    }
    
    private func operationLog(afterTimestamp timestamp: VectorClock, includingMissing: Bool, onlyGreaterThan: Bool) throws -> DataLayer.OperationLog
    {
        let query = try operationLogQuery(afterTimestamp: timestamp, includingMissing: includingMissing, onlyGreaterThan: onlyGreaterThan)
        
        if query.0.isEmpty
        {
            return [:]
        }
        
        let request = DataModelLogEntry.filter(sql: query.0, arguments: query.1).order(DataModelLogEntry.Columns.action_uuid, DataModelLogEntry.Columns.action_index)
        let values = try DataModelLogEntry.fetchAll(self, request)
        
        var operationLog: DataLayer.OperationLog = [:]
        var site: DataLayer.SiteID! = nil
        var operations: [GlobalID] = []
        var startingIndex: DataLayer.Index! = nil
        func tryCommit(_ v: DataModelLogEntry?)
        {
            if v == nil || v!.site != site
            {
                if let aSite = site
                {
                    operationLog[aSite] = (startingIndex!, operations)
                }
                site = v?.site
                operations = []
                startingIndex = v?.index
            }
        }
        for value in values
        {
            tryCommit(value)
            operations.append(value.operation)
        }
        tryCommit(nil)
        
        return operationLog
    }
    
    public func operationLog(forSite site: DataLayer.SiteID) throws -> [GlobalID]
    {
        let timestamp = VectorClock.init(map: [site:0])
        return try self.operationLog(afterTimestamp: timestamp, includingMissing: false, onlyGreaterThan: false).first?.value.operations ?? []
    }
    
    public func operationLog(afterTimestamp timestamp: VectorClock) throws -> DataLayer.OperationLog
    {
        return try self.operationLog(afterTimestamp: timestamp, includingMissing: true, onlyGreaterThan: true)
    }
    
    public func nextOperationIndex(forSite site: DataLayer.SiteID) throws -> DataLayer.Index
    {
        let statement = "SELECT MAX(\(DataModelLogEntry.Columns.action_index.rawValue)) FROM \(DataModelLogEntry.databaseTableName) WHERE (\(DataModelLogEntry.Columns.action_uuid.rawValue) = ?)"
        let query = try self.cachedSelectStatement(statement)
        
        if let index = try DataLayer.Index.fetchOne(query, arguments: [site.uuidString])
        {
            return index + 1
        }
        else
        {
            return 0
        }
    }
    
    public func data(forID id: GlobalID) throws -> DataModel?
    {
        return try DataModel.fetchOne(self, key: [DataModel.Columns.metadata_id_uuid.rawValue : id.siteID.uuidString, DataModel.Columns.metadata_id_index.rawValue : id.operationIndex])
    }
    
    public func lastAddedData() throws -> DataModel?
    {
        return try DataModel.filter(max(DataModel.Columns.metadata_creation_time)).fetchOne(self)
    }
    
    public func data(afterTimestamp timestamp: VectorClock) throws -> (Set<DataModel>,VectorClock)
    {
        let log = try self.operationLog(afterTimestamp: timestamp, includingMissing: true, onlyGreaterThan: true)
        
        let set = log.reduce(Set<GlobalID>()) { set, pair in return set.union(pair.value.operations) }
        var returnSet = Set<DataModel>()
        
        for item in set
        {
            guard let data = try self.data(forID: item) else
            {
                throw DataError.internalError
            }
            returnSet.insert(data)
        }
        
        let timestamp = try vectorTimestamp()
        
        return (returnSet,timestamp)
    }
    
    public func data(fromIncludingDate from: Date, toExcludingDate to: Date, afterTimestamp timestamp: VectorClock?) throws -> ([DataModel], VectorClock)
    {
        if let timestamp = timestamp
        {
            let globalTimestamp = try vectorTimestamp()
            let innerQuery = try operationLogQuery(afterTimestamp: timestamp, includingMissing: true, onlyGreaterThan: true)
            
            if innerQuery.0.isEmpty
            {
                return ([], globalTimestamp)
            }
            
            let dataTable = DataModel.databaseTableName
            let dataIdColumn = DataModel.Columns.metadata_id_uuid.rawValue
            let dataIndexColumn = DataModel.Columns.metadata_id_index.rawValue
            let logTable = DataModelLogEntry.databaseTableName
            let logIdColumn = DataModelLogEntry.Columns.operation_uuid
            let logIndexColumn = DataModelLogEntry.Columns.operation_index
            let dateColumn = DataModel.Columns.checkin_time_value.rawValue
            
             //SELECT metadata_id_uuid, metadata_id_index FROM (SELECT metadata_id_uuid, metadata_id_index, checkin_time_value FROM log JOIN data ON (log.action_uuid, log.action_index) = (data.metadata_id_uuid, data.metadata_id_index) WHERE (action_uuid = "5E011DC9-638A-4AD7-88A6-4E84DE19DD85" AND action_index > 20 AND action_index < 100)) WHERE (checkin_time_value > 1533990071.58237);
            
            let query = "SELECT * FROM (SELECT * FROM \(logTable) JOIN \(dataTable) ON (\(dataIdColumn), \(dataIndexColumn)) = (\(logIdColumn), \(logIndexColumn)) WHERE (\(innerQuery.0))) WHERE (\(dateColumn) >= ? AND \(dateColumn) < ?)"
            
            let allData = try DataModel.fetchAll(self, query, arguments: innerQuery.1 + [from.timeIntervalSince1970, to.timeIntervalSince1970])
            
            return (allData, globalTimestamp)
        }
        else
        {
            let request = DataModel.filter(DataModel.Columns.checkin_time_value >= from.timeIntervalSince1970 && DataModel.Columns.checkin_time_value < to.timeIntervalSince1970)
            let values = try DataModel.fetchAll(self, request)
            let timestamp = try vectorTimestamp()
            
            return (values, timestamp)
        }
    }
}

extension Database: DataWriteProtocolImmediate
{
    // TODO: if it's assumed that the lamport timestamps are correct, then why not assume the wildcard is taken care of, too?
    public func commit(data: [DataModel], withSite site: DataLayer.SiteID) throws -> [GlobalID]
    {
        if data.count == 0
        {
            return []
        }
        
        var newDatas: [DataModel] = []
        var newOperationLogArray: [GlobalID] = []
        var newOperationLogIndex: DataLayer.Index! = nil
        var nextOperationForSite: [DataLayer.SiteID:DataLayer.Index] = [:]
        
        func prepareNextOperationIndex(forSite site: DataLayer.SiteID) throws -> DataLayer.Index
        {
            if let op = nextOperationForSite[site]
            {
                nextOperationForSite[site] = op + 1
            }
            else
            {
                nextOperationForSite[site] = try self.nextOperationIndex(forSite: site)
            }
            
            return nextOperationForSite[site]!
        }
        
        for datum in data
        {
            // new operation
            if datum.metadata.id.operationIndex == DataLayer.wildcardIndex
            {
                let idx = try prepareNextOperationIndex(forSite: site)
                
                let id = GlobalID.init(siteID: site, operationIndex: idx)
                let metadata = DataModel.Metadata.init(id: id, creationTime: datum.metadata.creationTime, deleted: datum.metadata.deleted)
                let newData = DataModel.init(metadata: metadata, checkIn: datum.checkIn)
                
                newDatas.append(newData)
                newOperationLogArray.append(id)
                if newOperationLogIndex == nil
                {
                    newOperationLogIndex = idx
                }
            }
            // change
            else
            {
                let idx = try prepareNextOperationIndex(forSite: site)
                let v = try self.data(forID: datum.metadata.id)
                
                if let previousData = v
                {
                    var newData = datum
                    newData.merge(with: previousData)
                    
                    newDatas.append(newData)
                    newOperationLogArray.append(newData.metadata.id)
                    if newOperationLogIndex == nil
                    {
                        newOperationLogIndex = idx
                    }
                }
                else
                {
                    throw DataError.missingPreceedingOperations
                }
            }
        }
        
        let newOperationLog: DataLayer.OperationLog = [site : (newOperationLogIndex, newOperationLogArray)]
        
        try self.syncInSequence(data: Set(newDatas), withOperationLog: newOperationLog)
        
        return newDatas.map { $0.metadata.id }
    }
}

extension Database: DataAccessEasySyncProtocolImmediate
{
    // Assumes passed-in data is complete and filled in, with correct indices, and without any wildcards.
    public func syncInSequence(data: Set<DataModel>, withOperationLog operationLog: DataLayer.OperationLog) throws
    {
        assert(operationLog.values.reduce(Set()) { set, pair in return set.union(pair.operations) } ==
            Set(data.map { return $0.metadata.id }), "data and index map don't match")
        
        if data.count == 0
        {
            return
        }
        
        var map: [GlobalID:DataModel] = [:]
        data.forEach { map[$0.metadata.id] = $0 }
        var processed: Set<GlobalID> = Set()
        
        let fetchPreviousDataStatement = try self.makeSelectStatement("SELECT * FROM \(DataModel.databaseTableName) WHERE (\(DataModel.Columns.metadata_id_uuid.rawValue) = ? AND \(DataModel.Columns.metadata_id_index.rawValue) = ?)")
        
        func stepTwo(dataID: GlobalID, site: DataLayer.SiteID, index: DataLayer.Index) throws
        {
            let newDataO = map[dataID]
            guard let newData = newDataO else
            {
                throw DataError.internalError
            }
            
            if !processed.contains(dataID)
            {
                var commitData: DataModel
                
                commitData: do
                {
                    // PERF: major time spent making query
                    if let previousData = try DataModel.fetchOne(fetchPreviousDataStatement, arguments: [dataID.siteID.uuidString, dataID.operationIndex])
                    {
                        commitData = newData
                        commitData.merge(with: previousData)
                        try commitData.update(self)
                    }
                    else
                    {
                        commitData = newData
                        try commitData.insert(self)
                    }
                }
                
                processed.insert(dataID)
            }
            
            commitOperations: do
            {
                // TODO: move to parameters
                let operation = DataModelLogEntry.init(site: site, index: index, operation: dataID)
                try operation.insert(self)
            }
        }
        
        for (site, pair) in operationLog
        {
            for (i, op) in pair.operations.enumerated()
            {
                let idx = Int(pair.startingIndex) + i
                let nextIndex = try self.nextOperationIndex(forSite: site)
                
                // operation exists, check if it's the same
                if idx < nextIndex
                {
                    // NEXT: verify
                    //let previousOperation = self.operations[site]![idx]
                    //
                    //if previousOperation != op
                    //{
                    //    error = DataError.mismatchedOperation
                    //}
                    //else
                    //{
                        print("warning: operation \(op) already exists, skipping")
                    //}
                }
                // operation does not exist
                else if idx == nextIndex
                {
                    try stepTwo(dataID: op, site: site, index: nextIndex)
                }
                else
                {
                    throw DataError.missingPreceedingOperations
                }
            }
        }
    }
}
