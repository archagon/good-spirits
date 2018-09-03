//
//  Time.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//
//  This file is part of Good Spirits.
//
//  Good Spirits is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Good Spirits is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation
import DataLayer

class Time
{
    public static func currentWeek() -> (Date, Date)
    {
        return week(forDate: Date())
    }
    
    public static func week(forDate date: Date) -> (Date, Date)
    {
        let calendar = DataLayer.calendar
        
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
