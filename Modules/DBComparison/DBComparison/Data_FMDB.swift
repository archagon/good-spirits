//
//  Data_FMDB.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-5.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import FMDB

public class Data_FMDB
{
    let database: FMDatabase
    let queue: FMDatabaseQueue
    
    init?()
    {
        let path: String? = (NSTemporaryDirectory() as NSString).appendingPathComponent("\(UUID()).db")
        
        //self.database = FMDatabase.init(path: nil) //in-memory
        //self.database = FMDatabase.init(path: "") //temp file
        self.database = FMDatabase.init(path: path)
        
        self.queue = FMDatabaseQueue.init(path: path)!
        
        // TODO: pragma foreign keys needs to be done here
        let opened = self.database.open()
        if !opened
        {
            return nil
        }
        
        print("database path: \(path ?? "<null>")")
    }
    
    deinit
    {
        self.database.close()
        
        if let path = self.database.databasePath, path != ""
        {
            try! FileManager.default.removeItem(atPath: path)
        }
    }
}

extension Data_FMDB: DataAccessProtocol
{
    public func initialize(_ block: @escaping (Error?)->Void)
    {
        let foreignKeys = "PRAGMA foreign_keys = ON;"
        
        let valueSchema = DataModel.sqlValueSchemaStatement()
        let lamportSchema = DataModel.sqlLamportSchemaStatement()
        //let logConstraint = ", CHECK ((operation_index IS 0) OR (operation_index IS 1))"
        let logConstraint = ""
        let logSchema = "( site TEXT NOT NULL, operation_index INTEGER NOT NULL, metadata_id_uuid TEXT NOT NULL, metadata_id_index INTEGER NOT NULL, PRIMARY KEY (site, operation_index), FOREIGN KEY (metadata_id_uuid, metadata_id_index) REFERENCES data (metadata_id_uuid, metadata_id_index)\(logConstraint) )"
        
        let createValueTableCommand = "CREATE TABLE IF NOT EXISTS data \(valueSchema);"
        let createLamportTableCommand = "CREATE TABLE IF NOT EXISTS lamport \(lamportSchema);"
        let createLogTableCommand = "CREATE TABLE IF NOT EXISTS log \(logSchema);"
        
        self.queue.inDatabase
        { db in
            do
            {
                try db.executeUpdate(foreignKeys, values: nil)
                try db.executeUpdate(createValueTableCommand, values: nil)
                try db.executeUpdate(createLamportTableCommand, values: nil)
                try db.executeUpdate(createLogTableCommand, values: nil)
                block(nil)
            }
            catch
            {
                block(error)
            }
        }
    }
    
    public func readTransaction(_ block: @escaping (_ data: DataProtocol)->())
    {
        self.queue.inDatabase
        { db in
            let container = DatabaseContainer.init(withDatabase: db, queue: self.queue)
            block(container)
        }
    }
    
    public func readWriteTransaction(_ block: @escaping (_ data: DataWriteProtocol)->())
    {
        self.queue.inDatabase
        { db in
            let container = DatabaseContainer.init(withDatabase: db, queue: self.queue)
            block(container)
        }
    }
}

extension Data_FMDB: DataDebugProtocol
{
    public func _asserts()
    {
//        assert({
//            let query = "SELECT COUNT(*) FROM (?);"
//            var result: Bool = false
//            synced
//            { done in
//                self.queue.inDatabase
//                { db in
//                    do
//                    {
//                        let results1 = try db.executeQuery(query, values: ["data"])
//                        let results2 = try db.executeQuery(query, values: ["lamport"])
//                        var total1: Int32 = -1
//                        var total2: Int32 = -1
//                        while results1.next()
//                        {
//                            total1 = results1.int(forColumnIndex: 0)
//                        }
//                        while results2.next()
//                        {
//                            total2 = results1.int(forColumnIndex: 0)
//                        }
//                        result = (total1 == total2 && total1 != -1)
//                        done()
//                    }
//                    catch
//                    {
//                        done()
//                    }
//                }
//            }
//            return result
//        }())
    }
}

private class DatabaseContainer
{
    public var database: FMDatabase
    public var queue: FMDatabaseQueue
    
    public init(withDatabase db: FMDatabase, queue: FMDatabaseQueue)
    {
        self.database = db
        self.queue = queue
    }
    
    deinit
    {
        print("container deinitting")
    }
    
    var qqqOpIndex: Data.Index = 0
}

extension DatabaseContainer: DataAccessEasySyncProtocol {}

extension DatabaseContainer: DataProtocol
{
    private static func reconstructDataModel(withID: GlobalID, fromResultSet resultSet: FMResultSet) -> DataModel
    {
        func nameForKeyPath(_ path: PartialKeyPath<DataModel>, lamport: Bool) -> String
        {
            if lamport
            {
                return DataModel.sqlLamportMapping.first(where: { tuple in tuple.path == path })!.name
            }
            else
            {
                return DataModel.sqlPropertyMapping.first(where: { tuple in tuple.path == path })!.name
            }
        }
        
        // PERF: cache
        var name: [PartialKeyPath<DataModel>:String] = [:]
        for item in DataModel.sqlPropertyMapping { name[item.path] = item.name }
        for item in DataModel.sqlLamportMapping { name[item.path] = item.name }
        
        let idUUID = resultSet.string(forColumn: name[\DataModel.metadata.id.siteID.uuidString]!) ?? ""
        let idIndex = resultSet.unsignedLongLongInt(forColumn: name[\DataModel.metadata.id.operationIndex]!)
        let lastChangeIdUUID = resultSet.string(forColumn: name[\DataModel.metadata.lastChange.siteID.uuidString]!) ?? ""
        let lastChangeIdIndex = resultSet.unsignedLongLongInt(forColumn: name[\DataModel.metadata.lastChange.operationIndex]!)
        let creationTime = resultSet.double(forColumn: name[\DataModel.metadata.creationTime]!)
        let id = GlobalID.init(siteID: Data.SiteID.init(uuidString: idUUID)!, operationIndex: Data.Index(idIndex))
        let lastChangeId = GlobalID.init(siteID: Data.SiteID.init(uuidString: lastChangeIdUUID)!, operationIndex: Data.Index(lastChangeIdIndex))
        let metadata = DataModel.Metadata.init(id: id, lastChange: lastChangeId, creationTime: creationTime)
        
        let nameValue = (resultSet.columnIsNull(name[\DataModel.checkIn.drink.name.v]!) ? nil : resultSet.string(forColumn: name[\DataModel.checkIn.drink.name.v]!) ?? "")
        let nameLamport = resultSet.unsignedLongLongInt(forColumn: name[\DataModel.checkIn.drink.name.lamport]!)
        let styleValue = resultSet.string(forColumn: name[\DataModel.checkIn.drink.style.v.rawValue]!) ?? ""
        let styleLamport = resultSet.unsignedLongLongInt(forColumn: name[\DataModel.checkIn.drink.style.lamport]!)
        let abvValue = resultSet.double(forColumn: name[\DataModel.checkIn.drink.abv.v]!)
        let abvLamport = resultSet.unsignedLongLongInt(forColumn: name[\DataModel.checkIn.drink.abv.lamport]!)
        let priceValue = (resultSet.columnIsNull(name[\DataModel.checkIn.drink.price.v]!) ? nil : resultSet.double(forColumn: name[\DataModel.checkIn.drink.price.v]!))
        let priceLamport = resultSet.unsignedLongLongInt(forColumn: name[\DataModel.checkIn.drink.price.lamport]!)
        let volumeValue = resultSet.double(forColumn: name[\DataModel.checkIn.drink.volume.v.value]!)
        let volumeUnit = resultSet.string(forColumn: name[\DataModel.checkIn.drink.volume.v.unit.symbol]!) ?? ""
        let volumeLamport = resultSet.unsignedLongLongInt(forColumn: name[\DataModel.checkIn.drink.volume.lamport]!)
        let unit: UnitVolume = (volumeUnit == "fl oz" ? .fluidOunces : volumeUnit == "mL" ? .milliliters : .bushels)
        if unit == .bushels { fatalError("unit not included") } // HACK: NSUnitAcceleration crash
        let volume = Measurement<UnitVolume>.init(value: volumeValue, unit: unit)
        let drink = DataModel.Drink.init(name: .init(v: nameValue, t: nameLamport), style: .init(v: DataModel.Drink.Style.init(rawValue: styleValue)!, t: styleLamport), abv: .init(v: abvValue, t: abvLamport), price: .init(v: priceValue, t: priceLamport), volume: .init(v: volume, t: volumeLamport))
        
        let untappdIdValue = (resultSet.columnIsNull(name[\DataModel.checkIn.untappdId.v]!) ? nil : resultSet.unsignedLongLongInt(forColumn: name[\DataModel.checkIn.untappdId.v]!))
        let untappdIdLamport = resultSet.unsignedLongLongInt(forColumn: name[\DataModel.checkIn.untappdId.lamport]!)
        let timeValue = resultSet.double(forColumn: name[\DataModel.checkIn.time.v]!)
        let timeLamport = resultSet.unsignedLongLongInt(forColumn: name[\DataModel.checkIn.time.lamport]!)
        let checkIn = DataModel.CheckIn.init(untappdId: .init(v: untappdIdValue, t: untappdIdLamport), time: .init(v: timeValue, t: timeLamport), drink: drink)
        
        let model = DataModel.init(metadata: metadata, checkIn: checkIn)
        
        return model
    }
    
    private func allSites(withCompletionBlock block: @escaping (MaybeError<Set<Data.SiteID>>)->Void)
    {
        do
        {
            let statement = "SELECT DISTINCT site FROM log;"
            let results = try self.database.executeQuery(statement, values: nil)
            var returnVal = Set<Data.SiteID>()
            while results.next()
            {
                let site = results.string(forColumnIndex: 0) ?? ""
                let uuid = UUID.init(uuidString: site)!
                returnVal.insert(uuid)
            }
            block(.value(v: returnVal))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func lamportTimestamp(withCompletionBlock block: @escaping (MaybeError<Data.Time>)->())
    {
        do
        {
            var val: Data.Time = 0
            
            for col in DataModel.sqlLamportMappingWithoutForeignKeys
            {
                let query = "SELECT MAX(\(col.name)) FROM (SELECT \(col.name) FROM lamport);"
                let retVal = try self.database.executeQuery(query, values: nil)
                while retVal.next()
                {
                    if retVal.columnIndexIsNull(0)
                    {
                        let newVal = retVal.unsignedLongLongInt(forColumnIndex: 0)
                        val = max(val, newVal)
                    }
                }
            }
            
            block(MaybeError.value(v: val))
        }
        catch
        {
            block(MaybeError.error(e: error))
        }
    }
    
    public func vectorTimestamp(withCompletionBlock block: @escaping (MaybeError<VectorClock>)->())
    {
        allSites
        {
            switch $0
            {
            case .error(let e):
                block(.error(e: e))
            case .value(let v):
                var mapping: [Data.SiteID:Data.Time] = [:]
                var error: Error? = nil
                
                for site in v
                {
                    self.nextOperationIndex(forSite: site)
                    {
                        switch $0
                        {
                        case .error(let e):
                            error = e
                        case .value(let v):
                            mapping[site] = Data.Time(v)
                        }
                    }
                    
                    if error != nil
                    {
                        block(.error(e: error!))
                        return
                    }
                }
                
                let vector = VectorClock.init(map: mapping)
                block(.value(v: vector))
            }
        }
    }
    
    public func operationLog(forSite site: Data.SiteID, withCompletionBlock block: @escaping (MaybeError<[GlobalID]>)->())
    {
        do
        {
            let query = "SELECT * FROM log WHERE (site = (?));"
            let results = try self.database.executeQuery(query, values: [site.uuidString])
            var out: [GlobalID] = []
            while results.next()
            {
                let uuid = results.string(forColumn: "metadata_id_uuid")!
                let index = results.unsignedLongLongInt(forColumn: "metadata_id_index")
                let id = GlobalID.init(siteID: Data.SiteID.init(uuidString: uuid)!, operationIndex: Data.Index(index))
                out.append(id)
            }
            block(.value(v: out))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func operationLog(afterTimestamp timestamp: VectorClock, withCompletionBlock block: @escaping (MaybeError<Data.OperationLog>)->())
    {
        var sites: Set<Data.SiteID>! = nil
        var error: Error? = nil
        synced
        { done in
            self.allSites
            {
                switch $0
                {
                case .error(let e):
                    error = e
                    done()
                case .value(let v):
                    sites = v
                    done()
                }
            }
        }
        if let e = error
        {
            block(.error(e: e))
        }
        
        var query = ""
        var values: [Any] = []
        for (i, site) in sites.enumerated()
        {
            let index = timestamp.time(forSite: site) ?? 0
            let statement = "site == (?) AND operation_index >= (?)"
            values.append(site.uuidString)
            values.append(index)
            
            query += "(\(statement))"
            
            if i < sites.count - 1
            {
                query += " OR "
            }
        }
        let statement = "SELECT * FROM log\(query == "" ? "" : " WHERE (\(query))");"
        
        do
        {
            var returnSet: [Data.SiteID:(Data.Index,[GlobalID])] = [:]
            
            let results = try self.database.executeQuery(statement, values: values)
            while results.next()
            {
                let site = results.string(forColumn: "site")!
                let siteUUID = UUID.init(uuidString: site)!
                let startingIndex = Data.Index(timestamp.time(forSite: siteUUID) ?? 0)
                let uuid = results.string(forColumn: "metadata_id_uuid")!
                let uuidUUID = UUID.init(uuidString: uuid)!
                let index = Data.Index(results.unsignedLongLongInt(forColumn: "metadata_id_index"))
                let id = GlobalID.init(siteID: uuidUUID, operationIndex: index)
                
                if returnSet[siteUUID] == nil { returnSet[siteUUID] = (startingIndex, []) }
                returnSet[siteUUID]!.1.append(id)
            }
            block(.value(v: returnSet))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func nextOperationIndex(forSite site: Data.SiteID, withCompletionBlock block: @escaping (MaybeError<Data.Index>)->())
    {
        do
        {
            let query = "SELECT MAX(operation_index) from log WHERE site == \"\(site.uuidString)\";"
            let results = try self.database.executeQuery(query, values: nil)
            var index: Int = -1
            while results.next()
            {
                if !results.columnIndexIsNull(0)
                {
                    index = Int(results.unsignedLongLongInt(forColumnIndex: 0))
                }
            }
            block(.value(v: Data.Index(index + 1)))
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
            // PERF: slow
            let tableQuery = "SELECT * FROM data INNER JOIN lamport on (lamport.metadata_id_uuid, lamport.metadata_id_index) = (data.metadata_id_uuid, data.metadata_id_index)"
            
            // TODO: primary key reference
            let query = "SELECT * from (\(tableQuery)) WHERE (\(DataModel.sqlPropertyMapping[0].name) == (?) AND \(DataModel.sqlPropertyMapping[1].name) == (?));"
            
            let results = try self.database.executeQuery(query, values: [id.siteID.uuidString, id.operationIndex])
            var out: DataModel? = nil
            while results.next()
            {
                out = DatabaseContainer.reconstructDataModel(withID: id, fromResultSet: results)
            }
            block(.value(v: out))
        }
        catch
        {
            block(.error(e: error))
        }
    }
    
    public func data(afterTimestamp timestamp: VectorClock, withCompletionBlock block: @escaping (MaybeError<Set<DataModel>>)->())
    {
        operationLog(afterTimestamp: timestamp)
        {
            switch $0
            {
            case .error(let e):
                block(.error(e: e))
            case .value(let v):
                let set = v.reduce(Set<GlobalID>()) { set, pair in return set.union(pair.value.operations) }
                
                var returnSet = Set<DataModel>()
                
                let group = DispatchGroup.init()
                var error: Error? = nil
                
                for i in 0..<set.count
                {
                    group.enter()
                }
                
                for (i, item) in set.enumerated()
                {
                    self.data(forID: item)
                    {
                        switch $0
                        {
                        case .error(let e):
                            error = (error ?? e)
                            group.leave()
                        case .value(let v):
                            returnSet.insert(v!)
                            group.leave()
                        }
                    }
                }
                
                group.wait()
                
                if let e = error
                {
                    block(.error(e: e))
                }
                else
                {
                    block(.value(v: returnSet))
                }
            }
        }
    }
    
    public func data(fromIncludingDate from: Date, toExcludingDate to: Date, withCompletionBlock block: @escaping (MaybeError<[DataModel]>)->())
    {
        fatalError("not implemented")
    }
}

extension DatabaseContainer: DataWriteProtocol
{
    // Assumes passed-in data is complete and filled in, with correct indices, and without any wildcards.
    public func syncInSequence(data: Set<DataModel>, withOperationLog operationLog: Data.OperationLog, completionBlock block: @escaping (Error?)->Void)
    {
        assert(operationLog.values.reduce(Set()) { set, pair in return set.union(pair.operations) } ==
            Set(data.map { return $0.metadata.id }), "data and index map don't match")
        
        if data.count == 0
        {
            block(nil)
            return
        }
        
        var processed: Set<GlobalID> = Set()
        
        func stepTwo(dataID: GlobalID, site: Data.SiteID, index: Data.Index) -> Error?
        {
            // PERF: slow
            let newData = data.first { $0.metadata.id == dataID }!
            
            if !processed.contains(dataID)
            {
                var commitData: DataModel
                
                updateData: do
                {
                    var maybePreviousData: DataModel?
                    var error: Error? = nil
                    
                    getPreviousData: do
                    {
                        let group = DispatchGroup()
                        group.enter()
                        self.data(forID: newData.metadata.id)
                        { dataOrError in
                            defer { group.leave() }
                            switch dataOrError
                            {
                            case .error(let e):
                                error = e
                            case .value(let v):
                                maybePreviousData = v
                            }
                        }
                        group.wait()
                        
                        if error != nil { return error }
                    }
                
                    if let previousData = maybePreviousData
                    {
                        commitData = newData
                        commitData.merge(with: previousData)
                    }
                    else
                    {
                        commitData = newData
                    }
                }
                
                updateStores: do
                {
                    let statement = DatabaseContainer.insertTransaction(withTable: "data", count: DataModel.sqlPropertyMapping.count)
                    let lamportStatement = DatabaseContainer.insertTransaction(withTable: "lamport", count: DataModel.sqlLamportMapping.count)
                    try self.database.executeUpdate(statement, values: commitData.sqlRowValues())
                    try self.database.executeUpdate(lamportStatement, values: commitData.sqlLamportRowValues())
                }
                catch
                {
                    return error
                }
                
                processed.insert(dataID)
            }
            
            updateOperations: do
            {
                let statement = "INSERT INTO log VALUES (?, ?, ?, ?)"
                let values: [Any] = [site, index, dataID.siteID, dataID.operationIndex]
                try self.database.executeUpdate(statement, values: values)
            }
            catch
            {
                return error
            }
            
            return nil
        }
        
        var error: Error? = nil
        
        for (site, pair) in operationLog
        {
            for (i, op) in pair.operations.enumerated()
            {
                let idx = Int(pair.startingIndex) + i
                
                var nextIndex: Data.Index! = nil
                synced
                { done in
                    self.nextOperationIndex(forSite: site)
                    {
                        defer { done() }
                        switch $0
                        {
                        case .error(let e):
                            error = e
                        case .value(let v):
                            nextIndex = v
                        }
                    }
                }
                if error != nil { break }
                
                
                // operation exists, check if it's the same
                if idx < nextIndex
                {
//                    let previousOperation = self.operations[site]![idx]
//
//                    if previousOperation != op
//                    {
//                        error = DataError.mismatchedOperation
//                    }
//                    else
//                    {
                        print("warning: operation \(op) already exists, skipping")
//                    }
                }
                // operation does not exist
                else
                {
                    synced
                    { done in
                        self.nextOperationIndex(forSite: site)
                        { index in
                            switch index
                            {
                            case .error(let e):
                                error = e
                                done()
                            case .value(let v):
                                if idx != v
                                {
                                    error = DataError.missingPreceedingOperations
                                    done()
                                }
                                else
                                {
                                    error = stepTwo(dataID: op, site: site, index: v)
                                    done()
                                }
                            }
                        }
                    }
                }
                
                if error != nil  { break }
            }

            if let e = error
            {
                block(e)
                break
            }
        }
        
        block(error)
    }
    
    private static func insertTransaction(withTable table: String, count: Int) -> String
    {
        var questions = ""
        for i in 0..<count
        {
            questions += "?"
            if i < count - 1
            {
                questions += ", "
            }
        }
        
        let statement = "INSERT OR REPLACE INTO \(table) VALUES (\(questions))"
        
        return statement
    }
    
    public func commit(data: DataModel, withCompletionBlock block: @escaping (Error?)->())
    {
        // new operation
        if data.metadata.id.operationIndex == Data.wildcardIndex
        {
            assert(data.metadata.lastChange.operationIndex == Data.wildcardIndex, "invalid format")
            
            self.nextOperationIndex(forSite: data.metadata.lastChange.siteID)
            {
                switch $0
                {
                case .error(let e):
                    block(e)
                case .value(let idx):
                    let id = GlobalID.init(siteID: data.metadata.id.siteID, operationIndex: idx)
                    let metadata = DataModel.Metadata.init(id: id, lastChange: id, creationTime: data.metadata.creationTime)
                    let newData = DataModel.init(metadata: metadata, checkIn: data.checkIn)
                    
                    let opLog = [newData.metadata.lastChange.siteID:(idx,[newData.metadata.id])]
                    self.syncInSequence(data: Set([newData]), withOperationLog: opLog, completionBlock: block)
                }
            }
        }
        // new change
        else if data.metadata.lastChange.operationIndex == Data.wildcardIndex
        {
            nextOperationIndex(forSite: data.metadata.lastChange.siteID)
            {
                switch $0
                {
                case .error(let e):
                    block(e)
                case .value(let idx):
                    var previousData: DataModel? = nil
                    var error: Error?
                    synced
                    { done in
                        self.data(forID: data.metadata.id)
                        {
                            defer { done() }
                            switch $0
                            {
                            case .error(let e):
                                error = e
                            case .value(let v):
                                previousData = v
                            }
                        }
                    }
                    if let error = error { block(error); return; }
                    
                    if let previousData = previousData
                    {
                        var newData = previousData
                        newData.merge(with: data)
                        newData.metadata.lastChange = GlobalID.init(siteID: data.metadata.lastChange.siteID, operationIndex: idx)

                        let opLog = [newData.metadata.lastChange.siteID:(idx,[newData.metadata.id])]
                        self.syncInSequence(data: Set([newData]), withOperationLog: opLog, completionBlock: block)
                    }
                    else
                    {
                        block(DataError.missingPreceedingOperations)
                    }
                }
            }
        }
        // synced operation
        else
        {
            block(DataError.wrongSyncCommitChoice)
        }
    }
    
    // PERF: slow
    public func commit(data: Set<DataModel>, withCompletionBlock block: @escaping (Error?)->())
    {
        for datum in data
        {
            if !(datum.metadata.id.operationIndex == Data.wildcardIndex || datum.metadata.lastChange.operationIndex == Data.wildcardIndex)
            {
                block(DataError.wrongSyncCommitChoice)
                return
            }
        }
        
        for item in data
        {
            let group = DispatchGroup()
            group.enter()
            
            var error: Error? = nil
            
            self.commit(data: item)
            { e in
                error = e
                group.leave()
            }
            
            group.wait()
            
            if let e = error
            {
                block(e)
                return
            }
        }
        
        block(nil)
    }
}
