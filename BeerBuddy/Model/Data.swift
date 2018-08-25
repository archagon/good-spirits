//
//  Data.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import DataLayer

class Time
{
    public static func currentWeek() -> (Date, Date)
    {
        let calendar = DataLayer.calendar
        
        let date = Date()
        //let components = DateComponents.init(calendar: calendar, timeZone: TimeZone.init(abbreviation: "PST"), era: nil, year: 2018, month: 7, day: 14, hour: nil, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        //let date = calendar.date(from: components)!
        
        let startDay = Defaults.weekStartsOnMonday ? Weekday.monday : Weekday.sunday
        let startOfWeek = calendar.next(startDay, from: date, direction: .backward, considerToday: true)
        let endOfWeek = calendar.next(startDay, from: date, direction: .forward, considerToday: false)
        
        guard let newStartOfWeek = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: startOfWeek) else
        {
            appError("could not generate date")
            return (Date(), Date())
        }
        guard let newEndOfWeek = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: endOfWeek) else
        {
            appError("could not generate date")
            return (Date(), Date())
        }
        
        return (newStartOfWeek, newEndOfWeek)
    }
}
