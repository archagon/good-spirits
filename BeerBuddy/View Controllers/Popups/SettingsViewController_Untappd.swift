//
//  SettingsViewController_Untappd.swift
//  Good Spirits
//
//  Created by Alexei Baboulevitch on 2018-8-26.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

extension SettingsViewController
{
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
