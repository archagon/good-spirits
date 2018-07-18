//
//  FirstViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit

extension FirstViewController: UITabBarControllerDelegate
{
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool
    {
        if viewController is StubViewController
        {
            print("Tapped!")
            return false
        }
        else
        {
            return true
        }
    }
}

class FirstViewController: UIViewController
{
    //let debugPast: TimeInterval = -60 * 60 * 24 * 7
    let debugPast: TimeInterval = -60 * 60 * 24 * 50 * 10
    
    @IBOutlet var tableView: UITableView!
    
    var data: Data<DataImpl_JSON>!
    var dataCache: [Model.CheckIn]!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if let tabBarVC = self.tabBarController
        {
            tabBarVC.delegate = self
            
            if let view = tabBarVC.tabBar.viewWithTag(1)
            {
                dump(view)
            }
            
            dump(tabBarVC.tabBar.items)
        }
        
        self.tableView.register(CheckInCell.self, forCellReuseIdentifier: "CheckInCell")
        
        guard let jsonPath = Bundle.main.url(forResource: "stub", withExtension: "json") else
        {
            assert(false, "JSON file not found")
        }
        
        guard let dataImpl = DataImpl_JSON.init(withURL: jsonPath) else
        {
            assert(false, "JSON file not found")
        }
        
        let data = Data.init(impl: dataImpl)
        
        self.data = data
        
        do
        {
            let checkins = try data.checkins(from: Date.init(timeInterval: debugPast, since: Date()), to: Date.distantFuture)
            dump(checkins)
        }
        catch
        {
            assert(false, "Error: \(error)")
        }
        
        reloadData()
    }
    
    func reloadData()
    {
        //let oldCache = self.dataCache
        
        do
        {
            let newCache = try self.data.checkins(from: Date.init(timeInterval: debugPast, since: Date()), to: Date.distantFuture)
            
            // TODO: fancy animations, if needed
            self.dataCache = newCache
            
            self.tableView.reloadData()
        }
        catch
        {
            assert(false, "Error: \(error)")
            self.dataCache = []
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}

extension FirstViewController: UITableViewDataSource, UITableViewDelegate
{
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.dataCache.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CheckInCell") as? CheckInCell else
        {
            return CheckInCell()
        }
        
        let checkin = self.dataCache[indexPath.row]
        
        cell.populateWithData(checkin)
        
        return cell
    }
}
