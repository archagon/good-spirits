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
