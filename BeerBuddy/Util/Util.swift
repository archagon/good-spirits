//
//  Util.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-18.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public func onMain(_ block: @escaping ()->Void)
{
    if !Thread.current.isMainThread
    {
        DispatchQueue.main.async(execute: block)
    }
    else
    {
        block()
    }
}

public func round(_ v: Double, within: Double) -> (decimals: Int, units: Int)
{
    precondition(within > 0)
    
    let k = pow(10, within)
    let value = round(v * k)
    let units = Int(value / k)
    let decimals = Int(value - (Double(units) * k))
    
    return (Int(decimals), Int(units))
}

public func equalish<T: Dimension>(first: Measurement<T>, second: Measurement<T>, delta: Measurement<T>) -> Bool
{
    let baseFirst = first.converted(to: T.baseUnit())
    let baseSecond = second.converted(to: T.baseUnit())
    var baseDelta = delta.converted(to: T.baseUnit())
    
    if baseDelta.value < 0
    {
        baseDelta = baseDelta * -1
    }
    
    var diff = baseFirst - baseSecond

    if diff.value < 0
    {
        diff = diff * -1
    }
    
    return diff <= baseDelta
}

public func appError(_ message: String, _ controller: UIViewController? = nil)
{
    let message = "Oops! \(Constants.appName) encountered an unexpected error. (\(message)) Please e-mail archagon@archagon.net with a sceenshot of this message. My apologies!"
    print("Error: \(message)")
    showMessage(message, controller)
    //assert(false)
}

public func appAlert(_ message: String, _ controller: UIViewController? = nil)
{
    showMessage(message, controller)
}

public func appWarning(_ message: String)
{
    print("Warning: \(message)")
}

public func appDebug(_ message: String)
{
    #if DEBUG
    print("🔵 \(message)")
    #endif
}

public func showMessage(_ msg: String, _ controller: UIViewController? = nil)
{
    onMain
    {
        let popup = PopupDialog.init(title: nil, message: "\(msg)")
        
        let doneButton = DefaultButton.init(title: "OK", height: 40, dismissOnTap: true, action: nil)
        doneButton.backgroundColor = Appearance.themeColor.withAlphaComponent(0.7)
        doneButton.titleColor = UIColor.init(white: 1, alpha: 1)
        doneButton.titleFont = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.regular)
        popup.addButtons([doneButton])
        
        if let controller = controller
        {
            controller.present(popup, animated: true, completion: nil)
        }
        else
        {
            if let presented = (UIApplication.shared.delegate as? AppDelegate)?.rootController?.presentedViewController
            {
                presented.dismiss(animated: true)
                {
                    (UIApplication.shared.delegate as? AppDelegate)?.rootController?.present(popup, animated: true, completion: nil)
                }
            }
            else
            {
                (UIApplication.shared.delegate as? AppDelegate)?.rootController?.present(popup, animated: true, completion: nil)
            }
        }
    }
}

// https://stackoverflow.com/a/49561764/89812
public enum Weekday: Int
{
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    
    public init?(fromDate date: Date, withCalendar calendar: Calendar)
    {
        if let val = Weekday.init(rawValue: calendar.component(.weekday, from: date))
        {
            self = val
        }
        else
        {
            return nil
        }
    }
}
extension Calendar
{
    public func next(_ weekday: Weekday,
                     from date: Date,
                     direction: Calendar.SearchDirection = .forward,
                     considerToday: Bool = false) -> Date
    {
        let components = DateComponents(weekday: weekday.rawValue)
        
        if considerToday && self.component(.weekday, from: date) == weekday.rawValue
        {
            return date
        }
        
        return self.nextDate(after: date, matching: components, matchingPolicy: .nextTime, direction: direction)!
    }
}

// https://stackoverflow.com/a/25395011/89812
extension String
{
    public func nobr() -> String
    {
        return self
            .replacingOccurrences(of: " ", with: "\u{a0}")
            .replacingOccurrences(of: "-", with: "\u{2011}")
    }
}

extension String
{
    mutating func replaceAnchorText<T: CustomStringConvertible>(_ anchor: String, value: T, withDelimiter delim: String = "$")
    {
        if let aRange = range(of: "\(delim)\(anchor)\(delim)")
        {
            self.replaceSubrange(aRange, with: value.description)
        }
    }
}

extension NSMutableAttributedString
{
    func replaceAnchorText<T: CustomStringConvertible>(_ anchor: String, value: T, withDelimiter delim: String = "$", attributes: [NSAttributedStringKey:Any]? = nil)
    {
        let aRange = (self.string as NSString).range(of: "\(delim)\(anchor)\(delim)")
            
        if aRange.location != NSNotFound
        {
            let attributedString = NSAttributedString.init(string: value.description, attributes: attributes)
            self.replaceCharacters(in: aRange, with: attributedString)
        }
    }
}

public func ml(_ v: Double) -> Measurement<UnitVolume>
{
    return Measurement<UnitVolume>.init(value: v, unit: .milliliters)
}

public func floz(_ v: Double) -> Measurement<UnitVolume>
{
    return Measurement<UnitVolume>.init(value: v, unit: .fluidOunces)
}

extension Date
{
    public func today(_ calendar: Calendar) -> Bool
    {
        let todayComp = calendar.dateComponents([.day, .month, .year], from: Date())
        let startComp = calendar.dateComponents([.day, .month, .year], from: self)
        return todayComp == startComp
    }
}
