//
//  Constants.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-22.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

class Constants
{
    // NEXT:
    static let url = URL.init(string: "http://www.apple.com")!
    
    static let calorieMultiplier: Double = 1.6
    
    static var appName: String
    {
        return Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    }
    
    static var version: String
    {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    }
    
    static var build: String
    {
        return Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String
    }
}
