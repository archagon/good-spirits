//
//  CheckInCell.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-18.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
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
    private let untappd: UIImageView
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        self.prose = UITextView()
        self.stats = UITextView()
        self.name = UITextView()
        self.contentStack = UIStackView()
        self.container = UIButton()
        self.untappd = UIImageView()
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = nil
        
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
        
        let untappdSize: CGFloat = 16
        
        styling: do
        {
            let inset: CGFloat = 2
            
            self.name.textContainerInset = UIEdgeInsets.init(top: inset, left: 0, bottom: inset, right: 0)
            self.stats.textContainerInset = UIEdgeInsets.init(top: inset, left: 0, bottom: inset, right: 0)
            self.prose.textContainerInset = UIEdgeInsets.init(top: inset, left: 0, bottom: inset, right: 0)
            
            self.untappd.image = UIImage.init(named: "untappd")
            self.untappd.clipsToBounds = true
            self.untappd.layer.cornerRadius = untappdSize / 2
        }
        
        layout: do
        {
            let contentMargin: CGFloat = 0
            
            prose.translatesAutoresizingMaskIntoConstraints = false
            stats.translatesAutoresizingMaskIntoConstraints = false
            name.translatesAutoresizingMaskIntoConstraints = false
            container.translatesAutoresizingMaskIntoConstraints = false
            untappd.translatesAutoresizingMaskIntoConstraints = false
            contentStack.translatesAutoresizingMaskIntoConstraints = false
            
            self.contentView.addSubview(container)
            
            self.contentStack.axis = .vertical
            self.contentStack.alignment = .leading
            self.contentStack.addArrangedSubview(name)
            self.contentStack.addArrangedSubview(prose)
            self.contentStack.addArrangedSubview(stats)
            self.contentView.addSubview(self.contentStack)
            
            self.contentView.addSubview(untappd)
            
            let views = [ "content":contentStack, "prose":prose, "name":name, "container":container, "untappd":untappd ]
            let metrics = [ "sideMargin":4, "imageLabelGapContentMargin":6+contentMargin, "imageLabelGapSideMargin":4+contentMargin, "leftMargin":12, "imageHeight":30 ]
            
            dataConstraints: do
            {
                let hConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[container(imageHeight)]-(imageLabelGapContentMargin)-[content]-(imageLabelGapSideMargin)-|", options: .alignAllCenterY, metrics: metrics, views: views)
                let hConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "H:[name]-(>=sideMargin)-|", options: .alignAllCenterY, metrics: metrics, views: views)
                let vConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=sideMargin)-[container(imageHeight)]-(>=sideMargin)-|", options: [], metrics: metrics, views: views)
                let vConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=imageLabelGapSideMargin)-[content]-(>=imageLabelGapSideMargin)-|", options: [], metrics: metrics, views: views)
                
                let untappdAspect = untappd.widthAnchor.constraint(equalTo: untappd.heightAnchor)
                let untappdWidth = untappd.widthAnchor.constraint(equalToConstant: untappdSize)
                let untappdCenterX = untappd.centerXAnchor.constraint(equalTo: container.rightAnchor, constant: -3)
                let untappdCenterY = untappd.centerYAnchor.constraint(equalTo: container.bottomAnchor, constant: -4)
                
                let dataConstraints: [NSLayoutConstraint] = hConstraints1 + hConstraints2 + vConstraints1 + vConstraints2 + [untappdAspect, untappdWidth, untappdCenterX, untappdCenterY]
                
                NSLayoutConstraint.activate(dataConstraints)
            }
        }
    }
    
    public func populateWithData(_ data: Model)
    {
        let imageName = Model.assetNameForDrink(data.checkIn.drink)
        let image = Appearance.shared.drinkIcon(forImageName: imageName)
        
        let volume = String.init(format: (data.checkIn.drink.volume.value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"), data.checkIn.drink.volume.value as CVarArg)
        
        let measurementFormatter = MeasurementFormatter.init()
        measurementFormatter.unitStyle = .short
        let unit = measurementFormatter.string(from: data.checkIn.drink.volume.unit)
        
        let abv = String.init(format: "%.1f", data.checkIn.drink.abv * 100)
        
        let price: String? = (data.checkIn.drink.price != nil) ? String.init(format: (data.checkIn.drink.price!.truncatingRemainder(dividingBy: 1) == 0 ? "$%.0f" : "$%.2f"), data.checkIn.drink.price! as CVarArg) : nil
        
        let amount = "1"
        
        let proseText = "\(volume) \(unit) of \(abv)% ABV \(data.checkIn.drink.style) ×\(1)"
        
        let proseString = NSMutableAttributedString()
        createString: do
        {
            func appendUnderl(_ str: String, tag: String)
            {
                appendNormal(str)
                return
                
                let underlineAttributes: [NSAttributedStringKey:Any] =
                    [
                        NSAttributedStringKey.underlineStyle:(NSUnderlineStyle.styleSingle.rawValue),
                        NSAttributedStringKey.underlineColor:UIColor.gray,
                        NSAttributedStringKey.foregroundColor:UIColor.darkGray,
                        NSAttributedStringKey.link:URL.init(fileURLWithPath: tag)
                ]
                
                let text = NSAttributedString.init(string: str, attributes: underlineAttributes)
                proseString.append(text)
            }
            func appendNormal(_ str: String)
            {
                let text = NSAttributedString.init(string: str)
                proseString.append(text)
            }
            
            appendUnderl("\(volume) \(unit)", tag: "volume")
            appendNormal(" of ")
            appendUnderl("\(abv)%", tag: "abv")
            appendNormal(" ABV ")
            appendUnderl("\(data.checkIn.drink.style)", tag: "style")
        }
        proseString.setAttributes([NSAttributedStringKey.font:UIFont.systemFont(ofSize: 14)], range: NSMakeRange(0, proseString.length))
        
        let nameString = NSMutableAttributedString.init(string: data.checkIn.drink.name ?? "")
        nameString.setAttributes([NSAttributedStringKey.font:UIFont.systemFont(ofSize: 14, weight:.bold)], range: NSMakeRange(0, nameString.length))
        
        let statsString = NSMutableAttributedString()
        createStatsString: do
        {
            let limits = Limit.init(withCountryCode: "US")
            let alcoholVolume = data.checkIn.drink.volume * data.checkIn.drink.abv
            let units = limits.standardUnits(forAlcohol: alcoholVolume)
            let unitsString = String.init(format: "%.1f", units as CVarArg)
            
            // TODO: drink amounts
            let price = (data.checkIn.drink.price != nil ? data.checkIn.drink.price! * 1 : nil)
            let priceString: String? = (price != nil) ? String.init(format: (price!.truncatingRemainder(dividingBy: 1) == 0 ? "$%.0f" : "$%.2f"), price! as CVarArg) : nil
            
            statsString.append(NSAttributedString.init(string: "Drank \(unitsString) standard units\(price == nil ? "" : " for a total of \(priceString ?? "")")"))
        }
        statsString.setAttributes([NSAttributedStringKey.font:UIFont.systemFont(ofSize: 14), NSAttributedStringKey.foregroundColor:UIColor.gray], range: NSMakeRange(0, statsString.length))
        
        self.prose.attributedText = proseString
        self.stats.attributedText = statsString
        
        if nameString.length == 0
        {
            self.contentStack.removeArrangedSubview(name)
        }
        else
        {
            self.contentStack.insertArrangedSubview(name, at: 0)
        }
        self.name.attributedText = nameString
        
        self.container.setImage(image, for: .normal)
        self.container.tintColor = UIButton(type: .system).tintColor
        
        self.container.alpha = 1
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}
