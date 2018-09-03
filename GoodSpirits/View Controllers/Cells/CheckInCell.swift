//
//  CheckInCell.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-18.
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
import DataLayer

public class CheckInCell: UITableViewCell
{
    private let prose: UITextView
    private let stats: UITextView
    private let name: UITextView
    private let contentStack: UIStackView
    private let container: UIButton
    private let untappdShadow: UIView
    private let untappd: UIImageView
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        self.prose = UITextView()
        self.stats = UITextView()
        self.name = UITextView()
        self.contentStack = UIStackView()
        self.container = UIButton()
        self.untappdShadow = UIView()
        self.untappd = UIImageView()
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        //self.backgroundColor = nil
        self.prose.backgroundColor = .clear
        self.stats.backgroundColor = .clear
        self.name.backgroundColor = .clear
        
        self.prose.isEditable = false
        self.prose.isSelectable = false
        self.prose.isScrollEnabled = false
        
        self.name.isEditable = false
        self.name.isSelectable = false
        self.name.isScrollEnabled = false
        
        self.stats.isEditable = false
        self.stats.isSelectable = false
        self.stats.isScrollEnabled = false
        
        // AB: vestigial, easier to respond when just tapping the whole row
        self.container.adjustsImageWhenHighlighted = true
        
        // AB: allows row highlighting
        self.contentStack.isUserInteractionEnabled = false
        self.container.isUserInteractionEnabled = false
        
        let untappdSize: CGFloat = 18
        
        styling: do
        {
            let inset: CGFloat = 2
            
            self.name.textContainerInset = UIEdgeInsets.init(top: inset, left: 0, bottom: inset, right: 0)
            self.stats.textContainerInset = UIEdgeInsets.init(top: inset, left: 0, bottom: inset, right: 0)
            self.prose.textContainerInset = UIEdgeInsets.init(top: inset, left: 0, bottom: inset, right: 0)
            
            self.untappd.image = UIImage.init(named: "untappd")
            self.untappd.clipsToBounds = true
            self.untappd.layer.cornerRadius = untappdSize / 2
            
            let bounds = CGRect.init(x: 0, y: 0, width: untappdSize, height: untappdSize)
            self.untappdShadow.backgroundColor = .white
            self.untappdShadow.layer.cornerRadius = untappdSize / 2
            self.untappdShadow.layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: untappdSize / 2).cgPath
            self.untappdShadow.layer.shadowColor = UIColor.black.cgColor
            self.untappdShadow.layer.shadowRadius = 1.5
            self.untappdShadow.layer.shadowOpacity = 0.1
            self.untappdShadow.layer.shadowOffset = CGSize.init(width: -0.5, height: -0.5)
        }
        
        layout: do
        {
            prose.translatesAutoresizingMaskIntoConstraints = false
            stats.translatesAutoresizingMaskIntoConstraints = false
            name.translatesAutoresizingMaskIntoConstraints = false
            container.translatesAutoresizingMaskIntoConstraints = false
            untappd.translatesAutoresizingMaskIntoConstraints = false
            untappdShadow.translatesAutoresizingMaskIntoConstraints = false
            contentStack.translatesAutoresizingMaskIntoConstraints = false
            
            self.contentView.addSubview(container)
            
            self.contentStack.axis = .vertical
            self.contentStack.alignment = .leading
            self.contentStack.spacing = -1
            self.contentStack.addArrangedSubview(name)
            self.contentStack.addArrangedSubview(prose)
            self.contentStack.addArrangedSubview(stats)
            self.contentView.addSubview(self.contentStack)
            
            self.contentView.addSubview(untappdShadow)
            self.contentView.addSubview(untappd)
            
            let views = [ "content":contentStack, "prose":prose, "name":name, "container":container, "untappd":untappd ]
            let metrics = [ "sideMargin":4, "imageLabelGapContentMargin":10, "imageLabelGapSideMargin":6, "topMargin":6, "leftMargin":12, "imageHeight":34 ]
            
            dataConstraints: do
            {
                let hConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[container(imageHeight)]-(imageLabelGapContentMargin)-[content]-(imageLabelGapSideMargin)-|", options: .alignAllCenterY, metrics: metrics, views: views)
                let hConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "H:[name]-(>=sideMargin)-|", options: .alignAllCenterY, metrics: metrics, views: views)
                let vConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=topMargin)-[container(imageHeight)]-(>=topMargin)-|", options: [], metrics: metrics, views: views)
                let vConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=topMargin)-[content]-(>=topMargin)-|", options: [], metrics: metrics, views: views)
                
                let untappdAspect = untappd.widthAnchor.constraint(equalTo: untappd.heightAnchor)
                let untappdWidth = untappd.widthAnchor.constraint(equalToConstant: untappdSize)
                let untappdCenterX = untappd.centerXAnchor.constraint(equalTo: container.rightAnchor, constant: -3)
                let untappdCenterY = untappd.centerYAnchor.constraint(equalTo: container.bottomAnchor, constant: -4)
                
                let untappdShadowL = untappdShadow.leftAnchor.constraint(equalTo: untappd.leftAnchor)
                let untappdShadowR = untappdShadow.rightAnchor.constraint(equalTo: untappd.rightAnchor)
                let untappdShadowT = untappdShadow.topAnchor.constraint(equalTo: untappd.topAnchor)
                let untappdShadowB = untappdShadow.bottomAnchor.constraint(equalTo: untappd.bottomAnchor)
                
                let dataConstraints: [NSLayoutConstraint] = hConstraints1 + hConstraints2 + vConstraints1 + vConstraints2 + [untappdAspect, untappdWidth, untappdCenterX, untappdCenterY] + [untappdShadowL, untappdShadowR, untappdShadowT, untappdShadowB]
                
                NSLayoutConstraint.activate(dataConstraints)
            }
        }
    }
    
    public func populateWithData(_ data: Model, stats: Stats, isUntappd: Bool = false)
    {
        let imageName = Model.assetNameForDrink(data.checkIn.drink)
        let image = Appearance.shared.drinkIcon(forImageName: imageName)
        
        let volume = Format.format(volume: data.checkIn.drink.volume)
        let units = Format.format(drinks: stats.standardDrinks(data))
        let abv = Format.format(abv: data.checkIn.drink.abv)
        let price = Format.format(price: data.checkIn.drink.price ?? 0)
        let style = Format.format(style: data.checkIn.drink.style)
        let nameT = (data.checkIn.drink.name != nil && data.checkIn.drink.name?.isEmpty == false ? "\(data.checkIn.drink.name!)" : "")
        
        let nameString = NSMutableAttributedString.init(string: nameT)
        nameString.setAttributes([NSAttributedStringKey.font:UIFont.systemFont(ofSize: 14, weight:.semibold)], range: NSMakeRange(0, nameString.length))
        
        let proseText: String
        if isUntappd
        {
            proseText = "\(abv) ABV \(style)"
        }
        else
        {
            proseText = "\(volume) of \(abv) ABV \(style)"
        }
        let proseString = NSMutableAttributedString.init(string: proseText)
        proseString.setAttributes([NSAttributedStringKey.font:UIFont.systemFont(ofSize: 14)], range: NSMakeRange(0, proseString.length))
        //proseString.insert(nameString, at: 0)
        
        let statsText: String
        if isUntappd
        {
            let format = DateFormatter()
            format.dateFormat = "E, MMMM d, yyyy"
            statsText = "Checked in on \(format.string(from: data.checkIn.time))"
        }
        else
        {
            statsText = "Drank \(units) units\(data.checkIn.drink.price == nil || data.checkIn.drink.price == 0 ? "" : " for \(price)")"
        }
        let statsString = NSMutableAttributedString.init(string: statsText)
        statsString.setAttributes([NSAttributedStringKey.font:UIFont.systemFont(ofSize: 14), NSAttributedStringKey.foregroundColor:UIColor.gray], range: NSMakeRange(0, statsString.length))
        
        self.prose.attributedText = proseString
        self.stats.attributedText = statsString
        self.name.attributedText = nameString
        
        if nameString.length == 0
        {
            self.contentStack.removeArrangedSubview(name)
        }
        else
        {
            self.contentStack.insertArrangedSubview(name, at: 0)
        }
    
        self.container.setImage(image, for: .normal)
        
        // TODO: move this to appearance
        let tint: UIColor
        let beerTint = Appearance.themeColor
        let wineTint = UIColor.init(hue: 0.94, saturation: beerTint.s, brightness: beerTint.l, alpha: beerTint.a)
        let liquorTint = UIColor.init(hue: 0.1, saturation: beerTint.s, brightness: beerTint.l * 0.92, alpha: beerTint.a)
        let otherTint = UIColor.init(hue: 0.28, saturation: beerTint.s, brightness: beerTint.l * 0.88, alpha: beerTint.a)
        switch data.checkIn.drink.style
        {
        case .beer:
            fallthrough
        case .mead:
            fallthrough
        case .cider:
            tint = beerTint
            
        case .sake:
            tint = liquorTint
            
        case .wine:
            fallthrough
        case .fortifiedWine:
            tint = wineTint
            
        default:
            if data.checkIn.drink.style.distilled
            {
                tint = liquorTint
            }
            else
            {
                tint = otherTint
            }
        }
        self.container.tintColor = tint
        
        if isUntappd
        {
            self.contentView.backgroundColor = Untappd.themeColor.mixed(with: .white, by: 0.8)
            self.container.setImage(UIImage.init(named: "untappd"), for: .normal)
            self.container.layer.cornerRadius = 34/2
            self.container.clipsToBounds = true
            self.untappd.isHidden = true
            self.untappdShadow.isHidden = true
        }
        else
        {
            self.contentView.backgroundColor = nil
            self.container.layer.cornerRadius = 0
            self.container.clipsToBounds = false
            self.untappd.isHidden = (data.checkIn.untappdId == nil)
            self.untappdShadow.isHidden = self.untappd.isHidden
        }
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}
