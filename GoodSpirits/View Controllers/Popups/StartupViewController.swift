//
//  StartupViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-21.
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

import Foundation
import UIKit

class StartupViewController: UITableViewController
{
    var allLimits: [Limit]!
    func regenerateLimits(forMen: Bool)
    {
        let allCountries = Limit.allAvailableCountries
        var allLimits = allCountries.map { Limit.init(withCountryCode: $0) }
        allLimits.sort { $0.countryName < $1.countryName }
        allLimits.insert(Limit.standardLimit, at: 0)
        
        self.allLimits = allLimits
    }
    
    var country: Int?
    {
        didSet
        {
            if let index = country
            {
                let limit = allLimits[index]
                
                Defaults.standardDrinkSize = Limit.alcoholToGrams(fromFluidOunces: limit.standardDrink)
                Defaults.weeklyLimit = Limit.alcoholToGrams(fromFluidOunces: limit.weeklyLimit(forMale: male))
                if let peak = limit.peakLimit(forMale: male)
                {
                    Defaults.peakLimit = Limit.alcoholToGrams(fromFluidOunces: peak)
                }
                else
                {
                    Defaults.peakLimit = nil
                }
                //Defaults.drinkFreeDays = limit.drink
                
                var defaults = Defaults()
                defaults.limitCountry = limit.countryCode
                defaults.limitMale = self.male
            }
            else
            {
                var defaults = Defaults()
                defaults.limitCountry = nil
                defaults.limitMale = nil
            }

            quickReloadSection(2)
        }
    }
    
    var male: Bool = true
    {
        didSet
        {
            quickReloadSection(1)
            
            // AB: this reloads section 2 as well
            self.country = nil
            regenerateLimits(forMen: male)
        }
    }
    
    var choiceMade: Bool = false
    {
        // AB: this does not really belong here, but it's the easiest way to do it w/o wiring up delegates
        didSet
        {
            if !(choiceMade == true && oldValue == false)
            {
                return
            }
            
            guard let listPopup = self.parent as? StartupListPopupViewController else
            {
                return
            }
            
            guard let button = listPopup.popupController?.view.viewWithTag(1) as? DynamicPopupButton else
            {
                return
            }
            
            button.triggerLight(Appearance.themeColor.withAlphaComponent(0.7), textColor: UIColor.white)
        }
    }
    
    private var notificationObserver: Any?
    
    deinit
    {
        if let observer = notificationObserver
        {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override init(style: UITableViewStyle)
    {
        super.init(style: style)
        regenerateLimits(forMen: self.male)
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        regenerateLimits(forMen: self.male)
    }
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        regenerateLimits(forMen: self.male)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //self.view.backgroundColor = UIColor.white
        //self.tableView.separatorColor = UIColor.black
        
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "Footer")
        self.tableView.register(SelectionCell.self, forCellReuseIdentifier: "SelectionCell")
        self.tableView.register(TextEntryCell.self, forCellReuseIdentifier: "TextEntryCell")
        
        self.tableView.sectionFooterHeight = UITableViewAutomaticDimension
        self.tableView.estimatedSectionFooterHeight = 50
        
        self.notificationObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: OperationQueue.main)
        { [unowned `self`] n in
            self.quickReloadSection(3)
        }
    }
    
    func quickReloadSection(_ section: Int)
    {
        for indexPath in self.tableView.indexPathsForVisibleRows ?? []
        {
            if indexPath.section == section, let cell = self.tableView.cellForRow(at: indexPath)
            {
                // AB: a bit clunky, but this way we don't have to go through the laborious section reload process
                tableView(self.tableView, willDisplay: cell, forRowAt: indexPath)
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            return 0
        }
        else if section == 1
        {
            return 2
        }
        else if section == 2
        {
            return allLimits.count + 1
        }
        else if section == 3
        {
            return 2
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if section == 0
        {
            return nil
        }
        else if section == 1
        {
            return "Sex"
        }
        else if section == 2
        {
            return "Weekly Drinking Limits by Country"
        }
        else if section == 3
        {
            return "Limit Data"
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Footer") else
        {
            return nil
        }
        
        view.textLabel?.numberOfLines = 1000
        view.textLabel?.text = titleForFooterInSection(section)
        
        return view
    }
    
    func titleForFooterInSection(_ section: Int) -> String?
    {
        if section == 0
        {
            var copy = "Welcome to $name$! In order to use this drink tracker, you need to set your weekly drinking limits.\n\nRecent studies tend to agree that there is no completely safe level of alcohol consumption. However, many countries have published recommendations for a \"low-risk\" level of drinking. This concept isn't very strictly defined, but it's certainly the case that the less you drink, the less susceptible you are to alcohol-related cancers and other diseases. If you're already drinking, it's a healthy idea to stick to these limits as much as possible.\n\nBased on my own research, I would recommend aiming for a weekly limit of $default-men$ standard US drinks for men or $default-women$ standard US drinks for women. This is the limit adopted by the largest number of countries, including around ten European countries, Peru, Singapore, Vietnam, and Hong Kong. A standard drink tends to be smaller than you might be used to, e.g. 12 ounces of 5% beer or 4 ounces of 15% wine in the US."
            
            let appName = Constants.appName
            
            let usDrink = Limit.init(withCountryCode: "US").standardDrink
            let mLimit = Limit.standardLimit.weeklyLimit(forMale: true).value / usDrink.value
            let wLimit = Limit.standardLimit.weeklyLimit(forMale: false).value / usDrink.value
            
            copy.replaceAnchorText("name", value: appName)
            copy.replaceAnchorText("default-men", value: String.init(format: "%.0f", mLimit))
            copy.replaceAnchorText("default-women", value: String.init(format: "%.0f", wLimit))
            
            return copy
        }
        else if section == 1
        {
            return "Alcohol limits vary by sex. Your selection will determine the drinking limits presented in the next section."
        }
        else if section == 2
        {
            return "These numbers were taken from iard.org and come from the respective Ministries of Health, Departments of Public Health, Health Institutes, and so forth of each country. Don't feel obliged to pick your own country! Some countries, such as the UK and Netherlands, have more recent and healthier recommendations than others."
        }
        else if section == 3
        {
            return "If you want, you can also enter your drinking limits manually. This can be changed later in Settings."
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView aView: UIView, forSection section: Int)
    {
        if let footer = aView as? UITableViewHeaderFooterView
        {
            // AB: doing this here breaks auto-sizing... hope there aren't any caching problems
            //footer.textLabel?.text = titleForFooterInSection(section)
            
            if section == 0
            {
                footer.textLabel?.textColor = UIColor.black
            }
            else
            {
                footer.textLabel?.textColor = UIColor.gray
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplay aCell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        func fmt(_ t: Double, _ i: Int = 1) -> String
        {
            let rounded = round(t * 1000) / 1000
            
            if floor(rounded) == rounded
            {
                return String.init(format: "%.0f", t)
            }
            else
            {
                return String.init(format: "%.\(i)f", t)
            }
        }

        let section = indexPath.section
        
        if section == 1
        {
            guard let cell = aCell as? SelectionCell else
            {
                appError("wrong cell")
                return
            }
            
            if indexPath.row == 0
            {
                cell.textLabel?.text = "Male"
                
                if self.male
                {
                    cell.accessoryType = .checkmark
                }
                else
                {
                    cell.accessoryType = .none
                }
            }
            else
            {
                cell.textLabel?.text = "Female"
                
                if !self.male
                {
                    cell.accessoryType = .checkmark
                }
                else
                {
                    cell.accessoryType = .none
                }
            }
            
            cell.detailTextLabel?.text = nil
        }
        else if section == 2
        {
            guard let cell = aCell as? SelectionCell else
            {
                appError("wrong cell")
                return
            }
            
            let row = indexPath.row
            
            if row == tableView.numberOfRows(inSection: section) - 1
            {
                cell.textLabel?.text = "Custom"
                cell.detailTextLabel?.text = nil
                
                if self.country == nil
                {
                    cell.accessoryType = .checkmark
                }
                else
                {
                    cell.accessoryType = .none
                }
            }
            else
            {
                let limit = allLimits[row]
                
                let weeklyLimit = limit.weeklyLimit(forMale: self.male)
                let drinks = weeklyLimit.value / Limit.init(withCountryCode: "US").standardDrink.value
                
                cell.textLabel?.text = (limit.countryCode == "XX" ? "Standard" : limit.countryName)
                cell.detailTextLabel?.text = "\(fmt(drinks)) US drinks"
                
                if row == self.country
                {
                    cell.accessoryType = .checkmark
                }
                else
                {
                    cell.accessoryType = .none
                }
            }
        }
        else if section == 3
        {
            guard let cell = aCell as? TextEntryCell else
            {
                appError("wrong cell")
                return
            }
            
            cell.inputLabel?.delegate = self
            cell.inputLabel?.placeholder = nil
            cell.inputLabel?.tag = 0
            
            if indexPath.row == 0
            {
                cell.inputLabel?.tag = 1
                cell.inputLabel?.clearButtonMode = .never
                cell.textLabel?.text = "Alcohol (g) in Standard Drink"
                cell.inputLabel?.text = fmt(Defaults.standardDrinkSize)
                cell.inputLabel?.keyboardType = .numbersAndPunctuation
            }
            else if indexPath.row == 1
            {
                cell.inputLabel?.tag = 2
                cell.inputLabel?.clearButtonMode = .whileEditing
                cell.textLabel?.text = "Max Drinks per Week"
                cell.inputLabel?.text = Defaults.weeklyLimit != nil ? fmt(Defaults.weeklyLimit! / Defaults.standardDrinkSize) : nil
                cell.inputLabel?.placeholder = "0.0"
                cell.inputLabel?.keyboardType = .numbersAndPunctuation
            }
            //else if indexPath.row == 2
            //{
            //    aCell.inputLabel?.tag = 3
            //    aCell.inputLabel?.clearButtonMode = .always
            //    cell.textLabel?.text = "Max Drinks at Single Time"
            //    aCell.inputLabel?.text = Defaults.peakLimit != nil ? fmt(Defaults.peakLimit!) : nil
            //    aCell.inputLabel?.placeholder = "0.0"
            //    aCell.inputLabel?.keyboardType = .decimalPad
            //}
            //else if indexPath.row == 3
            //{
            //    aCell.inputLabel?.tag = 4
            //    aCell.inputLabel?.clearButtonMode = .always
            //    cell.textLabel?.text = "Drink-Free Days per Week"
            //    aCell.inputLabel?.text = Defaults.drinkFreeDays != nil ? fmt(Defaults.drinkFreeDays!) : nil
            //    aCell.inputLabel?.placeholder = "0"
            //    aCell.inputLabel?.keyboardType = .numberPad
            //}
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let section = indexPath.section
        
        if section == 1
        {
            return tableView.dequeueReusableCell(withIdentifier: "SelectionCell")!
        }
        else if section == 2
        {
            return tableView.dequeueReusableCell(withIdentifier: "SelectionCell")!
        }
        else if section == 3
        {
            return tableView.dequeueReusableCell(withIdentifier: "TextEntryCell")!
        }
        else
        {
            appError("incorrect section")
            return UITableViewCell()
        }
    }
    
    func commitInput(forTextEntryField textField: UITextField)
    {
        if textField.tag == 1
        {
            if let text = textField.text, let value = Double(text)
            {
                let prevValue = Defaults.standardDrinkSize
                
                Defaults.standardDrinkSize = value
                
                if let weeklyLimit = Defaults.weeklyLimit
                {
                    Defaults.weeklyLimit = (weeklyLimit / prevValue) * Defaults.standardDrinkSize
                }
            }
        }
        else if textField.tag == 2
        {
            if let text = textField.text, let value = Double(text)
            {
                Defaults.weeklyLimit = value * Defaults.standardDrinkSize
            }
            else
            {
                Defaults.weeklyLimit = nil
            }
        }
        //else if textField.tag == 3
        //{
        //    let value = Double(textField.text ?? "")
        //}
        //else if textField.tag == 4
        //{
        //    let value = Int(textField.text ?? "")
        //}
        
        // AB: in case defaults weren't changed
        quickReloadSection(3)
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
    {
        if indexPath.section == 1
        {
            return indexPath
        }
        else if indexPath.section == 2
        {
            return indexPath
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if indexPath.section == 1
        {
            if indexPath.row == 0
            {
                self.male = true
            }
            else
            {
                self.male = false
            }
        }
        else if indexPath.section == 2
        {
            self.country = (indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 ? nil : indexPath.row)
            self.choiceMade = true
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension StartupViewController: UITextFieldDelegate
{
    // PERF: string parsing with every character
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        
        if textField.tag != 4, let _ = Double(text)
        {
            return true
        }
        else if textField.tag == 4, let _ = Int(text)
        {
            return true
        }
        else if text.isEmpty
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    // https://stackoverflow.com/a/26547461/89812 -- AB: no longer relevant
    func textFieldShouldClear(_ textField: UITextField) -> Bool
    {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)
    {
        commitInput(forTextEntryField: textField)
        self.country = nil
        self.choiceMade = true
    }
}
