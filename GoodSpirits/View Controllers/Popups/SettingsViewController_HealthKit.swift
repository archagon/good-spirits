//
//  SettingsViewController_HealthKit.swift
//  Good Spirits
//
//  Created by Alexei Baboulevitch on 2018-8-26.
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
