//
//  PopupCells.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-22.
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

import UIKit

class SelectionCell: UITableViewCell
{
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        
        self.accessoryType = .checkmark
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}

class TextEntryCell: UITableViewCell
{
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        let detailLabel = self.detailTextLabel!
        detailLabel.text = "aaaaaaaa"
        
        let inputLabel = UITextField.init()
        self.contentView.addSubview(inputLabel)
        
        inputLabel.textColor = UIColor.gray
        inputLabel.textAlignment = .right
        inputLabel.keyboardType = .decimalPad
        
        inputLabel.translatesAutoresizingMaskIntoConstraints = false
        let l = inputLabel.leftAnchor.constraint(equalTo: detailLabel.leftAnchor)
        let r = inputLabel.rightAnchor.constraint(equalTo: detailLabel.rightAnchor)
        let t = inputLabel.topAnchor.constraint(equalTo: detailLabel.topAnchor)
        let b = inputLabel.bottomAnchor.constraint(equalTo: detailLabel.bottomAnchor)
        NSLayoutConstraint.activate([l, r, t, b])
        
        detailLabel.isHidden = true
        
        self.inputLabel = inputLabel
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    var inputLabel: UITextField?
}

class ToggleCell: UITableViewCell
{
    var toggle: UISwitch
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        let aSwitch = UISwitch()
        self.toggle = aSwitch
        
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        self.accessoryView = aSwitch
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}

class SubtitleToggleCell: ToggleCell
{
    var spinner: UIActivityIndicatorView
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        self.spinner = UIActivityIndicatorView.init(activityIndicatorStyle: .gray)
        
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        self.detailTextLabel?.numberOfLines = 1000
        
        self.textLabel?.backgroundColor = .clear
        self.detailTextLabel?.backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func enable()
    {
        self.spinner.stopAnimating()
        self.accessoryView = self.toggle
    }
    
    func disable()
    {
        self.accessoryView = self.spinner
        self.spinner.startAnimating()
    }
}
