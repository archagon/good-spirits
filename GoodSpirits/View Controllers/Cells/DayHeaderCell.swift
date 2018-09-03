//
//  DayHeaderCell.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-19.
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

public class DayHeaderCell: UITableViewHeaderFooterView
{
    private let addButton: UIButton
    private var buttonConstraints: [NSLayoutConstraint]!
    
    public override init(reuseIdentifier: String?)
    {
        self.addButton = UIButton()
        
        super.init(reuseIdentifier: reuseIdentifier)
        
        let blurView = UIVisualEffectView.init(effect: UIBlurEffect.init(style: .extraLight))
        self.backgroundView = blurView
        
        self.addButton.setImage(UIImage.init(named: "checkin"), for: .normal)
        self.addButton.tintColor = UIColor.green
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}
