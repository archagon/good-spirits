//
//  VolumePickerViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-1.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit
import DrawerKit
import DataLayer

// 2. incorrect pint/floz conversion towards end of ticker
// 3. correct rounding (not just floor) + avoid overshoot
// 4. wrong constraints + auto-sizing
// 5. collection selection

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
        return (measure, Model.assetNameForDrink(Model.Drink.init(name: nil, style: .beer, abv: 0, price: nil, volume: measure)))
    }
    private static let drinkTypes: [DrinkStyle:[(volume: Measurement<UnitVolume>, image: String)]] = [
        .beer : [ drinkTuple(.beer, 1.5), drinkTuple(.beer, 6), drinkTuple(.beer, 12), drinkTuple(.beer, 16), drinkTuple(.beer, 32) ],
        .wine : [ drinkTuple(.wine, 5), drinkTuple(.wine, 6) ],
        .sake : [ drinkTuple(.sake, 1.5), drinkTuple(.sake, 5) ]
    ]
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.glasses.register(DrinkCell.self, forCellWithReuseIdentifier: "Drink")
        self.glasses.isScrollEnabled = false
        self.glasesHeight.constant = 75
        
        if let layout = self.glasses.collectionViewLayout as? UICollectionViewFlowLayout
        {
            layout.estimatedItemSize = CGSize.init(width: 44, height: 60)
            layout.minimumInteritemSpacing = 12
        }
        
        self.currentMeasurement = self.delegate.startingVolume(for: self)
        self.style = self.delegate.drinkStyle(for: self)
        
        refreshPickers(animated: false)
    }
    
    private func refreshPickers(animated: Bool)
    {
        let measure = self.currentMeasurement!
        
        guard let row = VolumePickerViewController.validUnits.firstIndex(of: measure.unit) else
        {
            appError("invalid unit \"\(measure.unit)\"")
            return
        }
        
        let units = Int(floor(measure.value))
        let decimals = Int(floor(measure.value.truncatingRemainder(dividingBy: 1) * 10))
        
        self.unitPicker.reloadAllComponents()
        self.measurePicker.reloadAllComponents()
        
        self.unitPicker.selectRow(units, inComponent: 0, animated: animated)
        self.decimalPicker.selectRow(decimals, inComponent: 0, animated: animated)
        self.measurePicker.selectRow(row, inComponent: 0, animated: animated)
    }
    
    public var selectedVolume: Measurement<UnitVolume>
    {
        return self.currentMeasurement
    }
    
    public override func confirmCallback()
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
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets
    {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else
        {
            return UIEdgeInsets.zero
        }

        let CellWidth = 50
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
        return VolumePickerViewController.drinkTypes[self.style]!.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Drink", for: indexPath) as? DrinkCell else
        {
            appError("could not dequeue drink cell")
            return DrinkCell.init(frame: CGRect.zero)
        }
        
//        self.glasses.backgroundColor = .green
//        cell.image.backgroundColor = UIColor.red
//        cell.label.backgroundColor = UIColor.yellow
//        cell.backgroundColor = UIColor.purple
        
        let tuple = VolumePickerViewController.drinkTypes[self.style]![indexPath.row]
        
        cell.image = UIImage.init(named: tuple.image)
        cell.text = Format.format(volume: tuple.volume)
        
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
        
        private let imageScale: CGFloat = 0.7
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
            
            self.imageContainer.translatesAutoresizingMaskIntoConstraints = false
            self.imageView.translatesAutoresizingMaskIntoConstraints = false
            self.label.translatesAutoresizingMaskIntoConstraints = false
            
            self.contentView.addSubview(self.imageContainer)
            self.imageContainer.addSubview(self.imageView)
            self.contentView.addSubview(self.label)
            
            appearance: do
            {
                self.label.textAlignment = .center
                self.label.font = UIFont.systemFont(ofSize: 14)
            }
            
            constraints: do
            {
                let metrics: [String:Any] = ["imageSize":50]
                let views: [String:UIView] = ["imageContainer":self.imageContainer, "image":self.imageView, "label":self.label]
                
                let hConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|[imageContainer(imageSize)]|", options: [], metrics: metrics, views: views)
                let hConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "H:|[label]|", options: [], metrics: metrics, views: views)
                let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageContainer]-(8)-[label]|", options: [], metrics: metrics, views: views)
                
                let imageContainerAspect = self.imageContainer.widthAnchor.constraint(equalTo: self.imageContainer.heightAnchor)
                let imageBottom = self.imageView.bottomAnchor.constraint(equalTo: self.imageView.superview!.bottomAnchor)
                let imageCenter = self.imageView.centerXAnchor.constraint(equalTo: self.imageView.superview!.centerXAnchor)
                
                NSLayoutConstraint.activate(hConstraints1 + hConstraints2 + vConstraints + [imageContainerAspect, imageBottom, imageCenter, self.imageWidth, self.imageHeight])
            }
        }
        
        required init?(coder aDecoder: NSCoder)
        {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
