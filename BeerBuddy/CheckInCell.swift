//
//  CheckInCell.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-18.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit

private var _drinkIconCache: [String:UIImage] = [:]
private func drinkIcon(forImageName imageName: String, sansCircle: Bool = false) -> UIImage
{
    if let image = _drinkIconCache[imageName]
    {
        return image
    }
    else
    {
        let size: CGFloat = 100
        let circleWidth: CGFloat = 0 //was 2 for stroke
        
        guard let originalImage = UIImage.init(named: imageName) else
        {
            error("image \(imageName) not found")
            return UIImage()
        }
        
        UIGraphicsBeginImageContextWithOptions(CGSize.init(width: size, height: size), false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let ctx = UIGraphicsGetCurrentContext() else
        {
            error("image context could not be created")
            return UIImage()
        }
        
        ctx.saveGState()
        drawCircle: do
        {
            // QQQ:
            if sansCircle
            {
                let circleWidth: CGFloat = 2
                
                UIColor.black.setStroke()
                let circle = UIBezierPath.init(ovalIn: CGRect.init(x: circleWidth/2, y: circleWidth/2, width: size-circleWidth, height: size-circleWidth))
                circle.lineWidth = circleWidth
                circle.stroke()
                
                break drawCircle
            }
            
            UIColor.black.setStroke()
            let circle = UIBezierPath.init(ovalIn: CGRect.init(x: circleWidth/2, y: circleWidth/2, width: size-circleWidth, height: size-circleWidth))
            circle.lineWidth = circleWidth
            //circle.stroke()
            circle.fill()
        }
        ctx.restoreGState()
        
        ctx.saveGState()
        drawImage: do
        {
            let scale: CGFloat = 1
            originalImage.draw(in: CGRect.init(x: size/2-originalImage.size.width*scale/2, y: size/2-originalImage.size.height*scale/2, width: originalImage.size.width*scale, height: originalImage.size.height*scale), blendMode: (sansCircle ? CGBlendMode.normal : CGBlendMode.xor), alpha: 1)
//            originalImage.draw(at: CGPoint.init(x: size/2-originalImage.size.width/2, y: size/2-originalImage.size.height/2), blendMode: (sansCircle ? CGBlendMode.normal : CGBlendMode.xor), alpha: 1)
        }
        ctx.restoreGState()
        
        let img = UIGraphicsGetImageFromCurrentImageContext()

        guard var retImg = img else
        {
            error("image could not be rendered")
            return UIImage()
        }
        
        retImg = retImg.withRenderingMode(.alwaysTemplate)
        _drinkIconCache[imageName] = retImg
        return _drinkIconCache[imageName]!
    }
}

public class CheckInCell: UITableViewCell
{
    private let prose: UITextView
    //private let stats: UITextView
    private let name: UITextView
    private let contentStack: UIStackView
    private let caption: UITextView
    private let container: UIButton
    private let untappd: UIButton
    
    var dataConstraints: [NSLayoutConstraint]!
    var stubConstraints: [NSLayoutConstraint]!
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        self.prose = UITextView()
        self.name = UITextView()
        self.contentStack = UIStackView()
        self.caption = UITextView()
        self.container = UIButton()
        self.untappd = UIButton()
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = nil
        
        self.prose.isEditable = false
        self.prose.isSelectable = true
        self.prose.delegate = self
        self.prose.isScrollEnabled = false
        
        self.name.isEditable = true
        self.name.isSelectable = true
        self.name.delegate = self
        self.name.isScrollEnabled = false
        
        self.caption.isEditable = false
        self.caption.isSelectable = false
        self.caption.delegate = self
        self.caption.isScrollEnabled = false
        
        let inset: CGFloat = 2
        
        self.name.textContainerInset = UIEdgeInsets.init(top: inset, left: 0, bottom: inset, right: 0)
        self.prose.textContainerInset = UIEdgeInsets.init(top: inset, left: 0, bottom: inset, right: 0)
        self.caption.textContainerInset = UIEdgeInsets.init(top: inset, left: 0, bottom: inset, right: 0)
        
        layout: do
        {
            prose.translatesAutoresizingMaskIntoConstraints = false
            name.translatesAutoresizingMaskIntoConstraints = false
            caption.translatesAutoresizingMaskIntoConstraints = false
            container.translatesAutoresizingMaskIntoConstraints = false
            untappd.translatesAutoresizingMaskIntoConstraints = false
            contentStack.translatesAutoresizingMaskIntoConstraints = false
            
            //self.contentView.addSubview(prose)
            //self.contentView.addSubview(name)
            self.contentView.addSubview(caption)
            self.contentView.addSubview(container)
            //self.contentView.addSubview(untappd)
            
            self.contentStack.axis = .vertical
            self.contentStack.addArrangedSubview(prose)
            self.contentStack.addArrangedSubview(name)
            self.contentView.addSubview(self.contentStack)
            
            let containerSpacer1 = UILayoutGuide.init()
            let containerSpacer2 = UILayoutGuide.init()
            let containerSpacer3 = UILayoutGuide.init()
            let containerSpacer4 = UILayoutGuide.init()
            self.contentView.addLayoutGuide(containerSpacer1)
            self.contentView.addLayoutGuide(containerSpacer2)
            self.contentView.addLayoutGuide(containerSpacer3)
            self.contentView.addLayoutGuide(containerSpacer4)
            
            let views = [ "content":contentStack, "caption":caption, "container":container, "untappd":untappd, "cs1":containerSpacer1, "cs2":containerSpacer2, "cs3":containerSpacer3, "cs4":containerSpacer4 ]
            let metrics = [ "sideMargin":4, "leftMargin":12, "imageLabelGap":6, "gap":4, "imageHeight":30 ]
            
            dataConstraints: do
            {
                let hConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[container(imageHeight)]-(imageLabelGap)-[content]-(sideMargin)-|", options: .alignAllCenterY, metrics: metrics, views: views)
//                let vConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|[cs1][container(imageHeight)][cs2(cs1)]|", options: [], metrics: metrics, views: views)
                let vConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=sideMargin)-[container(imageHeight)]-(>=sideMargin)-|", options: [], metrics: metrics, views: views)
                let vConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=sideMargin)-[content]-(>=sideMargin)-|", options: [], metrics: metrics, views: views)
                
                var dataConstraints: [NSLayoutConstraint] = []
                dataConstraints += hConstraints1
                dataConstraints += vConstraints1
                dataConstraints += vConstraints2
                
                self.dataConstraints = dataConstraints
            }
            
            stubConstraints: do
            {
                let hConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(leftMargin)-[container(imageHeight)]-(imageLabelGap)-[caption]-(sideMargin)-|", options: .alignAllCenterY, metrics: metrics, views: views)
                let vConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=sideMargin)-[container(imageHeight)]-(>=sideMargin)-|", options: [], metrics: metrics, views: views)
                let vConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=sideMargin)-[caption]-(>=sideMargin)-|", options: [], metrics: metrics, views: views)
                
                var stubConstraints: [NSLayoutConstraint] = []
                stubConstraints += hConstraints1
                stubConstraints += vConstraints1
                stubConstraints += vConstraints2
                
                self.stubConstraints = stubConstraints
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func populateWithStub()
    {
        NSLayoutConstraint.deactivate(self.dataConstraints)
        NSLayoutConstraint.activate(self.stubConstraints)
        
        let image = drinkIcon(forImageName: "plus", sansCircle: true)
        
        self.prose.isHidden = true
        self.name.isHidden = true
        self.caption.isHidden = false
        self.untappd.isHidden = true
        
        self.container.setImage(image, for: .normal)
        
        let attributedText = NSMutableAttributedString.init(string: "Add Drink")
        attributedText.setAttributes([NSAttributedStringKey.font:UIFont.systemFont(ofSize: 14)], range: NSMakeRange(0, attributedText.length))
        
        self.caption.attributedText = attributedText
        
        self.container.tintColor = UIButton(type: .system).tintColor
        self.caption.textColor = UIButton(type: .system).tintColor
        
        self.caption.alpha = 0.7
        self.container.alpha = 0.7
    }
    
    public func populateWithData(_ data: Model.CheckIn)
    {
        NSLayoutConstraint.deactivate(self.stubConstraints)
        NSLayoutConstraint.activate(self.dataConstraints)
        
        let imageName = Model.assetNameForDrink(data.drink)
        let image = drinkIcon(forImageName: imageName)
        
        let volume = String.init(format: (data.drink.volume.value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"), data.drink.volume.value as CVarArg)
        
        let measurementFormatter = MeasurementFormatter.init()
        measurementFormatter.unitStyle = .short
        let unit = measurementFormatter.string(from: data.drink.volume.unit)
        
        let abv = String.init(format: "%.1f", data.drink.abv * 100)
        
        let price: String? = (data.drink.price != nil) ? String.init(format: (data.drink.price!.truncatingRemainder(dividingBy: 1) == 0 ? "$%.0f" : "$%.2f"), data.drink.price! as CVarArg) : nil
        
        let amount = "1"
        
        let proseText = "\(volume) \(unit) of \(abv)% ABV \(data.drink.style) ×\(1)"
        
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
            appendUnderl("\(data.drink.style)", tag: "style")
            if let price = price
            {
                appendNormal(" for ")
                appendUnderl("\(price)", tag: "price")
                appendNormal(" ")
            }
            appendNormal(" times ")
            appendUnderl("\(1)", tag: "times")
        }
        proseString.setAttributes([NSAttributedStringKey.font:UIFont.systemFont(ofSize: 14)], range: NSMakeRange(0, proseString.length))
        
        let nameString = NSMutableAttributedString.init(string: data.drink.name ?? "")
        nameString.setAttributes([NSAttributedStringKey.font:UIFont.systemFont(ofSize: 14)], range: NSMakeRange(0, nameString.length))
        
        self.prose.attributedText = proseString
        self.name.attributedText = nameString
        
        self.prose.isHidden = false
        self.name.isHidden = false
        self.caption.isHidden = true
        self.untappd.isHidden = false
        
        self.container.setImage(image, for: .normal)
        self.container.tintColor = UIButton(type: .system).tintColor
        
        self.caption.alpha = 1
        self.container.alpha = 1
    }
}

extension CheckInCell: UITextViewDelegate
{
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
    {
        print("Tapped url \(URL)")
        return false
    }
}
