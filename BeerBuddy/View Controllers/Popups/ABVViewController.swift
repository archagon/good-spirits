//
//  ABVViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-24.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit

public class ABVViewController: UIViewController
{
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var welcomeText: UITextView!
    @IBOutlet var descriptionText: UITextView!
    @IBOutlet var linkText: UITextView!
    @IBOutlet var conclusionText: UITextView!
    @IBOutlet var standardDrinkField: UITextField!
    @IBOutlet var drinksPerWeekField: UITextField!
    @IBOutlet var peakDrinksField: UITextField!
    @IBOutlet var drinkFreeDaysPerWeekField: UITextField!
    
    override public func viewDidLoad()
    {
        super.viewDidLoad()
        
        let textFields = [welcomeText, descriptionText, linkText, conclusionText]
        textFields.forEach
        {
            $0?.textContainerInset = UIEdgeInsets.zero
        }
        
//        if let existingColor = doneBackground.backgroundColor
//        {
//            var r: CGFloat = 0
//            var g: CGFloat = 0
//            var b: CGFloat = 0
//            let m: CGFloat = 0
//            let s: CGFloat = 1
//            existingColor.getRed(&r, green: &g, blue: &b, alpha: nil)
//            let newColor = UIColor.init(red: m * r + (1 - m) * s, green: m * g + (1 - m) * s, blue: m * b + (1 - m) * s, alpha: 1)
//            doneBackground.backgroundColor = newColor
//        }
    }
    
    override public func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        print("Label: \(self.welcomeText.frame.minX) vs. \(self.titleLabel.frame.minX)")
        print("Inset: \(self.scrollView.contentInset.bottom)")
        self.scrollView.contentInset.bottom = 100
        //self.scrollView.scrollIndicatorInsets.bottom = doneContainer.frame.height
    }
}
