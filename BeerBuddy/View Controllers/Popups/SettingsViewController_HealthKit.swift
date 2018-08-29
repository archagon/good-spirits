//
//  SettingsViewController_HealthKit.swift
//  Good Spirits
//
//  Created by Alexei Baboulevitch on 2018-8-26.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import HealthKit

// Quick and dirty HealthKit state machine.
extension SettingsViewController
{
    func updateHealthKitToggleAppearance(withCell aCell: UITableViewCell? = nil)
    {
        let aSection = self.sectionCounts.index { $0.0 == .healthKit }
        guard let section = aSection else
        {
            return
        }
        
        if
            let genericCell = aCell ?? self.tableView.cellForRow(at: IndexPath.init(row: 0, section: section)),
            let cell = genericCell as? SubtitleToggleCell
        {
            tableView.beginUpdates()
            switch HealthKit.shared.loginStatus
            {
            case .unavailable:
                cell.enable()
                cell.toggle.isOn = false
                cell.toggle.isEnabled = false
                cell.detailTextLabel?.text = "Health not available on this device"
            case .unauthorized:
                cell.enable()
                cell.toggle.isOn = false
                cell.toggle.isEnabled = false
                cell.detailTextLabel?.text = "Please authorize \(Constants.appName) in Health settings"
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
