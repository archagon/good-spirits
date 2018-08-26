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
import HealthKit

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
    let sectionCounts: [(Section, Int)] = [(.iap, 0), (.meta, 3), (.settings, 2), (.untappd, 1), (.healthKit, 1), (.info, 1)]
    
    var healthKitLoginPending: Bool = false
    enum HealthKitLoginStatus
    {
        case unavailable
        case unauthorized
        case disabled
        case pendingAuthorization
        case enabledAndAuthorized
    }
    
    var untappdLoginPending: Bool = false
    
    var notificationObservers: [Any] = []
    
    deinit
    {
        for observer in notificationObservers
        {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "Footer")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.register(SubtitleToggleCell.self, forCellReuseIdentifier: "ToggleCell")
        
        self.tableView.sectionFooterHeight = UITableViewAutomaticDimension
        self.tableView.estimatedSectionFooterHeight = 50
        
        let activeNotification = NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil)
        { [weak `self`] _ in
            self?.updateHealthKitToggleAppearance()
            self?.updateUntappdToggleAppearance()
        }
        notificationObservers.append(activeNotification)
    }
    
    func viewWillAppear()
    {
        updateHealthKitToggleAppearance()
        updateUntappdToggleAppearance()
    }
}

// Table view delegate.
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
            var iapPrompt = "Hello, dear user! $name$ is currently free because I am unable to add any new features in the forseeable future. With that said, making the app took a good amount of time and effort. If you're able to visit my website and buy something through my Amazon affiliate link, or donate $donation$ through an in-app purchase, I would be incredibly grateful!"
            
            iapPrompt.replaceAnchorText("name", value: Constants.appName)
            iapPrompt.replaceAnchorText("donation", value: "$1")
            
            footer.textLabel?.text = iapPrompt
        }
        else if sectionCounts[section].0 == .untappd
        {
            footer.textLabel?.text = "New check-ins will automatically be pulled from your Untappd account. Untappd entries will appear at the top of your Log view and will need to be supplemented with volume and price information or dismissed. You can also sync manually by pulling-to-refresh from the same screen. Does not sync past check-ins."
        }
        else if sectionCounts[section].0 == .healthKit
        {
            footer.textLabel?.text = "New check-ins will be added as nutrition to your HealthKit measurements, with an estimate for the calories based on the volume and alcohol content of your drinks. Does not sync past check-ins, unless updated."
        }
        else if sectionCounts[section].0 == .info
        {
            var about = "$name$ $version$ ($build$) is copyright © Alexei Baboulevitch (\"Archagon\") $year$."
            about.replaceAnchorText("name", value: Constants.appName)
            about.replaceAnchorText("version", value: Constants.version)
            about.replaceAnchorText("build", value: Constants.build)
            about.replaceAnchorText("year", value: 2018)
            
            footer.textLabel?.text = about
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
        case .untappd:
            return "Untappd"
        case .healthKit:
            return "Health Kit"
        case .info:
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
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
    {
        let section = indexPath.section
        let type = sectionCounts[section].0
        
        if type == .healthKit
        {
            if let cell = tableView.cellForRow(at: indexPath) as? SubtitleToggleCell
            {
                return (cell.toggle.isEnabled ? indexPath : nil)
            }
            else
            {
                return nil
            }
        }
        
        return indexPath
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
                
                cell.toggle.removeTarget(self, action: nil, for: .valueChanged)
                cell.toggle.addTarget(self, action: #selector(weekStartsOnMondayToggled), for: .valueChanged)
                cell.toggle.isOn = Defaults.weekStartsOnMonday
                
                cell.textLabel?.text = "Week Starts on Monday"
                cell.textLabel?.numberOfLines = 10
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
            
            cell.toggle.removeTarget(self, action: nil, for: .valueChanged)
            cell.toggle.addTarget(self, action: #selector(untappdToggled), for: .valueChanged)
            cell.toggle.isOn = Defaults.untappdEnabled
            
            if row == 0
            {
                cell.textLabel?.text = "Pull Check-Ins from Untappd"
                cell.textLabel?.numberOfLines = 10
                cell.detailTextLabel?.numberOfLines = 1000
                cell.detailTextLabel?.text = "Logged in as Archagon"
                updateUntappdToggleAppearance(withCell: cell)
            }
        case .healthKit:
            let cell = aCell as! ToggleCell
            cell.accessoryType = .none
            
            cell.toggle.removeTarget(self, action: nil, for: .valueChanged)
            cell.toggle.addTarget(self, action: #selector(healthKitToggled), for: .valueChanged)
            cell.toggle.isOn = Defaults.healthKitEnabled
            
            if row == 0
            {
                cell.textLabel?.text = "Send Check-Ins to Health Kit"
                cell.textLabel?.numberOfLines = 10
                cell.detailTextLabel?.numberOfLines = 1000
                cell.detailTextLabel?.textColor = .red
                updateHealthKitToggleAppearance(withCell: cell)
            }
        case .info:
            let cell = aCell
            cell.accessoryType = .disclosureIndicator
            
            if row == 0
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
                UIApplication.shared.open(Constants.url, options: [:], completionHandler: nil)
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
                if let cell = tableView.cellForRow(at: indexPath) as? ToggleCell
                {
                    cell.toggle.isOn = !cell.toggle.isOn
                    weekStartsOnMondayToggled(cell.toggle)
                }
                
                tableView.deselectRow(at: indexPath, animated: true)
            }
            else if row == 1
            {
                let storyboard = UIStoryboard.init(name: "Controllers", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "FirstTimeSetupTest") as! StartupListPopupViewController
                
                if self.navigationController?.topViewController == self
                {
                    self.navigationController?.pushViewController(controller.child, animated: true)
                }
            }
        case .untappd:
            if let cell = tableView.cellForRow(at: indexPath) as? ToggleCell
            {
                cell.toggle.isOn = !cell.toggle.isOn
                untappdToggled(cell.toggle)
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        case .healthKit:
            if let cell = tableView.cellForRow(at: indexPath) as? ToggleCell
            {
                cell.toggle.isOn = !cell.toggle.isOn
                healthKitToggled(cell.toggle)
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        case .info:
            if row == 0
            {
                let textPath = Bundle.main.url(forResource: "Licenses", withExtension: "txt")
                let textContent = try! String.init(contentsOf: textPath!, encoding: String.Encoding.utf8)
                
                //let text = TextDisplayController.init(style: .grouped)
                let text = TextDisplayController.init(nibName: nil, bundle: nil)
                text.navigationTitle = "Licenses"
                text.content = textContent
                
                if self.navigationController?.topViewController == self
                {
                    self.navigationController?.pushViewController(text, animated: true)
                }
            }
        }
    }
}

// Control callbacks.
extension SettingsViewController
{
    @objc func weekStartsOnMondayToggled(_ sender: UISwitch)
    {
        Defaults.weekStartsOnMonday = sender.isOn
    }
    
    @objc func untappdToggled(_ sender: UISwitch)
    {
        if self.untappdLoginPending
        {
            return
        }
        
        switch Untappd.shared.loginStatus
        {
        case .unreachable:
            print("ERROR: unreachable!")
            return
        case .disabled:
            if let token = Defaults.untappdToken
            {
                Defaults.untappdEnabled = sender.isOn
                Untappd.shared.refreshCheckIns(withData: ((UIApplication.shared.delegate as? AppDelegate)?.rootController?.data)!)
                appDebug("UNTAPPD available!")
            }
            else
            {
                let controller = UntappdLoginViewController.init()
                controller.navigationItem.largeTitleDisplayMode = .never
                
                if self.navigationController?.topViewController == self
                {
                    self.untappdLoginPending = true
                    
                    self.navigationController?.pushViewController(controller, animated: true)
                    
                    controller.load
                    { [weak `self`] (token, error) in
                        if let error = error
                        {
                            appError("Untappd login error -- \(error.localizedDescription)")
                        }
                        else
                        {
                            appDebug("retrieved token \(token)")
                            Defaults.untappdEnabled = true
                            Defaults.untappdToken = token
                        }
                        
                        self?.navigationController?.popToRootViewController(animated: true)
                        
                        self?.untappdLoginPending = false
                        self?.updateUntappdToggleAppearance()
                    }
                }
            }
        case .enabledAndAuthorized:
            Defaults.untappdEnabled = sender.isOn
        }
        
        updateUntappdToggleAppearance()
    }
    
    @objc func healthKitToggled(_ sender: UISwitch)
    {
        let newValue = sender.isOn
        transitionHealthKitStatus(newValue)
    }
}

// Quick and dirty HealthKit state machine.
extension SettingsViewController
{
    var healthKitLoginStatus: HealthKitLoginStatus
    {
        if self.healthKitLoginPending
        {
            return .pendingAuthorization
        }
        
        if let status = HealthKit.shared.authStatus()
        {
            switch status
            {
            case .notDetermined:
                return .disabled
            case .sharingAuthorized:
                return (Defaults.healthKitEnabled ?.enabledAndAuthorized : .disabled)
            case .sharingDenied:
                return . unauthorized
            }
        }
        else
        {
            return .unavailable
        }
    }
    
    func transitionHealthKitStatus(_ enabled: Bool)
    {
        switch self.healthKitLoginStatus
        {
        case .unavailable:
            break //no-op, can't do anything
        case .unauthorized:
            break //no-op, can't do anything
        case .disabled:
            if enabled
            {
                // TODO: move this to HealthKit proper
                authorizeHealthKit: do
                {
                    // no need to authorize, already done
                    if HealthKit.shared.authStatus() == .sharingAuthorized
                    {
                        Defaults.healthKitEnabled = true
                    }
                    // need to attempt authorization
                    else
                    {
                        self.healthKitLoginPending = true
                        //self.updateHealthKitToggleAppearance() happens below
                        
                        let allTypes: Set<HKSampleType> = [ HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)! ]
                        HealthKit.shared.store?.requestAuthorization(toShare: allTypes, read: nil)
                        { [weak `self`] (success, error) in
                            onMain
                            {
                                if success
                                {
                                    Defaults.healthKitEnabled = true
                                }
                                else
                                {
                                    if let error = error
                                    {
                                        appWarning("HealthKit error -- \(error)")
                                    }
                                }
                                
                                self?.healthKitLoginPending = false
                                self?.updateHealthKitToggleAppearance()
                            }
                        }
                    }
                }
            }
        case .pendingAuthorization:
            break //can't do anything until login completes
        case .enabledAndAuthorized:
            if !enabled
            {
                Defaults.healthKitEnabled = false
            }
        }
        
        self.updateHealthKitToggleAppearance()
    }
    
    func updateUntappdToggleAppearance(withCell aCell: UITableViewCell? = nil)
    {
        let section: Int = self.sectionCounts.firstIndex { $0.0 == .untappd }!
        
        if
            let genericCell = aCell ?? self.tableView.cellForRow(at: IndexPath.init(row: 0, section: section)),
            let cell = genericCell as? SubtitleToggleCell
        {
            tableView.beginUpdates()
            if self.untappdLoginPending
            {
                tableView.beginUpdates()
                cell.disable()
                cell.toggle.isEnabled = false
                tableView.endUpdates()
            }
            else
            {
                switch Untappd.shared.loginStatus
                {
                case .unreachable:
                    cell.enable()
                    cell.toggle.isOn = false
                    cell.toggle.isEnabled = true
                    cell.detailTextLabel?.text = "Untappd unreachable, please check your internet connection"
                case .disabled:
                    cell.enable()
                    cell.toggle.isOn = false
                    cell.toggle.isEnabled = true
                case .enabledAndAuthorized:
                    cell.enable()
                    cell.toggle.isOn = true
                    cell.toggle.isEnabled = true
                    cell.detailTextLabel?.text = "Logged in as Blah"
                }
            }
            tableView.endUpdates()
        }
    }
    
    func updateHealthKitToggleAppearance(withCell aCell: UITableViewCell? = nil)
    {
        let section: Int = self.sectionCounts.firstIndex { $0.0 == .healthKit }!
        
        if
            let genericCell = aCell ?? self.tableView.cellForRow(at: IndexPath.init(row: 0, section: section)),
            let cell = genericCell as? SubtitleToggleCell
        {
            tableView.beginUpdates()
            switch self.healthKitLoginStatus
            {
            case .unavailable:
                cell.enable()
                cell.toggle.isOn = false
                cell.toggle.isEnabled = false
                cell.detailTextLabel?.text = "HealthKit not available on this device"
            case .unauthorized:
                cell.enable()
                cell.toggle.isOn = false
                cell.toggle.isEnabled = false
                cell.detailTextLabel?.text = "Please authorize \(Constants.appName) in HealthKit settings"
            case .disabled:
                cell.enable()
                cell.toggle.isOn = false
                cell.toggle.isEnabled = true
                cell.detailTextLabel?.text = nil
            case .pendingAuthorization:
                cell.disable()
                //cell.toggle.isOn = true
                cell.toggle.isEnabled = false
                cell.detailTextLabel?.text = nil
            case .enabledAndAuthorized:
                cell.enable()
                cell.toggle.isOn = true
                cell.toggle.isEnabled = true
                cell.detailTextLabel?.text = nil
            }
            tableView.endUpdates()
        }
    }
}
