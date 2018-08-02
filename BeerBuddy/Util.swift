//
//  Util.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-18.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public func equalish<T: Dimension>(first: Measurement<T>, second: Measurement<T>, delta: Measurement<T>) -> Bool
{
    let baseFirst = first.converted(to: T.baseUnit())
    let baseSecond = second.converted(to: T.baseUnit())
    var baseDelta = delta.converted(to: T.baseUnit())
    
    if baseDelta.value < 0
    {
        baseDelta = baseDelta * -1
    }
    
    var diff = baseFirst - baseSecond

    if diff.value < 0
    {
        diff = diff * -1
    }
    
    return diff <= baseDelta
}

// TODO: log this and do something sensible
public func appError(_ message: String)
{
    print("Error: \(message)")
    assert(false)
}

public func appDebug(_ message: String)
{
    #if DEBUG
    print("🔵 \(message)")
    #endif
}

// https://stackoverflow.com/a/49561764/89812
public enum Weekday: Int
{
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    
    public init?(fromDate date: Date, withCalendar calendar: Calendar)
    {
        if let val = Weekday.init(rawValue: calendar.component(.weekday, from: date))
        {
            self = val
        }
        else
        {
            return nil
        }
    }
}
extension Calendar
{
    public func next(_ weekday: Weekday,
                     from date: Date,
                     direction: Calendar.SearchDirection = .forward,
                     considerToday: Bool = false) -> Date
    {
        let components = DateComponents(weekday: weekday.rawValue)
        
        if considerToday && self.component(.weekday, from: date) == weekday.rawValue
        {
            return date
        }
        
        return self.nextDate(after: date, matching: components, matchingPolicy: .nextTime, direction: direction)!
    }
}

// https://stackoverflow.com/a/25395011/89812
extension String
{
    public func nobr() -> String
    {
        return self
            .replacingOccurrences(of: " ", with: "\u{a0}")
            .replacingOccurrences(of: "-", with: "\u{2011}")
    }
}

public func ml(_ v: Double) -> Measurement<UnitVolume>
{
    return Measurement<UnitVolume>.init(value: v, unit: .milliliters)
}

public func floz(_ v: Double) -> Measurement<UnitVolume>
{
    return Measurement<UnitVolume>.init(value: v, unit: .fluidOunces)
}
