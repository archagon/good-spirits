//
//  CheckInDrawerViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-1.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit
import DrawerKit

public class CheckInDrawerViewController: UIViewController, DrawerPresentable, DrawerCoordinating
{
    @IBOutlet var confirmButton: ABPrettyButton?
    @IBOutlet var closeButton: ABPrettyButton?
    @IBOutlet var stackView: UIView!
    
    public var drawerDisplayController: DrawerDisplayController?
    
    public var standardConfiguration: DrawerConfiguration
    {
        var configuration = DrawerConfiguration.init()
        configuration.isFullyPresentableByDrawerTaps = false
        configuration.flickSpeedThreshold = 0
        configuration.timingCurveProvider = UISpringTimingParameters(dampingRatio: 0.8)
        configuration.cornerAnimationOption = .alwaysShowBelowStatusBar
        
        // KLUDGE: prevents full-sreen mode
        configuration.upperMarkGap = 100000
        
        var handleViewConfiguration = HandleViewConfiguration()
        handleViewConfiguration.autoAnimatesDimming = false
        configuration.handleViewConfiguration = handleViewConfiguration
        
        let drawerShadowConfiguration = DrawerShadowConfiguration(shadowOpacity: 0.25,
                                                                  shadowRadius: 5,
                                                                  shadowOffset: .zero,
                                                                  shadowColor: .black)
        configuration.drawerShadowConfiguration = drawerShadowConfiguration
        
        return configuration
    }
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if let closeButton = self.closeButton
        {            
            confirmButton?.setTitle("Accept", for: .normal)
        }
        
        self.confirmButton?.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        self.closeButton?.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    @IBAction func confirmTapped(_ button: UIControl)
    {
        confirmCallback()
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeTapped(_ button: UIControl)
    {
        dismiss(animated: true, completion: nil)
    }
    
    open func confirmCallback() {}
    
    public var heightOfPartiallyExpandedDrawer: CGFloat
    {
        let view = self.view!
        view.layoutIfNeeded() // AB: ensures autolayout is done
        
        let safeArea: CGFloat
        
        // KLUDGE: should pull this from parent VC, but we need this to work as soon as the view is loaded
        if #available(iOS 11.0, *)
        {
            let window = UIApplication.shared.keyWindow
            let bottomPadding = window?.safeAreaInsets.bottom
            safeArea = bottomPadding ?? 0
        }
        else
        {
            safeArea = 0
        }
        
        return view.convert(CGPoint.init(x: 0, y: self.stackView.bounds.maxY), from: self.stackView).y + safeArea + 16
    }
}
