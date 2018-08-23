//
//  SettingsViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-22.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import UIKit

// NEXT: healthkit -- "healthkit will estimate your alcohol calorie consumption as 1.5 times the abv * volume — roughly in the ballpark for most common beers"
// NEXT: untappd vc
// NEXT: affiliate link
// NEXT: about text
// NEXT: license text
// NEXT: week starts on monday defaults hookups + calendar hookup
// NEXT: settings icon and VC hookup

class SettingsViewController: UITableViewController
{
    enum Section
    {
        case iap
        case toggles
        case configs
        case info
    }
    
    let sectionCounts: [(Section, Int)] = [(.iap, 1), (.toggles, 1), (.configs, 3), (.info, 2)]
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.register(ToggleCell.self, forCellReuseIdentifier: "ToggleCell")
    }
}

extension SettingsViewController
{
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return sectionCounts.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return sectionCounts[section].1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let section = indexPath.section
        let type = sectionCounts[section].0
        
        switch type
        {
        case .iap:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            return cell
        case .toggles:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell")!
            return cell
        case .configs:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            return cell
        case .info:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay aCell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        let section = indexPath.section
        let row = indexPath.row
        let type = sectionCounts[section].0
        
        switch type
        {
        case .iap:
            let cell = aCell
            cell.accessoryType = .none
        case .toggles:
            let cell = aCell as! ToggleCell
            cell.accessoryType = .none
            
            cell.textLabel?.text = "Week Starts on Monday"
        case .configs:
            let cell = aCell
            cell.accessoryType = .disclosureIndicator
            
            if row == 0
            {
                cell.textLabel?.text = "Limits Setup"
            }
            else if row == 1
            {
                cell.textLabel?.text = "Untappd Integration"
            }
            else if row == 2
            {
                cell.textLabel?.text = "HealthKit Integration"
            }
        case .info:
            let cell = aCell
            cell.accessoryType = .disclosureIndicator
            
            if row == 0
            {
                cell.textLabel?.text = "About"
            }
            else if row == 1
            {
                cell.textLabel?.text = "Licenses"
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let section = indexPath.section
        let row = indexPath.row
        let type = sectionCounts[section].0
        
        switch type
        {
        case .iap:
            break
        case .configs:
            if row == 0
            {
                let storyboard = UIStoryboard.init(name: "Controllers", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "FirstTimeSetupTest") as! StartupListPopupViewController
                
                self.navigationController?.pushViewController(controller.child, animated: true)
            }
            else if row == 1
            {
                //untappd
            }
            else if row == 2
            {
                //healthkit
            }
        case .info:
            if row == 0
            {
                //about
            }
            else if row == 1
            {
                //licenses
            }
        default:
            break
        }
    }
}

class ToggleCell: UITableViewCell
{
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let aSwitch = UISwitch()
        self.accessoryView = aSwitch
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}
