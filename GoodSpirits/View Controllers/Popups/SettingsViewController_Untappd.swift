//
//  SettingsViewController_Untappd.swift
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

extension SettingsViewController
{
    func updateUntappdToggleAppearance(withCell aCell: UITableViewCell? = nil)
    {
        let section: Int = self.sectionCounts.index { $0.0 == .untappd }!
        
        if
            let genericCell = aCell ?? self.tableView.cellForRow(at: IndexPath.init(row: 0, section: section)),
            let cell = genericCell as? SubtitleToggleCell
        {
            switch Untappd.shared.loginStatus
            {
            case .unreachable:
                cell.enable()
                cell.toggle.isOn = false
                cell.toggle.isEnabled = true
                cell.detailTextLabel?.text = "Untappd unreachable, please check your internet connection"
                cell.detailTextLabel?.textColor = UIColor.red
            case .disabled:
                cell.enable()
                cell.toggle.isOn = false
                cell.toggle.isEnabled = true
                cell.detailTextLabel?.text = nil
                cell.detailTextLabel?.textColor = UIColor.black
            case .enabledAndAuthorized:
                cell.enable()
                cell.toggle.isOn = true
                cell.toggle.isEnabled = true
                if let name = Defaults.untappdDisplayName
                {
                    cell.detailTextLabel?.text = "Logged in as \(name)"
                }
                else
                {
                    cell.detailTextLabel?.text = "Logged in"
                }
                cell.detailTextLabel?.textColor = UIColor.black
            }
        }
    }
}
