//
//  PricePickerViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-2.
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

public protocol PricePickerViewControllerDelegate: class
{
    func drawerHeight(for: PricePickerViewController) -> CGFloat
    func startingPrice(for: PricePickerViewController) -> Double
    func didSetPrice(_ vc: PricePickerViewController, to: Double)
}

public class PricePickerViewController: CheckInDrawerViewController
{
    public weak var delegate: PricePickerViewControllerDelegate!
    
    @IBOutlet private var unitPicker: UIPickerView!
    @IBOutlet private var decimalPicker: UIPickerView!
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let price = self.delegate.startingPrice(for: self)
        
        // AB: avoids floating point rounding shenanigans
        let rounded = round(price, within: 2)
        let decimals = rounded.decimals
        let units = rounded.units
        
        self.unitPicker.selectRow(units, inComponent: 0, animated: false)
        self.decimalPicker.selectRow(decimals, inComponent: 0, animated: false)
    }
    
    public var selectedPrice: Double
    {
        let units = Double(self.unitPicker.selectedRow(inComponent: 0))
        let decimals = Double(self.decimalPicker.selectedRow(inComponent: 0))
        
        return units + decimals / 100
    }
    
    public override func confirmCallback(_ deleted: Bool = false)
    {
        self.delegate.didSetPrice(self, to: self.selectedPrice)
    }
}

extension PricePickerViewController: UIPickerViewDelegate, UIPickerViewDataSource
{
    public func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        if pickerView == self.unitPicker
        {
            return 5000
        }
        else
        {
            return 100
        }
    }
    
    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    {
        if pickerView == unitPicker
        {
            return "\(row)"
        }
        else
        {
            return String.init(format: "%02d", row)
        }
    }
}

