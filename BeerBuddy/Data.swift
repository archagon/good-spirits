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
    public typealias Week = Date
    
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

class Time
{
    public static func daysOfWeek() -> [Weekday]
    {
        if Defaults.weekStartsOnMonday
        {
            return [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
        }
        else
        {
            return [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        }
    }
    
    public static func calendar() -> Calendar
    {
        // TODO: other calendars?
        let calendar = Calendar.init(identifier: .gregorian)
        return calendar
    }
    
    public static func currentWeek() -> (Date, Date)
    {
        let calendar = Time.calendar()
        
        // QQQ:
        //let date = Date()
        let components = DateComponents.init(calendar: calendar, timeZone: TimeZone.init(abbreviation: "PST"), era: nil, year: 2018, month: 7, day: 14, hour: nil, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        let date = calendar.date(from: components)!
        
        let startDay = Defaults.weekStartsOnMonday ? Weekday.monday : Weekday.sunday
        let startOfWeek = calendar.next(startDay, from: date, direction: .backward, considerToday: true)
        let endOfWeek = calendar.next(startDay, from: date, direction: .forward, considerToday: false)
        
        guard let newStartOfWeek = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: startOfWeek) else
        {
            error("could not generate date")
            return (Date.distantPast, Date.distantFuture)
        }
        guard let newEndOfWeek = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: endOfWeek) else
        {
            error("could not generate date")
            return (Date.distantPast, Date.distantFuture)
        }
        
        dump(newStartOfWeek)
        dump(newEndOfWeek)
        
        return (newStartOfWeek, newEndOfWeek)
    }
}

// Low-level data storage/retreival interface. Strictly mechanical, not many business logic smarts.
public protocol DataImpl
{
    // Includes from, excludes to. Accepts distantPast and distantFuture as parameters. Sorted chronologically.
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
