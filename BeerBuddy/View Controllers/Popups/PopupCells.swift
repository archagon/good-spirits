//
//  PopupCells.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-22.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
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
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        let aSwitch = UISwitch()
        self.accessoryView = aSwitch
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}
