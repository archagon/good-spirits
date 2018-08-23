//
//  SettingsViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-22.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import UIKit
import StoreKit

// NEXT: healthkit -- "healthkit will estimate your alcohol calorie consumption as 1.5 times the abv * volume — roughly in the ballpark for most common beers"
// NEXT: untappd vc -- checkbox goes to UntappdLoginViewController
// NEXT: about text
// NEXT: license text
// NEXT: intro label
// NEXT: week starts on monday defaults hookups + calendar hookup
// NEXT: settings icon and VC hookup

class SettingsViewController: UITableViewController
{
    enum Section
    {
        case iap
        case meta
        case settings
        case untappd
        case healthKit
        case info
    }
    
    let sectionCounts: [(Section, Int)] = [(.iap, 0), (.meta, 3), (.settings, 2), (.untappd, 1), (.healthKit, 1), (.info, 2)]
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "Footer")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.register(SubtitleToggleCell.self, forCellReuseIdentifier: "ToggleCell")
        
        self.tableView.sectionFooterHeight = UITableViewAutomaticDimension
        self.tableView.estimatedSectionFooterHeight = 50
    }
}

extension SettingsViewController
{
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return sectionCounts.count
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Footer")!
        
        footer.textLabel?.numberOfLines = 1000
        
        if sectionCounts[section].0 == .iap
        {
            var iapPrompt = "Hello, dear user! $name$ is currently free because I am unable to add any new features in the forseeable future. Nonetheless, making the app took a good amount of time, and if you're able to visit my website and buy something through my Amazon affiliate link, or donate $donation$ through the app, I would be incredibly grateful!"
            
            footer.textLabel?.text = iapPrompt
        }
        else if sectionCounts[section].0 == .untappd
        {
            footer.textLabel?.text = "New check-ins will automatically be pulled from your Untappd account. Check-ins will still need to be completed (or cancelled) within the app."
        }
        else if sectionCounts[section].0 == .healthKit
        {
            footer.textLabel?.text = "New check-ins will be added as foods to your HealthKit diet tracking, with an estimate of 1.5 times the pure alcohol calories."
        }
        else
        {
            footer.textLabel?.text = nil
        }
        
        return footer
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
        case .meta:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            return cell
        case .settings:
            if indexPath.row == 0
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell")!
                return cell
            }
            else
            {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
                return cell
            }
        case .untappd:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell")!
            return cell
        case .healthKit:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell")!
            return cell
        case .info:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        let type = sectionCounts[section].0
        
        switch type
        {
        case .iap:
            return nil
        case .meta:
            return nil
        case .settings:
            return "Settings"
        case .info:
            return "Information"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView aView: UIView, forSection section: Int)
    {
        if let footer = aView as? UITableViewHeaderFooterView
        {
            if section == 0
            {
                footer.textLabel?.textColor = UIColor.black
            }
            else
            {
                footer.textLabel?.textColor = UIColor.gray
            }
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
        case .meta:
            let cell = aCell
            cell.accessoryType = .disclosureIndicator
            
            if row == 0
            {
                cell.textLabel?.text = "Visit Website"
            }
            else if row == 1
            {
                cell.textLabel?.text = "Leave a Review"
            }
            else if row == 2
            {
                cell.textLabel?.text = "Donate"
            }
        case .settings:
            if row == 0
            {
                let cell = aCell as! ToggleCell
                cell.accessoryType = .none
                
                cell.textLabel?.text = "Week Starts on Monday"
            }
            else if row == 1
            {
                let cell = aCell
                cell.accessoryType = .disclosureIndicator
                
                cell.textLabel?.text = "Limits Setup"
            }
        case .untappd:
            let cell = aCell as! ToggleCell
            cell.accessoryType = .none
            
            if row == 0
            {
                cell.textLabel?.text = "Pull Check-Ins from Untappd"
                cell.detailTextLabel?.numberOfLines = 1000
                cell.detailTextLabel?.text = "Logged in as Archagon"
            }
        case .healthKit:
            let cell = aCell as! ToggleCell
            cell.accessoryType = .none
            
            if row == 0
            {
                cell.textLabel?.text = "Send Check-Ins to Health Kit"
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
        case .meta:
            if row == 0
            {
                UIApplication.shared.open(Defaults.url, options: [:], completionHandler: nil)
            }
            else if row == 1
            {
                SKStoreReviewController.requestReview()
            }
            else if row == 2
            {
                //donation
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        case .settings:
            if row == 0
            {
                tableView.deselectRow(at: indexPath, animated: true)
            }
            else if row == 1
            {
                let storyboard = UIStoryboard.init(name: "Controllers", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "FirstTimeSetupTest") as! StartupListPopupViewController
                
                self.navigationController?.pushViewController(controller.child, animated: true)
            }
        case .untappd:
            tableView.deselectRow(at: indexPath, animated: true)
        case .healthKit:
            tableView.deselectRow(at: indexPath, animated: true)
        case .info:
            if row == 0
            {
                let text = TextDisplayController.init(style: .grouped)
                text.navigationTitle = "About"
                text.content = "This is a test about section, just to have some content.\n\nBlah blah blah blah blah."
                
                self.navigationController?.pushViewController(text, animated: true)
            }
            else if row == 1
            {
                let text = TextDisplayController.init(style: .grouped)
                text.navigationTitle = "Licenses"
                text.content = "This is a test licenses section, just to have some content.\n\nBlah blah blah blah blah."
                
                self.navigationController?.pushViewController(text, animated: true)
            }
        }
    }
}

class SubtitleToggleCell: ToggleCell
{
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        self.detailTextLabel?.numberOfLines = 1000
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}
