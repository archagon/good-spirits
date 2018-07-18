//
//  CheckInCell.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-18.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit

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
            
            let views = [ "prose":prose, "name":name, "container":container, "untappd":untappd ]
            let metrics = [ "sideMargin":8, "gap":4, "imageHeight":20 ]
            
            let hConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(sideMargin)-[container(imageHeight)]-(gap)-[prose]-(sideMargin)-|", options: [], metrics: metrics, views: views)
            let hConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(sideMargin)-[container]-[name]-(sideMargin)-|", options: [], metrics: metrics, views: views)
            let vConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(sideMargin)-[container(imageHeight)]", options: [], metrics: metrics, views: views)
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
        let image = UIImage.init(named: imageName)
        
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
