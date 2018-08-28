//
//  AddItemCell.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-19.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit

import UIKit
import DataLayer

public class AddItemCell: UITableViewCell
{
    private let caption: UITextView
    private let container: UIButton
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        self.caption = UITextView()
        self.container = UIButton()
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //self.backgroundColor = nil
        self.caption.backgroundColor = .clear
        
        self.caption.isEditable = false
        self.caption.isSelectable = false
        self.caption.isScrollEnabled = false
        
        // AB: vestigial, easier to respond when just tapping the whole row
        self.container.adjustsImageWhenHighlighted = true
        
        // AB: allows row highlighting
        self.caption.isUserInteractionEnabled = false
        self.container.isUserInteractionEnabled = false
        
        styling: do
        {
            let inset: CGFloat = 2
            
            self.caption.textContainerInset = UIEdgeInsets.init(top: inset, left: 0, bottom: inset, right: 0)
        }
        
        layout: do
        {
            caption.translatesAutoresizingMaskIntoConstraints = false
            container.translatesAutoresizingMaskIntoConstraints = false
            
            self.contentView.addSubview(caption)
            self.contentView.addSubview(container)
            
            let views = [ "caption":caption, "container":container ]
            let metrics = [ "sideMargin":4, "imageLabelGapContentMargin":10, "imageLabelGapSideMargin":6, "topMargin":6, "leftMargin":12, "imageHeight":34 ]
            
            stubConstraints: do
            {
                let hConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[container(imageHeight)]-(imageLabelGapContentMargin)-[caption]-(imageLabelGapSideMargin)-|", options: .alignAllCenterY, metrics: metrics, views: views)
                let vConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=topMargin)-[container(imageHeight)]-(>=topMargin)-|", options: [], metrics: metrics, views: views)
                let vConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=topMargin)-[caption]-(>=topMargin)-|", options: [], metrics: metrics, views: views)
                
                var stubConstraints: [NSLayoutConstraint] = []
                stubConstraints += hConstraints1
                stubConstraints += vConstraints1
                stubConstraints += vConstraints2
                
                NSLayoutConstraint.activate(stubConstraints)
            }
            
            setup: do
            {
                let image = Appearance.shared.drinkIcon(forImageName: "plus", sansCircle: true)
                
                self.container.setImage(image, for: .normal)
                
                let attributedText = NSMutableAttributedString.init(string: "Add Drink")
                attributedText.setAttributes([NSAttributedStringKey.font:UIFont.systemFont(ofSize: 16, weight: .medium)], range: NSMakeRange(0, attributedText.length))
                
                self.caption.attributedText = attributedText
                
                self.container.tintColor = Appearance.themeColor
                self.caption.textColor = Appearance.themeColor
                
                self.caption.alpha = 0.9
                self.container.alpha = 0.6
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}
