//
//  Model_SQL.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-9.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

extension DataModel
{
    public static let sqlPropertyMapping: [(path: PartialKeyPath<DataModel>, name: String, type: String, nullable: Bool)] =
    [
        (\DataModel.metadata.id.siteID.uuidString, "metadata_id_uuid", "TEXT", false),
        (\DataModel.metadata.id.operationIndex, "metadata_id_index", "INTEGER", false),
        (\DataModel.metadata.lastChange.siteID.uuidString, "metadata_last_change_uuid", "TEXT", false),
        (\DataModel.metadata.lastChange.operationIndex, "metadata_last_change_index", "INTEGER", false),
        (\DataModel.metadata.creationTime, "metadata_creation_time", "REAL", false),
        (\DataModel.checkIn.untappdId.v, "checkin_untappd_id", "INTEGER", true),
        (\DataModel.checkIn.time.v, "checkin_time", "REAL", false),
        (\DataModel.checkIn.drink.name.v, "checkin_drink_name", "TEXT", true),
        (\DataModel.checkIn.drink.style.v.rawValue, "checkin_drink_style", "TEXT", false),
        (\DataModel.checkIn.drink.abv.v, "checkin_drink_abv", "REAL", false),
        (\DataModel.checkIn.drink.price.v, "checkin_drink_price", "REAL", true),
        (\DataModel.checkIn.drink.volume.v.value, "checkin_drink_volume_value", "REAL", false),
        (\DataModel.checkIn.drink.volume.v.unit.symbol, "checkin_drink_volume_type", "TEXT", false),
    ]
    public static let sqlLamportMapping: [(path: PartialKeyPath<DataModel>, name: String, type: String, nullable: Bool)] =
    [
        (\DataModel.metadata.id.siteID.uuidString, "metadata_id_uuid", "TEXT", false),
        (\DataModel.metadata.id.operationIndex, "metadata_id_index", "INTEGER", false),
        (\DataModel.checkIn.untappdId.lamport, "checkin_untappd_id_lamport", "INTEGER", false),
        (\DataModel.checkIn.time.lamport, "checkin_time_lamport", "INTEGER", false),
        (\DataModel.checkIn.drink.name.lamport, "checkin_drink_name_lamport", "INTEGER", false),
        (\DataModel.checkIn.drink.style.lamport, "checkin_drink_style_lamport", "INTEGER", false),
        (\DataModel.checkIn.drink.abv.lamport, "checkin_drink_abv_lamport", "INTEGER", false),
        (\DataModel.checkIn.drink.price.lamport, "checkin_drink_price_lamport", "INTEGER", false),
        (\DataModel.checkIn.drink.volume.lamport, "checkin_drink_volume_lamport", "INTEGER", false),
    ]
    public static var sqlLamportMappingWithoutForeignKeys = DataModel.sqlLamportMapping[2..<DataModel.sqlLamportMapping.count]
    
    public static func sqlValueSchemaStatement() -> String
    {
        var schemaEntries: [String] = []
        
        for tuple in DataModel.sqlPropertyMapping
        {
            schemaEntries.append("\(tuple.name) \(tuple.type)\(tuple.nullable ? "" : " NOT NULL")")
        }
        schemaEntries.append("PRIMARY KEY (metadata_id_uuid, metadata_id_index)")
        
        var schema = "(\n"
        for (i, entry) in schemaEntries.enumerated()
        {
            schema += "\(entry)\(i == schemaEntries.count - 1 ? "\n" : ",\n")"
        }
        schema += ")"
        
        return schema
    }
    
    public static func sqlLamportSchemaStatement() -> String
    {
        var schemaEntries: [String] = []
        
        for tuple in DataModel.sqlLamportMapping
        {
            schemaEntries.append("\(tuple.name) \(tuple.type)\(tuple.nullable ? "" : " NOT NULL")")
        }
        // TODO: this does not belong here
        schemaEntries.append("FOREIGN KEY (metadata_id_uuid, metadata_id_index) REFERENCES data (metadata_id_uuid, metadata_id_index)")
        
        var schema = "(\n"
        for (i, entry) in schemaEntries.enumerated()
        {
            schema += "\(entry)\(i == schemaEntries.count - 1 ? "\n" : ",\n")"
        }
        schema += ")"
        
        return schema
    }
    
    public func sqlRowValues() -> [Any]
    {
        let tuples = DataModel.sqlPropertyMapping
        var values: [Any] = []
        
        for tuple in tuples
        {
            let value = self[keyPath: tuple.path]
            values.append(value)
        }
        
        return values
    }
    
    public func sqlLamportRowValues() -> [Any]
    {
        let tuples = DataModel.sqlLamportMapping
        var values: [Any] = []
        
        for tuple in tuples
        {
            let value = self[keyPath: tuple.path]
            values.append(value)
        }
        
        return values
    }
}
