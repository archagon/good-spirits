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
        return checkins
    }
    
    public func checkin(withId id: Model.ID) throws -> Model.CheckIn?
    {
        let checkin = try self.impl.checkin(withId: id)
        return checkin
    }
    
    public func addCheckin(_ checkin: Model.CheckIn) throws
    {
        try self.impl.addCheckin(checkin)
    }
    
    public func deleteCheckin(withId id: Model.ID) throws
    {
        try self.impl.deleteCheckin(withId: id)
    }
    
    public func updateCheckin(_ checkin: Model.CheckIn) throws
    {
        try self.impl.updateCheckin(checkin)
    }
}

// Low-level data storage/retreival interface. Strictly mechanical, not many business logic smarts.
public protocol DataImpl
{
    // Includes from, excludes to. Accepts distantPast and distantFuture as parameters.
    func checkins(from: Date, to: Date) throws -> [Model.CheckIn]
    
    func checkin(withId id: Model.ID) throws -> Model.CheckIn?
    func addCheckin(_ checkin: Model.CheckIn) throws
    func deleteCheckin(withId id: Model.ID) throws
    func updateCheckin(_ checkin: Model.CheckIn) throws
}

public enum DataImplGenericError: Error
{
    case fileNotFound(path: String)
    case fileIllegible(path: String)
    case invalidFieldFormat(field: String)
    case readOnly
    case writeFailed
}
