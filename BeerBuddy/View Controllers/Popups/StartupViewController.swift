//
//  StartupViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-21.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
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
            
            self.tableView.reloadSections(IndexSet.init(integer: 2), with: UITableViewRowAnimation.none)
        }
    }
    
    var male: Bool = true
    {
        didSet
        {
            self.country = nil
            regenerateLimits(forMen: male)
         
            self.tableView.reloadSections(IndexSet.init(integer: 1), with: UITableViewRowAnimation.none)
            //self.tableView.reloadSections(IndexSet.init(integer: 2), with: UITableViewRowAnimation.left)
            self.tableView.reloadSections(IndexSet.init(integer: 2), with: UITableViewRowAnimation.none)
        }
    }
    
    func updateButton()
    {
        guard let popupController = (self.parent as? StartupListPopupViewController)?.popupController else
        {
            return
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
        
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil)
        { n in
            self.tableView.reloadSections(IndexSet.init(integer: 3), with: UITableViewRowAnimation.none)
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
//        guard let view = super.tableView(tableView, viewForFooterInSection: section) as? UITableViewHeaderFooterView else
//        {
//            return nil
//        }
        
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Footer") else
        {
            return nil
        }
        
        view.textLabel?.numberOfLines = 1000
        view.textLabel?.text = asdf(tableView, titleForFooterInSection: section)
        
        return view
    }
    
    func asdf(_ tableView: UITableView, titleForFooterInSection section: Int) -> String?
    {
        if section == 0
        {
            var copy = "Welcome to $name$! In order to use this drink tracker, you need to set your daily and weekly drinking limits.\n\nRecent studies tend to agree that there is no safe level of alcohol consumption. However, many countries have published recommendations for what constitutes \"low-risk\" drinking. This concept isn't very well-defined, but in general, the less you drink, the less susceptible you are to alcohol-related cancers and other diseases.\n\nBased on my own research, I would suggest starting with the common European weekly limit of $default-men$ standard US drinks for men or $default-women$ standard US drinks for women, then working your way down from there. A standard drink tends to be smaller than you might be used to, e.g. 12 ounces of 5% beer or 4 ounces of 15% wine."
            
            func replaceText<T: CustomStringConvertible>(_ anchor: String, value: T)
            {
                let range = (copy as NSString).range(of: "$\(anchor)$")
                copy = (copy as NSString).replacingCharacters(in: range, with: value.description)
            }
            
            let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
            
            let usDrink = Limit.init(withCountryCode: "US").standardDrink
            let mLimit = Limit.init(withCountryCode: "DK").weeklyLimit(forMale: true).value / usDrink.value
            let wLimit = Limit.init(withCountryCode: "DK").weeklyLimit(forMale: false).value / usDrink.value
            
            replaceText("name", value: appName)
            replaceText("default-men", value: String.init(format: "%.0f", mLimit))
            replaceText("default-women", value: String.init(format: "%.0f", wLimit))
            
            return copy
        }
        else if section == 1
        {
            return "Alcohol limits vary by sex. Your selection will determine the drinking limits presented in the next section."
        }
        else if section == 2
        {
            return "These numbers were pulled from iard.org and come from the respective Ministries of Health, Departments of Public Health, Health Institutes, etc. of each country. Don't feel obliged to pick your own country! Some countries, such as the UK and Netherlands, have more recent and healthier recommendations than the others."
        }
        else if section == 3
        {
            return "If you want, you can also enter your drinking limits manually. This can be changed later in Settings."
        }
        
        return nil
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
    {
        if section == 0, let footer = view as? UITableViewHeaderFooterView
        {
            footer.textLabel?.textColor = UIColor.black
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        //let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let cell: UITableViewCell
        
        //cell.backgroundColor = Appearance.themeColor.withAlphaComponent(0.75)
        //cell.textLabel?.textColor = UIColor.white
        //cell.textLabel?.backgroundColor = nil
        
        let section = indexPath.section
        
        if section == 1
        {
            cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell") as! SelectionCell
            
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
            cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell") as! SelectionCell
            
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
                
                cell.textLabel?.text = limit.countryName
                cell.detailTextLabel?.text = String.init(format: (drinks == floor(drinks) ? "%.0f US drinks" : "%.1f US drinks"), drinks)
                
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
            func fmt(_ t: Double, _ i: Int = 1) -> String
            {
                if floor(t) == t
                {
                    return String.init(format: "%.0f", t)
                }
                else
                {
                    return String.init(format: "%.\(i)f", t)
                }
            }
            
            let aCell = tableView.dequeueReusableCell(withIdentifier: "TextEntryCell") as! TextEntryCell
            cell = aCell
            
            aCell.inputLabel?.delegate = self
            aCell.inputLabel?.placeholder = nil
            aCell.inputLabel?.tag = 0
            
            if indexPath.row == 0
            {
                aCell.inputLabel?.tag = 1
                aCell.inputLabel?.clearButtonMode = .never
                cell.textLabel?.text = "Alcohol (g) in Standard Drink"
                aCell.inputLabel?.text = fmt(Defaults.standardDrinkSize)
                aCell.inputLabel?.keyboardType = .numbersAndPunctuation
            }
            else if indexPath.row == 1
            {
                aCell.inputLabel?.tag = 2
                aCell.inputLabel?.clearButtonMode = .whileEditing
                cell.textLabel?.text = "Max Drinks per Week"
                aCell.inputLabel?.text = Defaults.weeklyLimit != nil ? fmt(Defaults.weeklyLimit! / Defaults.standardDrinkSize) : nil
                aCell.inputLabel?.placeholder = "0.0"
                aCell.inputLabel?.keyboardType = .numbersAndPunctuation
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
        else
        {
            appError("incorrect section")
            cell = UITableViewCell()
        }
        
        return cell
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
        self.tableView.reloadSections(IndexSet.init(integer: 3), with: UITableViewRowAnimation.none)
    }
    
    // NEXT: fix US 14.0 drinks and grams
    // NEXT: hook up done button via viewWithTag
    // NEXT: open on startup
    // NEXT: sizing for devices
    
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
        }
    }
}

extension StartupViewController: UITextFieldDelegate
{
    // PERF:
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
        self.country = nil
        commitInput(forTextEntryField: textField)
    }
}

class SelectionCell: UITableViewCell
{
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        
        self.accessoryType = .checkmark
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}

class TextEntryCell: UITableViewCell
{
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        let detailLabel = self.detailTextLabel!
        detailLabel.text = "aaaaaaaa"
        
        let inputLabel = UITextField.init()
        self.contentView.addSubview(inputLabel)

        inputLabel.textColor = UIColor.gray
        inputLabel.textAlignment = .right
        inputLabel.keyboardType = .decimalPad

        inputLabel.translatesAutoresizingMaskIntoConstraints = false
        let l = inputLabel.leftAnchor.constraint(equalTo: detailLabel.leftAnchor)
        let r = inputLabel.rightAnchor.constraint(equalTo: detailLabel.rightAnchor)
        let t = inputLabel.topAnchor.constraint(equalTo: detailLabel.topAnchor)
        let b = inputLabel.bottomAnchor.constraint(equalTo: detailLabel.bottomAnchor)
        NSLayoutConstraint.activate([l, r, t, b])
        
        detailLabel.isHidden = true
        
        self.inputLabel = inputLabel
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    var inputLabel: UITextField?
}
