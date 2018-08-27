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
import DataLayer

class SettingsViewController: UITableViewController
{
    enum Section
    {
        case iap
        case meta
        case settings
        case untappd
        case healthKit
        case export
        case info
    }
    let sectionCounts: [(Section, Int)] = [(.iap, 0), (.meta, 3), (.settings, 2), (.untappd, 1), (.healthKit, 1), (.export, 1), (.info, 1)]
    
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
    
    // IAP stuff
    var products: [SKProduct]? = nil
    var productsRequest: SKProductsRequest? = nil
    var paymentInProgress = false
    
    var notificationObservers: [Any] = []
    
    var data: DataLayer?
    {
        return (self.presentingViewController as? RootViewController)?.data
    }
    
    deinit
    {
        for observer in notificationObservers
        {
            NotificationCenter.default.removeObserver(observer)
        }
        SKPaymentQueue.default().remove(self)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "Footer")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PriceCell")
        self.tableView.register(SubtitleToggleCell.self, forCellReuseIdentifier: "ToggleCell")
        
        self.tableView.sectionFooterHeight = UITableViewAutomaticDimension
        self.tableView.estimatedSectionFooterHeight = 50
        
        let activeNotification = NotificationCenter.default.addObserver(forName: Notification.Name.UIApplicationDidBecomeActive, object: nil, queue: nil)
        { [weak `self`] _ in
            self?.updateHealthKitToggleAppearance()
            self?.updateUntappdToggleAppearance()
        }
        notificationObservers.append(activeNotification)
        
        SKPaymentQueue.default().add(self)
        
        requestProducts()
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
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Footer")!
        updateFooter(cell, forSection: section)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
    {
        updateFooter(view, forSection: section)
    }
    
    func updateFooter(_ view: UIView?, forSection section: Int)
    {
        guard let footer = view as? UITableViewHeaderFooterView else
        {
            return
        }
        
        if section == 0
        {
            footer.textLabel?.textColor = UIColor.black
        }
        else
        {
            footer.textLabel?.textColor = UIColor.gray
        }
        
        footer.textLabel?.numberOfLines = 1000
        
        if sectionCounts[section].0 == .iap
        {
            var iapPrompt: String
            
            if !Defaults.donated
            {
                iapPrompt = "Hello, dear user! $name$ is currently free because I am unable to add any new features in the forseeable future. With that said, making the app took a good amount of time and effort. If you're able to visit my website and buy something through my Amazon affiliate link, or donate $donation$through an in-app purchase, I would be incredibly grateful!"
                
                iapPrompt.replaceAnchorText("name", value: Constants.appName)
                if let price = localizedPrice()
                {
                    iapPrompt.replaceAnchorText("donation", value: "\(price) ")
                }
                else
                {
                    iapPrompt.replaceAnchorText("donation", value: "")
                }
            }
            else
            {
                iapPrompt = "Thank you very much for donating to $name$! Your contribution means a lot. 😊"
                iapPrompt.replaceAnchorText("name", value: Constants.appName)
            }
            
            footer.textLabel?.text = iapPrompt
        }
        else if sectionCounts[section].0 == .untappd
        {
            footer.textLabel?.text = "New check-ins will automatically be pulled from your Untappd account. Untappd entries will appear at the top of your Log view and will need to be supplemented with volume and price information or dismissed. (Try swiping left on an entiry for a shortcut to do this.) You can also sync manually by pulling-to-refresh from the Log view. Does not sync past check-ins."
        }
        else if sectionCounts[section].0 == .healthKit
        {
            footer.textLabel?.text = "New check-ins will be added as nutrition to your Health app, with an estimate for calories based on the volume and alcohol content of your drinks. Deleted check-ins will also be removed from Health. Does not sync past check-ins, except when updated."
        }
        else if sectionCounts[section].0 == .export
        {
            footer.textLabel?.text = "Export your data as a SQLite database or JSON for backups or outside processing."
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
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return sectionCounts[section].1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let section = indexPath.section
        let type = sectionCounts[section].0
        
        let cell: UITableViewCell
        
        switch type
        {
        case .iap:
            cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        case .meta:
            if indexPath.row == 2
            {
                cell = tableView.dequeueReusableCell(withIdentifier: "PriceCell")!
            }
            else
            {
                cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            }
        case .settings:
            if indexPath.row == 0
            {
                cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell")!
            }
            else
            {
                cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
            }
        case .untappd:
            cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell")!
        case .healthKit:
            cell = tableView.dequeueReusableCell(withIdentifier: "ToggleCell")!
        case .export:
            cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        case .info:
            cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        }
        
        updateCell(cell, forRowAt: indexPath)
        return cell
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
        case .export:
            return nil
        case .info:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
    {
        let section = indexPath.section
        let type = sectionCounts[section].0
        
        if type == .meta
        {
            if indexPath.row == 2 && (self.products == nil || self.paymentInProgress)
            {
                return nil
            }
        }
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
        else if type == .untappd
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
        updateCell(aCell, forRowAt: indexPath)
    }
    
    func updateCell(_ aCell: UITableViewCell?, forRowAt indexPath: IndexPath)
    {
        let maybeCell = aCell ?? self.tableView.cellForRow(at: indexPath)
        guard let aCell = maybeCell else
        {
            return
        }
        
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
            
            if row == 0
            {
                cell.textLabel?.text = "Visit Website"
                cell.accessoryType = .disclosureIndicator
            }
            else if row == 1
            {
                cell.textLabel?.text = "Leave a Review"
                cell.accessoryType = .disclosureIndicator
            }
            else if row == 2
            {
                if let price = localizedPrice()
                {
                    cell.textLabel?.text = "Donate \(price)"
                    
                    if self.paymentInProgress
                    {
                        cell.accessoryType = .none
                        let indicator = UIActivityIndicatorView.init(activityIndicatorStyle: .gray)
                        cell.accessoryView = indicator
                        indicator.startAnimating()
                        cell.textLabel?.textColor = UIColor.gray
                    }
                    else
                    {
                        cell.accessoryType = .disclosureIndicator
                        cell.accessoryView = nil
                        cell.textLabel?.textColor = UIColor.black
                    }
                }
                else
                {
                    cell.accessoryType = .none
                    let indicator = UIActivityIndicatorView.init(activityIndicatorStyle: .gray)
                    cell.accessoryView = indicator
                    indicator.startAnimating()
                    cell.textLabel?.text = "Donate"
                    cell.textLabel?.textColor = UIColor.gray
                }
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
            
            cell.textLabel?.text = "Pull Check-Ins from Untappd"
            cell.textLabel?.numberOfLines = 10
            cell.detailTextLabel?.numberOfLines = 1000
            updateUntappdToggleAppearance(withCell: cell)
        case .healthKit:
            let cell = aCell as! ToggleCell
            cell.accessoryType = .none
            
            cell.toggle.removeTarget(self, action: nil, for: .valueChanged)
            cell.toggle.addTarget(self, action: #selector(healthKitToggled), for: .valueChanged)
            
            cell.textLabel?.text = "Send Check-Ins to Health Kit"
            cell.textLabel?.numberOfLines = 10
            cell.detailTextLabel?.numberOfLines = 1000
            cell.detailTextLabel?.textColor = .red
            updateHealthKitToggleAppearance(withCell: cell)
        case .export:
            let cell = aCell
            cell.accessoryType = .disclosureIndicator
            
            cell.textLabel?.text = "Export Data"
        case .info:
            let cell = aCell
            cell.accessoryType = .disclosureIndicator
            
            cell.textLabel?.text = "Licenses"
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
                if self.products != nil
                {
                    purchase()
                }
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
        case .export:
            appDebug("exporting")
            
            let controller = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
            controller.addAction(UIAlertAction.init(title: "SQLite Database", style: .default, handler:
            { [weak `self`] _ in
                if let data = self?.data, let db = data.primaryStore as? Data_GRDB
                {
                    let url = URL.init(fileURLWithPath: db.path)
                    let shareVC = UIActivityViewController.init(activityItems: [url], applicationActivities: nil)
                    self?.present(shareVC, animated: true, completion: nil)
                }
            }))
            controller.addAction(UIAlertAction.init(title: "JSON", style: .default, handler:
            { [weak `self`] _ in
                do
                {
                    if let data = self?.data
                    {
                        let data = try data.toJSON()
                        let shareVC = UIActivityViewController.init(activityItems: [data], applicationActivities: nil)
                        self?.present(shareVC, animated: true, completion: nil)
                    }
                }
                catch
                {
                    appError("error converting to JSON -- \(error)")
                }
            }))
            controller.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            self.present(controller, animated: true, completion: nil)
            
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
                Defaults.untappdToken = (sender.isOn ? token : nil)
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
                            Defaults.untappdToken = token
                        }
                        
                        self?.navigationController?.popToRootViewController(animated: true)
                        
                        self?.untappdLoginPending = false
                        self?.updateUntappdToggleAppearance()
                    }
                }
            }
        case .enabledAndAuthorized:
            Defaults.untappdToken = (sender.isOn ? Defaults.untappdToken : nil)
        }
        
        updateUntappdToggleAppearance()
    }
    
    @objc func healthKitToggled(_ sender: UISwitch)
    {
        let newValue = sender.isOn
        transitionHealthKitStatus(newValue)
    }
}
