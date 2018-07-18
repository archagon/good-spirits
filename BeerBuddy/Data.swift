//
//  Data.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

// Data interface. Efficient transactions & queries. Actual backing code is abstracted away.
public class Data <T: DataImpl>
{
    private var impl: T
    private var cache: [Model.ID:Model.CheckIn] = [:]
    
    public init(impl: T)
    {
        self.impl = impl
    }
    
    public func checkins(from: Date, to: Date) throws -> [Model.CheckIn]
    {
        let checkins = try self.impl.checkins(from: from, to: to)
        
        updateCache(checkins)
        
        return checkins
    }
    
    public func checkin(withId id: Model.ID) throws -> Model.CheckIn?
    {
        return try tryCache(id)
    }
    
    public func addCheckin(_ checkin: Model.CheckIn) throws
    {
        let newCheckin = try self.impl.addCheckin(checkin)
        
        self.cache[checkin.id] = nil
        self.cache[newCheckin.id] = newCheckin
    }
    
    public func deleteCheckin(withId id: Model.ID) throws
    {
        try self.impl.deleteCheckin(withId: id)
        
        self.cache[id] = nil
    }
    
    public func updateCheckin(_ checkin: Model.CheckIn) throws
    {
        let newCheckin = try self.impl.updateCheckin(checkin)
        
        self.cache[checkin.id] = nil
        self.cache[newCheckin.id] = newCheckin
    }
    
    private func tryCache(_ id: Model.ID) throws -> Model.CheckIn?
    {
        if let checkin = self.cache[id]
        {
            return checkin
        }
        else
        {
            let checkin = try self.impl.checkin(withId: id)
            
            self.cache[id] = nil
            if let checkin = checkin
            {
                self.cache[checkin.id] = checkin
            }
            
            return checkin
        }
    }
    
    private func updateCache(_ checkins: [Model.CheckIn])
    {
        for checkin in checkins
        {
            self.cache[checkin.id] = checkin
        }
    }
}

// Low-level data storage/retreival interface. Strictly mechanical, not many business logic smarts.
public protocol DataImpl
{
    // Includes from, excludes to. Accepts distantPast and distantFuture as parameters.
    func checkins(from: Date, to: Date) throws -> [Model.CheckIn]
    
    func checkin(withId id: Model.ID) throws -> Model.CheckIn?
    func addCheckin(_ checkin: Model.CheckIn) throws -> Model.CheckIn
    func deleteCheckin(withId id: Model.ID) throws
    func updateCheckin(_ checkin: Model.CheckIn) throws -> Model.CheckIn
}

public enum DataImplGenericError: Error
{
    case fileNotFound(path: String)
    case fileIllegible(path: String)
    case invalidFieldFormat(field: String)
    case readOnly
    case writeFailed
}
