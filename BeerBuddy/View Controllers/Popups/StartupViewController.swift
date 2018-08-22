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
        
        self.tableView.register(SelectionCell.self, forCellReuseIdentifier: "SelectionCell")
        self.tableView.register(TextEntryCell.self, forCellReuseIdentifier: "TextEntryCell")
        
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: nil)
        {
            print($0)
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
            return allLimits.count
        }
        else if section == 3
        {
            return 4
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
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String?
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
            return "Different countries have established different drinking limits. These numbers are pulled from the respective Ministries of Health, Departments of Health, and so forth. Don't feel obliged to pick your own country! Some countries, such as the UK and the Netherlands, have much healthier recommendations than others."
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
            
            let limit = allLimits[indexPath.row]
            
            let weeklyLimit = limit.weeklyLimit(forMale: self.male)
            let drinks = weeklyLimit.value / Limit.init(withCountryCode: "US").standardDrink.value
            
            cell.textLabel?.text = limit.countryName
            cell.detailTextLabel?.text = String.init(format: (drinks == floor(drinks) ? "%.0f drinks" : "%.1f drinks"), drinks)
            
            if indexPath.row == self.country
            {
                cell.accessoryType = .checkmark
            }
            else
            {
                cell.accessoryType = .none
            }
        }
        else if section == 3
        {
            let aCell = tableView.dequeueReusableCell(withIdentifier: "TextEntryCell") as! TextEntryCell
            cell = aCell
            
            aCell.inputLabel?.delegate = self
            aCell.inputLabel?.placeholder = nil
            
            if indexPath.row == 0
            {
                cell.textLabel?.text = "Alcohol (g) in Standard Drink"
                aCell.inputLabel?.text = String.init(format: "%.1f", Defaults.standardDrinkSize)
                aCell.inputLabel?.keyboardType = .numbersAndPunctuation
            }
            else if indexPath.row == 1
            {
                cell.textLabel?.text = "Max Drinks per Week"
                aCell.inputLabel?.text = Defaults.weeklyLimit != nil ? String.init(format: "%.1f", Defaults.weeklyLimit!) : nil
                aCell.inputLabel?.placeholder = "0.0"
                aCell.inputLabel?.keyboardType = .numbersAndPunctuation
            }
            else if indexPath.row == 2
            {
                cell.textLabel?.text = "Max Drinks at Single Time"
                aCell.inputLabel?.text = Defaults.peakLimit != nil ? String.init(format: "%.1f", Defaults.peakLimit!) : nil
                aCell.inputLabel?.placeholder = "0.0"
                aCell.inputLabel?.keyboardType = .numbersAndPunctuation
            }
            else if indexPath.row == 3
            {
                cell.textLabel?.text = "Drink-Free Days per Week"
                aCell.inputLabel?.text = Defaults.drinkFreeDays != nil ? String.init(format: "%.0f", Defaults.drinkFreeDays!) : nil
                aCell.inputLabel?.placeholder = "0"
                aCell.inputLabel?.keyboardType = .numberPad
            }
        }
        else
        {
            appError("incorrect section")
            cell = UITableViewCell()
        }
        
        return cell
    }
    
    // NEXT: days should be int-cast
    // NEXT: can't leave empty standard drink size
    // NEXT: populate from countries
    // NEXT: hook up to defaults
    // NEXT: fix US 14.0 drinks
    // NEXT: hook up done button
    
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
            self.country = indexPath.row
        }
    }
}

extension StartupViewController: UITextFieldDelegate
{
    // PERF:
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        
        if let _ = Double(text)
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
        inputLabel.tag = 1
        self.contentView.addSubview(inputLabel)

        inputLabel.textColor = UIColor.gray
        inputLabel.textAlignment = .right
        inputLabel.clearButtonMode = .always
        inputLabel.keyboardType = .decimalPad

        inputLabel.translatesAutoresizingMaskIntoConstraints = false
        let l = inputLabel.leftAnchor.constraint(equalTo: detailLabel.leftAnchor)
        let r = inputLabel.rightAnchor.constraint(equalTo: detailLabel.rightAnchor)
        let t = inputLabel.topAnchor.constraint(equalTo: detailLabel.topAnchor)
        let b = inputLabel.bottomAnchor.constraint(equalTo: detailLabel.bottomAnchor)
        NSLayoutConstraint.activate([l, r, t, b])
        
        detailLabel.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    var inputLabel: UITextField?
    {
        return self.viewWithTag(1) as? UITextField
    }
}
