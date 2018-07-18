//
//  CheckInCell.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-18.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit

private var _drinkIconCache: [String:UIImage] = [:]
private func drinkIcon(forImageName imageName: String) -> UIImage
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
            originalImage.draw(at: CGPoint.init(x: size/2-originalImage.size.width/2, y: size/2-originalImage.size.height/2), blendMode: CGBlendMode.xor, alpha: 1)
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
    public let prose: UITextField
    public let name: UITextField
    public let container: UIButton
    public let untappd: UIButton
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        self.prose = UITextField()
        self.name = UITextField()
        self.container = UIButton()
        self.untappd = UIButton()
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = nil
        
        layout: do
        {
            prose.translatesAutoresizingMaskIntoConstraints = false
            name.translatesAutoresizingMaskIntoConstraints = false
            container.translatesAutoresizingMaskIntoConstraints = false
            untappd.translatesAutoresizingMaskIntoConstraints = false
            
            self.contentView.addSubview(prose)
            self.contentView.addSubview(name)
            self.contentView.addSubview(container)
            //self.contentView.addSubview(untappd)
            
            let containerSpacer1 = UILayoutGuide.init()
            let containerSpacer2 = UILayoutGuide.init()
            self.contentView.addLayoutGuide(containerSpacer1)
            self.contentView.addLayoutGuide(containerSpacer2)
            
            let views = [ "prose":prose, "name":name, "container":container, "untappd":untappd, "cs1":containerSpacer1, "cs2":containerSpacer2 ]
            let metrics = [ "sideMargin":10, "gap":4, "imageHeight":30 ]
            
            let hConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(sideMargin)-[container(imageHeight)]-(sideMargin)-[prose]-(sideMargin)-|", options: [], metrics: metrics, views: views)
            let hConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(sideMargin)-[container]-(sideMargin)-[name]-(sideMargin)-|", options: [], metrics: metrics, views: views)
            let vConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|[cs1][container(imageHeight)][cs2(cs1)]|", options: [], metrics: metrics, views: views)
            let vConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(sideMargin)-[prose]-(gap)-[name]-(sideMargin)-|", options: [], metrics: metrics, views: views)
            
            NSLayoutConstraint.activate(hConstraints1 + hConstraints2 + vConstraints1 + vConstraints2)
        }
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func populateWithData(_ data: Model.CheckIn)
    {
        let imageName = Model.assetNameForDrink(data.drink)
        let image = drinkIcon(forImageName: imageName)
        
        let volume = String.init(format: (data.drink.volume.value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f"), data.drink.volume.value as CVarArg)
        
        let measurementFormatter = MeasurementFormatter.init()
        measurementFormatter.unitStyle = .short
        let unit = measurementFormatter.string(from: data.drink.volume.unit)
        
        let abv = String.init(format: "%.1f", data.drink.abv * 100)
        
        let proseText = "\(volume) \(unit) of \(abv)% ABV \(data.drink.style) × 1"
        
        self.prose.text = proseText
        self.name.text = data.drink.name
        self.container.setImage(image, for: .normal)
    }
}
