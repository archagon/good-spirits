//
//  DayHeaderCell.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-19.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
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
