//
//  Data_GRDB.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-8.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import GRDB

public class Data_GRDB
{
    let database: DatabaseQueue
    let queue: DispatchQueue
    
    public init?(withDatabasePath path: String? = nil)
    {
        let path: String? = path
        
        do
        {
            var configuration = Configuration.init()
            //#if DEBUG
            //configuration.trace = { print($0) }
            //#endif
            
            self.database = try DatabaseQueue.init(path: path ?? "", configuration: configuration)
            self.queue = DispatchQueue.init(label: "GRDBQueue", qos: .default, attributes: [], autoreleaseFrequency: .inherit, target: nil)
            
            print("Database path: \(path ?? "<null>")")
        }
        catch
        {
            return nil
        }
    }
    
    public func explain<T>(request: QueryInterfaceRequest<T>) throws
    {
        try self.database.inDatabase
        { db in
            try db.explain(request: request)
        }
    }
}

extension Data_GRDB: DataObservationProtocol, TransactionObserver
{
    public static var DataDidChangeNotification: Notification.Name = Notification.Name.init(rawValue: "GRDBDataDidChangeNotification")
 
    public func observes(eventsOfKind eventKind: DatabaseEventKind) -> Bool
    {
        return true
    }
    
    public func databaseDidChange(with event: DatabaseEvent)
    {
        //NotificationCenter.default.post(name: Data_GRDB.DataDidChangeNotification, object: self)
        //self.stopObservingDatabaseChangesUntilNextTransaction()
    }
    
    public func databaseDidCommit(_ db: Database)
    {
        NotificationCenter.default.post(name: Data_GRDB.DataDidChangeNotification, object: self)
    }
    
    public func databaseDidRollback(_ db: Database)
    {
    }
}

extension Data_GRDB: DataAccessProtocol, DataAccessProtocolImmediate
{
    public func initialize() throws
    {
        try self.database.write
        { db in
            try db.create(table: DataModel.databaseTableName, temporary: false, ifNotExists: true, withoutRowID: true)
            { td in
                DataModel.createTable(withTableDefinition: td)
            }
            try db.create(index: "dateIndex", on: DataModel.databaseTableName, columns: [DataModel.Columns.checkin_time_value.rawValue])
            // TODO: does the untappd portion actually help?
            try db.create(index: "creationTimeIndex", on: DataModel.databaseTableName, columns: [DataModel.Columns.metadata_creation_time.rawValue, DataModel.Columns.checkin_untappd_id_value.rawValue])
            let allLamportColumns = DataModel.Columns.allCases.filter { $0.isLamport }
            // TODO: maybe make this a compound index? also, how does max work on compound index?
            for (_, column) in allLamportColumns.enumerated()
            {
                try db.create(index: "\(column.rawValue.underscoreToCamelCase)Index", on: DataModel.databaseTableName, columns: [column.rawValue])
            }
            
            try db.create(table: DataModelLogEntry.databaseTableName, temporary: false, ifNotExists: true, withoutRowID: false)
            { td in
                DataModelLogEntry.createTable(withTableDefinition: td)
            }
            try db.create(index: "logIndex", on: DataModelLogEntry.databaseTableName, columns: [DataModelLogEntry.Columns.action_uuid.rawValue, DataModelLogEntry.Columns.action_index.rawValue])
            
            db.add(transactionObserver: self)
        }
    }
    
    public func readTransaction(_ block: @escaping (_ data: DataProtocol)->())
    {
        self.queue.async
        {
            do
            {
                try self.database.read
                { db in
                    block(db)
                }
            }
            catch
            {
            }
        }
    }
    
    public func readTransaction<T>(_ block: @escaping (_ data: DataProtocolImmediate) throws -> T) rethrows -> T
    {
        return try self.database.read
        { db in
            return try block(db)
        }
    }
    
    public func readWriteTransaction(_ block: @escaping (_ data: DataWriteProtocol)->())
    {
        self.queue.async
        {
            do
            {
                try self.database.write
                { db in
                    block(db)
                }
            }
            catch
            {
            }
        }
    }
    
    public func readWriteTransaction<T>(_ block: @escaping (_ data: DataWriteProtocolImmediate) throws -> T) rethrows -> T
    {
        return try self.database.write
        { db in
            return try block(db)
        }
    }
}

extension Data_GRDB: DataDebugProtocol
{
    public func _asserts()
    {
    }
}
