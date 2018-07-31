//
//  CheckinViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-24.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit
import DrawerKit

public class CheckInViewController: UIViewController, DrawerPresentable
{
    @IBOutlet private var abvStackView: UIView!
    
    public var heightOfPartiallyExpandedDrawer: CGFloat
    {
        guard let view = self.viewIfLoaded else { return 20 }
        
        // TODO: accommodate safe area
        return view.convert(CGPoint.init(x: 0, y: self.abvStackView.bounds.maxY), from: self.abvStackView).y + 8
    }
}
