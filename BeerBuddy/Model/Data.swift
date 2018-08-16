//
//  Data.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

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
            appError("could not generate date")
            return (Date.distantPast, Date.distantFuture)
        }
        guard let newEndOfWeek = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: endOfWeek) else
        {
            appError("could not generate date")
            return (Date.distantPast, Date.distantFuture)
        }
        
        dump(newStartOfWeek)
        dump(newEndOfWeek)
        
        return (newStartOfWeek, newEndOfWeek)
    }
}

public enum DataImplGenericError: Error
{
    case fileNotFound(path: String)
    case fileIllegible(path: String)
    case invalidFieldFormat(field: String)
    case readOnly
    case writeFailed
}
