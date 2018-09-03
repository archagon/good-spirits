//
//  Constants.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-22.
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

class Constants
{
    static let url = URL.init(string: "https://goodspirits.app")!
    
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
    
    #if HEALTH_KIT
    static let healthKitFoodNameKey = "BBMetadataKeyFoodName"
    #endif
    static let tipIAPProductID = "net.abstractrose.goodspirits.iap.tipjar"
    
    static let calorieMultiplier: Double = 1.6
    
    static let standardDrinkSizeDefault: Double = 14
    static let standardDrinkSizeRange: ClosedRange<Double> = 3...30
    static let weeklyLimitRange: ClosedRange<Double> = 0...999
    static let peakLimitRange: ClosedRange<Double> = 0...999
    static let drinkFreeDaysRange: ClosedRange<Int> = 0...8
}
