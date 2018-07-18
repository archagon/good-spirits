//
//  DataJSON.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

// This class is assumed to be the sole owner of the JSON file. No outside entities may edit it.
public class DataImpl_JSON: DataImpl
{
    private let url: URL
    private var _data: RootFormat? //use fetchData to get the data
    
    public init?(withURL url: URL)
    {
        if !FileManager.default.fileExists(atPath: url.path)
        {
            return nil
        }
        
        self.url = url
    }
    
    // PERF: O(AllCheckIns), inefficient
    public func checkins(from: Date, to: Date) throws -> [Model.CheckIn]
    {
        assert(from <= to)
        
        try verifyExists()
        
        var checkins = try allCheckIns()
        checkins = checkins.filter { return from <= $0.time && $0.time < to }
        
        return checkins
    }
    
    // PERF: O(AllCheckIns), inefficient
    public func checkin(withId id: Model.ID) throws -> Model.CheckIn?
    {
        try verifyExists()
        
        let checkins = try allCheckIns()
        
        for checkin in checkins
        {
            if checkin.id == id
            {
                return checkin
            }
        }
        
        return nil
    }
    
    public func addCheckin(_ checkin: Model.CheckIn) throws
    {
        try verifyExists()
        
        throw DataImplGenericError.readOnly
    }
    
    public func deleteCheckin(withId id: Model.ID) throws
    {
        try verifyExists()
        
        throw DataImplGenericError.readOnly
    }
    
    public func updateCheckin(_ checkin: Model.CheckIn) throws
    {
        try verifyExists()
        
        throw DataImplGenericError.readOnly
    }
    
    // TODO: remove once more performant fetch functions are implemented
    private func allCheckIns() throws -> [Model.CheckIn]
    {
        let data = try fetchData()
        
        var out: [Model.CheckIn] = []
        
        for item in data.checkins
        {
            guard let style = DataImpl_JSON.drinkTypeMap[item.drink_type] else
            {
                throw DataImplGenericError.invalidFieldFormat(field: "drinkType")
            }
            
            // TODO: include locale
            let formatter = DateFormatter.init()
            formatter.dateFormat = DataImpl_JSON.dateFormat
            guard let time = formatter.date(from: item.checkin_time) else
            {
                throw DataImplGenericError.invalidFieldFormat(field: "checkInTime")
            }
            
            let volume = try DataImpl_JSON.volume(forUnit: item.drink_volume_unit, value: item.drink_volume)
            let drink = Model.Drink.init(name: item.drink_name, style: style, abv: item.drink_abv, price: item.drink_price, volume: volume)
            let checkin = Model.CheckIn.init(id: item.checkin_id, untappdId: item.untappd_checkin_id, time: time, drink: drink)
            
            out.append(checkin)
        }
        
        return out
    }
    
    private func verifyExists() throws
    {
        if !FileManager.default.fileExists(atPath: self.url.path)
        {
            throw DataImplGenericError.fileNotFound(path: self.url.path)
        }
    }
    
    private func fetchData() throws -> RootFormat
    {
        if self._data == nil
        {
            guard let fileData = FileManager.default.contents(atPath: self.url.path) else
            {
                throw DataImplGenericError.fileNotFound(path: self.url.path)
            }
            
            do
            {
                let jsonData = try JSONDecoder.init().decode(RootFormat.self, from: fileData)
                self._data = jsonData
            }
            catch
            {
                throw DataImplGenericError.fileIllegible(path: self.url.path)
            }
        }
        
        return self._data!
    }
}

// JSON to model mapping.
private extension DataImpl_JSON
{
    private struct RootFormat: Codable
    {
        public let checkins: [CheckinFormat]
    }
    
    private struct CheckinFormat: Codable
    {
        public let checkin_id: UInt64
        public let untappd_checkin_id: UInt64?
        public let checkin_time: String
        public let drink_name: String?
        public let drink_type: String
        public let drink_abv: Double
        public let drink_price: Double?
        public let drink_volume: Double
        public let drink_volume_unit: String
    }
    
    private static var drinkTypeMap: [String:Model.Drink.Style] =
    [
        "beer":.beer,
        "sake":.sake,
        "wine":.wine
    ]
    
    private static var dateFormat: String = "E, d MMM yyyy HH:mm:ss Z"
    
    private static func volume(forUnit unit: String, value: Double) throws -> Model.Volume
    {
        if unit == "floz"
        {
            return Model.Volume.fluidOunces(v: value)
        }
        else if unit == "ml"
        {
            return Model.Volume.mililiters(v: value)
        }
        else
        {
            throw DataImplGenericError.invalidFieldFormat(field: "volume")
        }
    }
}
