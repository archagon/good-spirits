//
//  AppDelegate.swift
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

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?
    var rootController: RootViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        Defaults.registerDefaults()
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(60 * 5)
        
        //Limit.test()
        
        #if HEALTH_KIT
        appDebug("HealthKit enabled")
        #else
        appDebug("HealthKit disabled")
        #endif
        
        #if DONATION
        appDebug("donations enabled")
        #else
        appDebug("donations disabled")
        #endif
        
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        self.rootController?.syncUntappd
        {
            switch $0
            {
            case .error(let e):
                print("background refresh error: \(e.localizedDescription)")
                completionHandler(UIBackgroundFetchResult.failed)
            case .value(let v):
                if v == 0
                {
                    appDebug("background refresh: no new data")
                    completionHandler(UIBackgroundFetchResult.noData)
                }
                else
                {
                    appDebug("background refresh: \(v) new check-ins")
                    completionHandler(UIBackgroundFetchResult.newData)
                }
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication)
    {
    }

    func applicationDidEnterBackground(_ application: UIApplication)
    {
    }

    func applicationWillEnterForeground(_ application: UIApplication)
    {
    }

    func applicationDidBecomeActive(_ application: UIApplication)
    {
    }

    func applicationWillTerminate(_ application: UIApplication)
    {
    }
}

