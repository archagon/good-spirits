//
//  Model_GRDB.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-13.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import GRDB

protocol TableCreatable
{
    static func createTable(withTableDefinition: TableDefinition)
}

// --------------------
// MARK: - Data Model -
// --------------------

extension DrinkStyle: DatabaseValueConvertible {}

extension DataModel
{
    enum Columns: String, ColumnExpression
    {
        case metadata_id_uuid, metadata_id_index, metadata_creation_time, checkin_untappd_id_value, checkin_untappd_id_lamport, checkin_time_value, checkin_time_lamport, checkin_drink_name_value, checkin_drink_name_lamport, checkin_drink_style_value, checkin_drink_style_lamport, checkin_drink_abv_value, checkin_drink_abv_lamport, checkin_drink_price_value, checkin_drink_price_lamport, checkin_drink_volume_value_value, checkin_drink_volume_value_unit, checkin_drink_volume_lamport
        
        // https://medium.com/@derrickho_28266/iterate-over-swift-enums-1c251cd28a1c
        static var allCases: [Columns]
        {
            var out: [Columns] = []
            
            switch Columns.metadata_id_uuid
            {
            case .metadata_id_uuid: out.append(.metadata_id_uuid); fallthrough
            case .metadata_id_index: out.append(.metadata_id_index); fallthrough
            case .metadata_creation_time: out.append(.metadata_creation_time); fallthrough
            case .checkin_untappd_id_value: out.append(.checkin_untappd_id_value); fallthrough
            case .checkin_untappd_id_lamport: out.append(.checkin_untappd_id_lamport); fallthrough
            case .checkin_time_value: out.append(.checkin_time_value); fallthrough
            case .checkin_time_lamport: out.append(.checkin_time_lamport); fallthrough
            case .checkin_drink_name_value: out.append(.checkin_drink_name_value); fallthrough
            case .checkin_drink_name_lamport: out.append(.checkin_drink_name_lamport); fallthrough
            case .checkin_drink_style_value: out.append(.checkin_drink_style_value); fallthrough
            case .checkin_drink_style_lamport: out.append(.checkin_drink_style_lamport); fallthrough
            case .checkin_drink_abv_value: out.append(.checkin_drink_abv_value); fallthrough
            case .checkin_drink_abv_lamport: out.append(.checkin_drink_abv_lamport); fallthrough
            case .checkin_drink_price_value: out.append(.checkin_drink_price_value); fallthrough
            case .checkin_drink_price_lamport: out.append(.checkin_drink_price_lamport); fallthrough
            case .checkin_drink_volume_value_value: out.append(.checkin_drink_volume_value_value); fallthrough
            case .checkin_drink_volume_value_unit: out.append(.checkin_drink_volume_value_unit); fallthrough
            case .checkin_drink_volume_lamport: out.append(.checkin_drink_volume_lamport)
            }
            
            return out
        }
        
        var isLamport: Bool
        {
            switch self
            {
            case .metadata_id_uuid: fallthrough
            case .metadata_id_index: fallthrough
            case .metadata_creation_time: fallthrough
            case .checkin_untappd_id_value: fallthrough
            case .checkin_time_value: fallthrough
            case .checkin_drink_name_value: fallthrough
            case .checkin_drink_style_value: fallthrough
            case .checkin_drink_abv_value: fallthrough
            case .checkin_drink_price_value: fallthrough
            case .checkin_drink_volume_value_value: fallthrough
            case .checkin_drink_volume_value_unit:
                return false

            case .checkin_untappd_id_lamport: fallthrough
            case .checkin_time_lamport: fallthrough
            case .checkin_drink_name_lamport: fallthrough
            case .checkin_drink_style_lamport: fallthrough
            case .checkin_drink_abv_lamport: fallthrough
            case .checkin_drink_price_lamport: fallthrough
            case .checkin_drink_volume_lamport:
                return true
            }
        }
    }
}

extension DataModel: TableCreatable
{
    public static func createTable(withTableDefinition td: TableDefinition)
    {
        for item in Columns.allCases
        {
            switch item
            {
            case .metadata_id_uuid:
                td.column(item.rawValue, .text).notNull()
            case .metadata_id_index:
                td.column(item.rawValue, .integer).notNull()
            case .metadata_creation_time:
                td.column(item.rawValue, .double).notNull()
            case .checkin_untappd_id_value:
                td.column(item.rawValue, .integer)
            case .checkin_untappd_id_lamport:
                td.column(item.rawValue, .integer).notNull()
            case .checkin_time_value:
                td.column(item.rawValue, .double).notNull()
            case .checkin_time_lamport:
                td.column(item.rawValue, .integer).notNull()
            case .checkin_drink_name_value:
                td.column(item.rawValue, .text)
            case .checkin_drink_name_lamport:
                td.column(item.rawValue, .integer).notNull()
            case .checkin_drink_style_value:
                td.column(item.rawValue, .text).notNull()
            case .checkin_drink_style_lamport:
                td.column(item.rawValue, .integer).notNull()
            case .checkin_drink_abv_value:
                td.column(item.rawValue, .double).notNull()
            case .checkin_drink_abv_lamport:
                td.column(item.rawValue, .integer).notNull()
            case .checkin_drink_price_value:
                td.column(item.rawValue, .double)
            case .checkin_drink_price_lamport:
                td.column(item.rawValue, .integer).notNull()
            case .checkin_drink_volume_value_value:
                td.column(item.rawValue, .double).notNull()
            case .checkin_drink_volume_value_unit:
                td.column(item.rawValue, .text).notNull()
            case .checkin_drink_volume_lamport:
                td.column(item.rawValue, .integer).notNull()
            }
        }
        
        td.primaryKey([Columns.metadata_id_uuid.rawValue, Columns.metadata_id_index.rawValue])
    }
}

extension DataModel: FetchableRecord
{
    public init(row: Row)
    {
        let idSiteId: String = row[Columns.metadata_id_uuid]
        let idIndex: DataLayer.Index = row[Columns.metadata_id_index]
        let id = GlobalID.init(siteID: DataLayer.SiteID.init(uuidString: idSiteId)!, operationIndex: idIndex)
        let creationTime: Double = row[Columns.metadata_creation_time]
        let metadata = Metadata.init(id: id, creationTime: creationTime)
        
        let nameValue: String? = row[Columns.checkin_drink_name_value]
        let nameLamport: DataLayer.Time = row[Columns.checkin_drink_name_lamport]
        let name = LamportValue.init(v: nameValue, t: nameLamport)
        let styleValue: DrinkStyle = row[Columns.checkin_drink_style_value]
        let styleLamport: DataLayer.Time = row[Columns.checkin_drink_style_lamport]
        let style = LamportValue.init(v: styleValue, t: styleLamport)
        let abvValue: Double = row[Columns.checkin_drink_abv_value]
        let abvLamport: DataLayer.Time = row[Columns.checkin_drink_abv_lamport]
        let abv = LamportValue.init(v: abvValue, t: abvLamport)
        let priceValue: Double? = row[Columns.checkin_drink_price_value]
        let priceLamport: DataLayer.Time = row[Columns.checkin_drink_price_lamport]
        let price = LamportValue.init(v: priceValue, t: priceLamport)
        let volumeValueValue: Double = row[Columns.checkin_drink_volume_value_value]
        let volumeValueUnit: String = row[Columns.checkin_drink_volume_value_unit]
        let volumeLamport: DataLayer.Time = row[Columns.checkin_drink_volume_lamport]
        let volumeValue = Measurement<UnitVolume>.init(value: volumeValueValue, unit: UnitVolume.unit(withSymbol: volumeValueUnit))
        let volume = LamportValue.init(v: volumeValue, t: volumeLamport)
        let drink = Drink.init(name: name, style: style, abv: abv, price: price, volume: volume)
        
        let untappdIdValue: ID? = row[Columns.checkin_untappd_id_value]
        let untappdIdLamport: DataLayer.Time = row[Columns.checkin_untappd_id_lamport]
        let untappdId = LamportValue.init(v: untappdIdValue, t: untappdIdLamport)
        let timeValue: Double = row[Columns.checkin_time_value]
        let timeLamport: DataLayer.Time = row[Columns.checkin_time_lamport]
        let time = LamportValue.init(v: timeValue, t: timeLamport)
        let checkIn = CheckIn.init(untappdId: untappdId, time: time, drink: drink)
        
        self.metadata = metadata
        self.checkIn = checkIn
    }
}

extension DataModel: PersistableRecord
{
    public func encode(to container: inout PersistenceContainer)
    {
        for item in Columns.allCases
        {
            switch item
            {
            case .metadata_id_uuid:
                container[item] = self.metadata.id.siteID.uuidString
            case .metadata_id_index:
                container[item] = self.metadata.id.operationIndex
            case .metadata_creation_time:
                container[item] = self.metadata.creationTime
            case .checkin_untappd_id_value:
                container[item] = self.checkIn.untappdId.v
            case .checkin_untappd_id_lamport:
                container[item] = self.checkIn.untappdId.t
            case .checkin_time_value:
                container[item] = self.checkIn.time.v
            case .checkin_time_lamport:
                container[item] = self.checkIn.time.t
            case .checkin_drink_name_value:
                container[item] = self.checkIn.drink.name.v
            case .checkin_drink_name_lamport:
                container[item] = self.checkIn.drink.name.t
            case .checkin_drink_style_value:
                container[item] = self.checkIn.drink.style.v
            case .checkin_drink_style_lamport:
                container[item] = self.checkIn.drink.style.t
            case .checkin_drink_abv_value:
                container[item] = self.checkIn.drink.abv.v
            case .checkin_drink_abv_lamport:
                container[item] = self.checkIn.drink.abv.t
            case .checkin_drink_price_value:
                container[item] = self.checkIn.drink.price.v
            case .checkin_drink_price_lamport:
                container[item] = self.checkIn.drink.price.t
            case .checkin_drink_volume_value_value:
                container[item] = self.checkIn.drink.volume.v.value
            case .checkin_drink_volume_value_unit:
                container[item] = self.checkIn.drink.volume.v.unit.symbol
            case .checkin_drink_volume_lamport:
                container[item] = self.checkIn.drink.volume.t
            }
        }
    }
    
    //public func didInsert(with rowID: Int64, for column: String?)
    //public func insert(_ db: Database) throws
    //public func save(_ db: Database) throws
}

extension DataModel: TableRecord
{
    public static var databaseTableName: String = "data"
    //public static var databaseSelection: [SQLSelectable]
}

// ------------------------------
// MARK: - Data Model Log Entry -
// ------------------------------

extension DataModelLogEntry
{
    enum Columns: String, ColumnExpression
    {
        case action_uuid, action_index, operation_uuid, operation_index
        
        // https://medium.com/@derrickho_28266/iterate-over-swift-enums-1c251cd28a1c
        static var allCases: [Columns]
        {
            var out: [Columns] = []
            
            switch Columns.action_uuid
            {
            case .action_uuid: out.append(.action_uuid); fallthrough
            case .action_index: out.append(.action_index); fallthrough
            case .operation_uuid: out.append(.operation_uuid); fallthrough
            case .operation_index: out.append(.operation_index)
            }
            
            return out
        }
    }
}

extension DataModelLogEntry: TableCreatable
{
    public static func createTable(withTableDefinition td: TableDefinition)
    {
        for item in Columns.allCases
        {
            switch item
            {
            case .action_uuid:
                td.column(item.rawValue, .text).notNull()
            case .action_index:
                td.column(item.rawValue, .integer).notNull()
            case .operation_uuid:
                td.column(item.rawValue, .text).notNull()
            case .operation_index:
                td.column(item.rawValue, .integer).notNull()
            }
        }
        
        td.foreignKey([Columns.operation_uuid.rawValue, Columns.operation_index.rawValue], references: DataModel.databaseTableName, columns: [DataModel.Columns.metadata_id_uuid.rawValue, DataModel.Columns.metadata_id_index.rawValue], onDelete: nil, onUpdate: nil, deferred: false)
    }
}

extension DataModelLogEntry: FetchableRecord
{
    public init(row: Row)
    {
        let site: String = row[Columns.action_uuid]
        let index: DataLayer.Index = row[Columns.action_index]
        let operationSite: String = row[Columns.operation_uuid]
        let operationIndex: DataLayer.Index = row[Columns.operation_index]
        let operation = GlobalID.init(siteID: DataLayer.SiteID.init(uuidString: operationSite)!, operationIndex: operationIndex)
        
        self.site = DataLayer.SiteID.init(uuidString: site)!
        self.index = index
        self.operation = operation
    }
}

extension DataModelLogEntry: PersistableRecord
{
    public func encode(to container: inout PersistenceContainer)
    {
        for item in Columns.allCases
        {
            switch item
            {
            case .action_uuid:
                container[item] = self.site.uuidString
            case .action_index:
                container[item] = self.index
            case .operation_uuid:
                container[item] = self.operation.siteID.uuidString
            case .operation_index:
                container[item] = self.operation.operationIndex
            }
        }
    }
    
    //public func didInsert(with rowID: Int64, for column: String?)
    //public func insert(_ db: Database) throws
    //public func save(_ db: Database) throws
}

extension DataModelLogEntry: TableRecord
{
    public static var databaseTableName: String = "log"
    //public static var databaseSelection: [SQLSelectable]
}
