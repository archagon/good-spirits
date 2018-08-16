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
    
    public init?()
    {
        let path: String? = (NSTemporaryDirectory() as NSString).appendingPathComponent("\(UUID()).db")
        
        do
        {
            var configuration = Configuration.init()
            //#if DEBUG
            //configuration.trace = { print($0) }
            //#endif
            
            self.database = try DatabaseQueue.init(path: path ?? "", configuration: configuration)
            self.queue = DispatchQueue.init(label: "GRDBQueue", qos: .default, attributes: [], autoreleaseFrequency: .inherit, target: nil)
            
            print("database path: \(path ?? "<null>")")
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

extension Data_GRDB: DataAccessProtocol
{
    public func initialize(_ block: @escaping (Error?)->Void)
    {
        self.database.write
        { db in
            do
            {
                try db.create(table: DataModel.databaseTableName, temporary: false, ifNotExists: true, withoutRowID: true)
                { td in
                    DataModel.createTable(withTableDefinition: td)
                }
                try db.create(index: "dateIndex", on: DataModel.databaseTableName, columns: [DataModel.Columns.checkin_time_value.rawValue])
                let allLamportColumns = DataModel.Columns.allCases.filter { $0.isLamport }
                for (_, column) in allLamportColumns.enumerated()
                {
                    // TODO: is this correct?
                    try db.create(index: "max\(column.rawValue.underscoreToCamelCase.capitalizedFirstLetter)Index", on: DataModel.databaseTableName, columns: ["MAX(\(column.rawValue))"])
                }
                
                try db.create(table: DataModelLogEntry.databaseTableName, temporary: false, ifNotExists: true, withoutRowID: false)
                { td in
                    DataModelLogEntry.createTable(withTableDefinition: td)
                }
                try db.create(index: "logIndex", on: DataModelLogEntry.databaseTableName, columns: [DataModelLogEntry.Columns.action_uuid.rawValue, DataModelLogEntry.Columns.action_index.rawValue])
                
                block(nil)
            }
            catch
            {
                block(error)
            }
        }
    }
    
    
    //DispatchQueue.global().async {
    //dbQueue.write { db in
    //// Perform database work
    //}
    //DispatchQueue.main.async {
    //// update your user interface
    //}
    //}
    
    public func readTransaction(_ block: @escaping (_ data: DataProtocol)->())
    {
        // NEXT: make custom thrown errors work
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
}

extension Data_GRDB: DataDebugProtocol
{
    public func _asserts()
    {
    }
}
