//
//  Defaults.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-19.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public class Defaults
{
    private static let weekStartsOnMondayKey: String = "WeekStartsOnMonday"
    
    public static func registerDefaults()
    {
        UserDefaults.standard.register(defaults: [
            weekStartsOnMondayKey:false
            ])
    }
    
    public static var weekStartsOnMonday: Bool
    {
        let val = UserDefaults.standard.bool(forKey: weekStartsOnMondayKey)
        return val
    }
}
