//
//  ABVPickerViewController.swift
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

public protocol ABVPickerViewControllerDelegate: class
{
    func drawerHeight(for: ABVPickerViewController) -> CGFloat
    func startingABV(for: ABVPickerViewController) -> Double
    func didSetABV(_ vc: ABVPickerViewController, to: Double)
}

public class ABVPickerViewController: CheckInDrawerViewController
{
    public weak var delegate: ABVPickerViewControllerDelegate!
    
    @IBOutlet private var unitPicker: UIPickerView!
    @IBOutlet private var decimalPicker: UIPickerView!
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let abv = self.delegate.startingABV(for: self) * 100
        
        // AB: avoids floating point rounding shenanigans
        let rounded = round(abv, within: 1)
        let decimals = rounded.decimals
        let units = rounded.units
        
        self.unitPicker.selectRow(units, inComponent: 0, animated: false)
        self.decimalPicker.selectRow(decimals, inComponent: 0, animated: false)
    }
    
    public var selectedABV: Double
    {
        let units = Double(self.unitPicker.selectedRow(inComponent: 0))
        let decimals = Double(self.decimalPicker.selectedRow(inComponent: 0))
        
        return (units + decimals / 10) / 100
    }
    
    public override func confirmCallback(_ deleted: Bool = false)
    {
        self.delegate.didSetABV(self, to: self.selectedABV)
    }
}

extension ABVPickerViewController: UIPickerViewDelegate, UIPickerViewDataSource
{
    public func numberOfComponents(in pickerView: UIPickerView) -> Int
    {
        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
    {
        if pickerView == self.unitPicker
        {
            return 100
        }
        else
        {
            return 10
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
            return "\(row)"
        }
    }
}
