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
    @IBOutlet var confirmButton: UIButton?
    @IBOutlet var closeButton: UIButton?
    @IBOutlet var stackView: UIView!
    @IBOutlet var titleLabel: UILabel!
    
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
            self.confirmButton?.setTitle("Accept", for: .normal)
        }
        
        // TODO: why does this not work with system buttons?
        let themeColor = Appearance.themeColor.withAlphaComponent(1)
        let darkenedThemeColor = Appearance.darkenedThemeColor
        let darkenedTextColor = UIColor.init(white: 0.9, alpha: 1)
        self.confirmButton?.setBackgroundImage(themeColor.resizableImage(withCornerRadius: 8), for: .normal)
        self.confirmButton?.setBackgroundImage(darkenedThemeColor.resizableImage(withCornerRadius: 8), for: .highlighted)
        self.confirmButton?.setBackgroundImage(darkenedThemeColor.resizableImage(withCornerRadius: 8), for: .selected)
        self.confirmButton?.setBackgroundImage(darkenedThemeColor.resizableImage(withCornerRadius: 8), for: [.highlighted, .selected])
        self.confirmButton?.setTitleColor(.white, for: .normal)
        self.confirmButton?.setTitleColor(darkenedTextColor, for: .highlighted)
        self.confirmButton?.setTitleColor(darkenedTextColor, for: .selected)
        self.confirmButton?.setTitleColor(darkenedTextColor, for: [.highlighted, .selected])
        self.confirmButton?.layer.cornerRadius = 8
        self.confirmButton?.adjustsImageWhenHighlighted = false
        self.confirmButton?.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.semibold)
        self.confirmButton?.contentEdgeInsets = .init(top: 8, left: 0, bottom: 8, right: 0)
        
        //self.confirmButton?.addTarget(self, action: #selector(changeShadowDown), for: .touchDown)
        //self.confirmButton?.addTarget(self, action: #selector(changeShadowDown), for: .touchDragInside)
        //self.confirmButton?.addTarget(self, action: #selector(changeShadowUp), for: .touchUpInside)
        //self.confirmButton?.addTarget(self, action: #selector(changeShadowUp), for: .touchUpOutside)
        //self.confirmButton?.addTarget(self, action: #selector(changeShadowUp), for: .touchDragOutside)
        //self.confirmButton?.layer.shadowColor = UIColor.black.cgColor
        //self.confirmButton?.layer.shadowOpacity = 0.2
        //self.confirmButton?.layer.shadowRadius = 2
        //self.confirmButton?.layer.shadowOffset = CGSize.init(width: 0, height: 1.5)
        
        self.titleLabel?.textColor = Appearance.themeColor.withAlphaComponent(1)
        
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
