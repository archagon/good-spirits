//
//  AppDelegate.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var rootController: RootViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        Defaults.registerDefaults()
        
        //Limit.test()
        
        return true
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

