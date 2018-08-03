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
        
        //let blurView = UIVisualEffectView.init(effect: UIBlurEffect.init(style: .regular))
        let blurView = UIView()
        blurView.backgroundColor = UIColor.white
        //blurView.alpha = 0.9
        self.backgroundView = blurView
        
        self.addButton.setImage(UIImage.init(named: "checkin"), for: .normal)
        self.addButton.tintColor = UIColor.green
        
//        if let label = self.textLabel
//        {
//            self.contentView.addSubview(self.addButton)
//            self.addButton.translatesAutoresizingMaskIntoConstraints = false
//
//            let views = [ "label":label, "button":self.addButton ]
//            let metrics = [ "gap":8, "buttonHeight":16 ]
//
//            let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "[label]-(gap)-[button(buttonHeight)]", options: .alignAllCenterY, metrics: metrics, views: views)
//
//            self.addButton.widthAnchor.constraint(equalTo: self.addButton.heightAnchor).isActive = true
//
//            self.buttonConstraints = hConstraints
//        }
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override func didMoveToWindow()
//    {
//        if let _ = self.textLabel?.superview
//        {
//            NSLayoutConstraint.activate(self.buttonConstraints)
//        }
//    }
}
