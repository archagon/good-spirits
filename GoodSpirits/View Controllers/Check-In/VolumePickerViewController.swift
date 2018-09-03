//
//  VolumePickerViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-1.
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
import DrawerKit
import DataLayer

public protocol VolumePickerViewControllerDelegate: class
{
    func drawerHeight(for: VolumePickerViewController) -> CGFloat
    func startingVolume(for: VolumePickerViewController) -> Measurement<UnitVolume>
    func drinkStyle(for: VolumePickerViewController) -> DrinkStyle
    func didSetVolume(_ vc: VolumePickerViewController, to: Measurement<UnitVolume>)
}

public class VolumePickerViewController: CheckInDrawerViewController
{
    public weak var delegate: VolumePickerViewControllerDelegate!
    
    private var style: DrinkStyle!
    private var currentMeasurement: Measurement<UnitVolume>! = nil
    
    @IBOutlet private var glasses: UICollectionView!
    @IBOutlet private var glasesHeight: NSLayoutConstraint!
    
    @IBOutlet private var unitPicker: UIPickerView!
    @IBOutlet private var decimalPicker: UIPickerView!
    @IBOutlet private var measurePicker: UIPickerView!
    
    private static let limit = Measurement<UnitVolume>.init(value: 3, unit: .liters)
    private static let validUnits = [
        //UnitVolume.liters,
        UnitVolume.centiliters,
        UnitVolume.fluidOunces,
        UnitVolume.pints,
        //UnitVolume.imperialFluidOunces,
        //UnitVolume.imperialPints
    ]
    
    private static func drinkTuple(_ type: DrinkStyle, _ flozVal: Double) -> (Measurement<UnitVolume>, String)
    {
        let measure = floz(flozVal)
        return (measure, Model.assetNameForDrink(Model.Drink.init(name: nil, style: type, abv: 0, price: nil, volume: measure)))
    }
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.glasses.register(DrinkCell.self, forCellWithReuseIdentifier: "Drink")
        self.glasses.isScrollEnabled = false
        //self.glasses.backgroundColor = UIColor.green
        self.glasses.allowsSelection = true
        self.glasesHeight.constant = 70 //KLUDGE: I don't think UICV can autosize height
        
        if let layout = self.glasses.collectionViewLayout as? UICollectionViewFlowLayout
        {
            layout.estimatedItemSize = CGSize.init(width: 50, height: 60)
            layout.minimumInteritemSpacing = 8
        }
        
        self.currentMeasurement = self.delegate.startingVolume(for: self)
        self.style = self.delegate.drinkStyle(for: self)
        
        refreshPickers(animated: false)
    }
    
    private func refreshPickers(animated: Bool)
    {
        let measure = self.currentMeasurement!
        
        guard let row = VolumePickerViewController.validUnits.index(of: measure.unit) else
        {
            appError("invalid unit \"\(measure.unit)\"")
            return
        }
        
        // AB: avoids floating point rounding shenanigans
        let rounded = round(measure.value, within: 1)
        let decimals = rounded.decimals
        let units = rounded.units
        
        self.measurePicker.selectRow(row, inComponent: 0, animated: animated)
        
        self.unitPicker.reloadAllComponents()
        //self.measurePicker.reloadAllComponents()
        
        if units >= self.unitPicker.numberOfRows(inComponent: 0)
        {
            self.unitPicker.selectRow(self.unitPicker.numberOfRows(inComponent: 0) - 1, inComponent: 0, animated: animated)
            self.decimalPicker.selectRow(self.decimalPicker.numberOfRows(inComponent: 0) - 1, inComponent: 0, animated: animated)
        }
        else
        {
            self.unitPicker.selectRow(units, inComponent: 0, animated: animated)
            self.decimalPicker.selectRow(decimals, inComponent: 0, animated: animated)
        }
    }
    
    public var selectedVolume: Measurement<UnitVolume>
    {
        return self.currentMeasurement
    }
    
    public override func confirmCallback(_ deleted: Bool = false)
    {
        self.delegate.didSetVolume(self, to: self.selectedVolume)
    }
}

extension VolumePickerViewController: UIPickerViewDelegate, UIPickerViewDataSource
{
    public func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        if pickerView == self.unitPicker
        {
            let unit = VolumePickerViewController.validUnits[self.measurePicker.selectedRow(inComponent: 0)]
            let measure = VolumePickerViewController.limit.converted(to: unit)
            
            return Int(floor(measure.value))
        }
        else if pickerView == self.decimalPicker
        {
            return 10
        }
        else
        {
            return VolumePickerViewController.validUnits.count
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        if pickerView == self.unitPicker
        {
            return "\(row)"
        }
        else if pickerView == self.decimalPicker
        {
            return "\(row)"
        }
        else
        {
            return Format.format(unit: VolumePickerViewController.validUnits[row])
        }
    }
    
    // AB: prevents text cutting off on iPhone SE
    public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let label: UILabel
        if let view = view as? UILabel { label = view }
        else { label = UILabel() }

        label.text = self.pickerView(pickerView, titleForRow: row, forComponent: component)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 23, weight: .regular)
        label.adjustsFontSizeToFitWidth = true

        return label
    }
    
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
    {
        if pickerView == self.unitPicker || pickerView == self.decimalPicker
        {
            let unit = VolumePickerViewController.validUnits[self.measurePicker.selectedRow(inComponent: 0)]
            let units = Double(self.unitPicker.selectedRow(inComponent: 0))
            let decimals = Double(self.decimalPicker.selectedRow(inComponent: 0)) / 10
            
            self.currentMeasurement = Measurement<UnitVolume>.init(value: units + decimals, unit: unit)
        }
        else
        {
            let unit = VolumePickerViewController.validUnits[self.measurePicker.selectedRow(inComponent: 0)]
            self.currentMeasurement.convert(to: unit)
            
            refreshPickers(animated: true)
        }
    }
}

extension VolumePickerViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let measurement = self.style.assortedVolumes[indexPath.row].converted(to: UnitVolume.fluidOunces)
        self.currentMeasurement = measurement
        
        self.refreshPickers(animated: true)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else
        {
            return UIEdgeInsets.zero
        }

        let CellWidth = 50 //TODO: make this a constant
        let CellCount = collectionView.numberOfItems(inSection: section)
        let CellSpacing = layout.minimumInteritemSpacing

        let totalCellWidth = CGFloat(CellWidth * CellCount)
        let totalSpacingWidth = CellSpacing * CGFloat(CellCount - 1)

        let leftInset = (collectionView.bounds.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
        let rightInset = leftInset

        return UIEdgeInsetsMake(0, leftInset, 0, rightInset)
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return self.style.assortedVolumes.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Drink", for: indexPath) as? DrinkCell else
        {
            appError("could not dequeue drink cell")
            return DrinkCell.init(frame: CGRect.zero)
        }
        
        let volumeObj = self.style.assortedVolumes[indexPath.row]
        let volume = volumeObj.converted(to: UnitVolume.fluidOunces).value
        
        let tuple = VolumePickerViewController.drinkTuple(self.style, volume)
        
        cell.image = UIImage.init(named: tuple.1)
        cell.text = Format.format(volume: tuple.0)
        
        return cell
    }
}

extension VolumePickerViewController
{
    private class DrinkCell: UICollectionViewCell
    {
        public var image: UIImage?
        {
            get
            {
                return self.imageView.image
            }
            set
            {
                self.imageView.image = newValue
                if let image = newValue
                {
                    self.imageWidth.constant = image.size.width * self.imageScale
                    self.imageHeight.constant = image.size.height * self.imageScale
                }
            }
        }
        public var text: String?
        {
            get { return self.label.text }
            set { self.label.text = newValue }
        }
        
        private var imageView: UIImageView
        private var label: UILabel
        private var imageContainer: UIView
        
        private let imageScale: CGFloat = 0.6
        private var imageWidth: NSLayoutConstraint
        private var imageHeight: NSLayoutConstraint
        
        override init(frame: CGRect)
        {
            self.imageView = UIImageView.init()
            self.label = UILabel.init()
            self.imageContainer = UIView()
            self.imageWidth = self.imageView.widthAnchor.constraint(equalToConstant: 40)
            self.imageHeight = self.imageView.heightAnchor.constraint(equalToConstant: 40)
            
            super.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 100))
            
            // BUGFIX: this appears to be necessary to prevent autolayout errors
            self.contentView.translatesAutoresizingMaskIntoConstraints = false
            let cvh = NSLayoutConstraint.constraints(withVisualFormat: "H:|[cv]|", options: [], metrics: nil, views: ["cv":self.contentView])
            let cvv = NSLayoutConstraint.constraints(withVisualFormat: "V:|[cv]|", options: [], metrics: nil, views: ["cv":self.contentView])
            NSLayoutConstraint.activate(cvh + cvv)
            
            self.imageContainer.translatesAutoresizingMaskIntoConstraints = false
            self.imageView.translatesAutoresizingMaskIntoConstraints = false
            self.label.translatesAutoresizingMaskIntoConstraints = false

            self.contentView.addSubview(self.imageContainer)
            self.imageContainer.addSubview(self.imageView)
            self.contentView.addSubview(self.label)

            //let highlightView = UIView()
            //highlightView.backgroundColor = UIColor.init(white: 0.5, alpha: 1)
            //highlightView.layer.cornerRadius = 8
            //self.selectedBackgroundView = highlightView

            appearance: do
            {
                self.label.textAlignment = .center
                self.label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
                self.label.textColor = UIColor.darkText
                
                imageContainer.backgroundColor = Appearance.themeColor
                imageContainer.layer.cornerRadius = 8
                
                imageView.tintColor = .white
            }

            constraints: do
            {
                let metrics: [String:Any] = ["imageSize":50]
                let views: [String:UIView] = ["imageContainer":self.imageContainer, "image":self.imageView, "label":self.label]

                let hConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|[imageContainer(imageSize)]|", options: [], metrics: metrics, views: views)
                let hConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "H:|[label]|", options: [], metrics: metrics, views: views)
                let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageContainer(imageSize)]-(2)-[label]|", options: [], metrics: metrics, views: views)

                let imageCenter1 = self.imageView.centerXAnchor.constraint(equalTo: self.imageView.superview!.centerXAnchor)
                let imageCenter2 = self.imageView.centerYAnchor.constraint(equalTo: self.imageView.superview!.centerYAnchor)

                NSLayoutConstraint.activate(hConstraints1 + hConstraints2 + vConstraints)
                NSLayoutConstraint.activate([imageCenter1, imageCenter2, imageWidth, imageHeight])
            }
        }
        
        override var isHighlighted: Bool
        {
            didSet
            {
                if isHighlighted
                {
                    imageContainer.backgroundColor = Appearance.darkenedThemeColor
                    imageView.tintColor = UIColor.init(white: 0.9, alpha: 1)
                }
                else
                {
                    imageContainer.backgroundColor = Appearance.themeColor
                    imageView.tintColor = .white
                }
            }
        }
        
        override var isSelected: Bool
        {
            didSet
            {
                if isHighlighted
                {
                    imageContainer.backgroundColor = Appearance.darkenedThemeColor
                    imageView.tintColor = UIColor.init(white: 0.9, alpha: 1)
                }
                else
                {
                    imageContainer.backgroundColor = Appearance.themeColor
                    imageView.tintColor = .white
                }
            }
        }
        
        required init?(coder aDecoder: NSCoder)
        {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
