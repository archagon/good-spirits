//
//  CheckinViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-24.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit
import DrawerKit
import DataLayer

public protocol CheckInViewControllerDelegate: class
{
    func calendar(for: CheckInViewController) -> Calendar
    func committed(drink: Model.Drink, onDate: Date?, for: CheckInViewController)
    func deleted(for: CheckInViewController)
    func updateDimensions(for: CheckInViewController)
}

public class CheckInViewController: CheckInDrawerViewController
{
    public weak var delegate: CheckInViewControllerDelegate! { didSet { setupText() } }
    
    public enum Style
    {
        case normal
        case update
        case untappd
    }
    
    var defaultData: Model.Drink? = nil { didSet { setupText() } }
    
    public var type: Style = .normal { didSet { setupText() } }
    public var checkInDate: Date? { didSet { setupText() } }
    public var name: String? { didSet { setupText() } }
    public var abv: Double? { didSet { setupText() } }
    public var volume: Measurement<UnitVolume>? { didSet { setupText() } }
    public var style: DrinkStyle? { didSet { setupText() } }
    public var cost: Double? { didSet { setupText() } }
    
    private var display: (name: String?, date: Date?, abv: Double, volume: Measurement<UnitVolume>, style: DrinkStyle, cost: Double)
    {
        let defaultCheckIn = (self.defaultData ?? Model.Drink.init(name: nil, style: DrinkStyle.defaultStyle, abv: DrinkStyle.defaultStyle.defaultABV, price: 5, volume: DrinkStyle.defaultStyle.defaultVolume))
        
        //let name = self.name ?? defaultCheckIn.name
        let name = self.name
        let date = self.checkInDate
        let abv = self.abv ?? defaultCheckIn.abv
        let volume = self.volume ?? defaultCheckIn.volume
        let style = self.style ?? defaultCheckIn.style
        let cost = self.cost ?? defaultCheckIn.price
        
        return (name, date, abv, volume, style, cost ?? 0)
    }
    
    @IBOutlet private var text: UITextView!

    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.text.textContainerInset = .zero
        self.text.delegate = self
        if #available(iOS 11.0, *)
        {
            self.text.textDragInteraction?.isEnabled = false
        }
        
        // BUGFIX: no more delay when tapping links
        self.text.isSelectable = false
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedTextView))
        text.addGestureRecognizer(tapRecognizer)
        
        setupText()
    }
    
    // https://stackoverflow.com/a/26495954/89812
    @objc func tappedTextView(tapGesture: UIGestureRecognizer)
    {
        guard let textView = tapGesture.view as? UITextView else { return }
        let tapLocation = tapGesture.location(in: textView)
        guard let textPosition = textView.closestPosition(to: tapLocation) else { return }
        guard let attr = textView.textStyling(at: textPosition, in: UITextStorageDirection.forward) else { return }
        
        if let url: NSURL = attr[NSAttributedStringKey.link.rawValue] as? NSURL
        {
            let _ = self.textView(textView, shouldInteractWith: url as URL, in: NSRange.init(location: 0, length: 0), interaction: UITextItemInteraction.invokeDefaultAction)
        }
    }
    
    private func setupText()
    {
        if self.viewIfLoaded == nil
        {
            return
        }
        
        let baseString: NSString = "I $drinking$ $volume$ of $abv$ ABV $type$ $price$$date$."
        
        var attributedString = NSMutableAttributedString.init(string: baseString as String)
        
        let display = self.display
        var withDate = display.date
        var withName = display.name
        var withPrice = display.cost
        
        let dateFormat = DateFormatter.init()
        dateFormat.dateFormat = "EEEE, MMMM\u{a0}d"
        let linkColor = UIColor.init(red: 0, green: 0.47843137254901963, blue: 1, alpha: 1) //from default attributes
        let emphLinkColor = UIColor.red
        
        let paragraph = NSMutableParagraphStyle.init()
        paragraph.lineSpacing = 5
        let mainAttributes: [NSAttributedStringKey:Any] = [
            NSAttributedStringKey.font:UIFont.systemFont(ofSize: 19, weight: .bold),
            NSAttributedStringKey.foregroundColor:UIColor.darkText,
            NSAttributedStringKey.paragraphStyle:paragraph
        ]
        
        attributedString.setAttributes(mainAttributes, range: NSMakeRange(0, attributedString.length))
        
        // AB: manual link styling down below
        self.text.linkTextAttributes = [
            NSAttributedStringKey.underlineStyle.rawValue:NSUnderlineStyle.styleNone.rawValue
        ]
        
        func replaceLink<T: CustomStringConvertible>(_ anchor: String, value: T, tag: String? = nil, emphasized: Bool = false)
        {
            let rTag = tag ?? anchor
         
            var linkAttributes = mainAttributes
            linkAttributes[NSAttributedStringKey.link] = URL.init(fileURLWithPath: rTag)
            linkAttributes[NSAttributedStringKey.underlineStyle] = (NSUnderlineStyle.styleSingle.rawValue)

            if emphasized
            {
                linkAttributes[NSAttributedStringKey.foregroundColor] = emphLinkColor
                linkAttributes[NSAttributedStringKey.underlineColor] = emphLinkColor
            }
            else
            {
                linkAttributes[NSAttributedStringKey.foregroundColor] = linkColor
                linkAttributes[NSAttributedStringKey.underlineColor] = linkColor
            }
            
            let range = (attributedString.string as NSString).range(of: "$\(anchor)$")
            let newText = NSAttributedString.init(string: value.description, attributes: linkAttributes)
            attributedString.replaceCharacters(in: range, with: newText)
        }
        func replaceText<T: CustomStringConvertible>(_ anchor: String, value: T)
        {
            let range = (attributedString.string as NSString).range(of: "$\(anchor)$")
            let newText = NSAttributedString.init(string: value.description, attributes: mainAttributes)
            attributedString.replaceCharacters(in: range, with: newText)
        }
        
        // AB: for testing branches
        //let withDate: Date? = Date.init(timeInterval: 5000, since: Date())
        //withPrice = 1.251245
        //withName = "Lagunitas IPA"
        
        if let date = withDate
        {
            let today = Date()
            if date <= today
            {
                replaceText("drinking", value: "was drinking")
                replaceText("date", value: " on \(dateFormat.string(from: date))")
            }
            else
            {
                replaceText("drinking", value: "will be drinking")
                replaceText("date", value: " on \(dateFormat.string(from: date))")
            }
        }
        else
        {
            replaceText("drinking", value: "am drinking")
            replaceText("date", value: "")
        }
        replaceLink("volume", value: Format.format(volume: display.volume), emphasized: self.type == .untappd && self.volume == nil)
        replaceLink("abv", value: Format.format(abv: display.abv))
        if let name = withName
        {
            replaceText("type", value: "\"$name$\" $type$")
            replaceLink("name", value: name, tag: "type")
            replaceLink("type", value: Format.format(style: display.style), tag: "type")
            //replaceLink("type", value: "\"\(name)\" \(Format.format(style: display.style))")
        }
        else
        {
            replaceLink("type", value: Format.format(style: display.style))
        }
        if withPrice > 0
        {
            replaceText("price", value: "at $price$ per drink")
            replaceLink("price", value: "\(Format.format(price: withPrice))", emphasized: self.type == .untappd && self.cost == nil)
        }
        else
        {
            replaceText("price", value: "for $price$")
            replaceLink("price", value: "free", emphasized: self.type == .untappd && self.cost == nil)
        }
        
        self.text.attributedText = attributedString
        
        switch self.type
        {
        case .normal:
            self.confirmButton?.setTitle("Check In", for: .normal)
            self.deleteButton?.setTitle(nil, for: .normal)
            if let aButton = self.deleteButton
            {
                self.buttonStack.removeArrangedSubview(aButton)
                aButton.isHidden = true
            }
        case .update:
            self.confirmButton?.setTitle("Update", for: .normal)
            self.deleteButton?.setTitle("Delete", for: .normal)
            if let aButton = self.deleteButton
            {
                self.buttonStack.insertArrangedSubview(aButton, at: 0)
                aButton.isHidden = false
            }
        case .untappd:
            self.confirmButton?.setTitle("Approve", for: .normal)
            self.deleteButton?.setTitle("Dismiss", for: .normal)
            if let aButton = self.deleteButton
            {
                self.buttonStack.insertArrangedSubview(aButton, at: 0)
                aButton.isHidden = false
            }
        }
    }
    
    public override func confirmCallback(_ deleted: Bool = false)
    {
        if deleted
        {
            self.delegate.deleted(for: self)
        }
        else
        {
            let display = self.display
            let model = Model.Drink.init(name: display.name, style: display.style, abv: display.abv, price: display.cost, volume: display.volume)
            
            self.delegate.committed(drink: model, onDate: self.checkInDate, for: self)
        }
    }
}

extension CheckInViewController: UITextViewDelegate
{
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
    {
        let id = URL.lastPathComponent
        
        if id == "abv" || id == "volume" || id == "type" || id == "price"
        {
            let storyboard = UIStoryboard.init(name: "Controllers", bundle: nil)
            
            let controller: CheckInDrawerViewController
            if id == "abv"
            {
                let aController = storyboard.instantiateViewController(withIdentifier: "ABVPicker") as! ABVPickerViewController
                aController.delegate = self
                controller = aController
            }
            else if id == "volume"
            {
                let aController = storyboard.instantiateViewController(withIdentifier: "VolumePicker") as! VolumePickerViewController
                aController.delegate = self
                controller = aController
            }
            else if id == "type"
            {
                let aController = storyboard.instantiateViewController(withIdentifier: "StylePicker") as! StylePickerViewController
                aController.delegate = self
                controller = aController
            }
            else
            {
                let aController = storyboard.instantiateViewController(withIdentifier: "PricePicker") as! PricePickerViewController
                aController.delegate = self
                controller = aController
            }
            
            var configuration = controller.standardConfiguration
            configuration.fullExpansionBehaviour = .leavesCustomGap(gap: self.view.bounds.size.height - controller.heightOfPartiallyExpandedDrawer - 32)
            
            let pulley = DrawerDisplayController.init(presentingViewController: self, presentedViewController: controller, configuration: configuration, inDebugMode: false)
            self.drawerDisplayController = pulley
            
            self.present(controller, animated: true, completion: nil)
            
            return false
        }
        
        return false
    }
}

extension CheckInViewController: ABVPickerViewControllerDelegate
{
    public func drawerHeight(for: ABVPickerViewController) -> CGFloat
    {
        return self.heightOfPartiallyExpandedDrawer
    }
    
    public func startingABV(for: ABVPickerViewController) -> Double
    {
        return self.display.abv
    }
    
    public func didSetABV(_ vc: ABVPickerViewController, to: Double)
    {
        self.abv = to
        
        self.delegate?.updateDimensions(for: self)
    }
}

extension CheckInViewController: VolumePickerViewControllerDelegate
{
    public func drawerHeight(for: VolumePickerViewController) -> CGFloat
    {
        return self.heightOfPartiallyExpandedDrawer
    }
    
    public func startingVolume(for: VolumePickerViewController) -> Measurement<UnitVolume>
    {
        return self.display.volume
    }
    
    public func drinkStyle(for: VolumePickerViewController) -> DrinkStyle
    {
        return self.display.style
    }
    
    public func didSetVolume(_ vc: VolumePickerViewController, to: Measurement<UnitVolume>)
    {
        self.volume = to
        
        self.delegate?.updateDimensions(for: self)
    }
}

extension CheckInViewController: StylePickerViewControllerDelegate
{
    public func drawerHeight(for: StylePickerViewController) -> CGFloat
    {
        return self.heightOfPartiallyExpandedDrawer
    }
    
    public func startingStyle(for: StylePickerViewController) -> DrinkStyle
    {
        return self.display.style
    }
    
    public func startingName(for: StylePickerViewController) -> String?
    {
        return self.display.name
    }
    
    public func didSetStyle(_ vc: StylePickerViewController, to: DrinkStyle, withName: String?)
    {
        self.style = to
        self.name = withName
        
        self.delegate?.updateDimensions(for: self)
    }
}

extension CheckInViewController: PricePickerViewControllerDelegate
{
    public func drawerHeight(for: PricePickerViewController) -> CGFloat
    {
        return self.heightOfPartiallyExpandedDrawer
    }
    
    public func startingPrice(for: PricePickerViewController) -> Double
    {
        return self.display.cost
    }
    
    public func didSetPrice(_ vc: PricePickerViewController, to: Double)
    {
        self.cost = to
        
        self.delegate?.updateDimensions(for: self)
    }
}
