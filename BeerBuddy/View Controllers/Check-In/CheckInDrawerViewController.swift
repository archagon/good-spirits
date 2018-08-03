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
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if let closeButton = self.closeButton
        {
            //let translation = CGAffineTransform.init(translationX: -closeButton.bounds.width/2, y: -closeButton.bounds.height/2)
            let rotation = CGAffineTransform.init(rotationAngle: 0.125 * (2*CGFloat.pi))
            let transform = rotation
            
            closeButton.transform = transform
            
            confirmButton?.setTitle("Done", for: .normal)
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
        guard let view = self.viewIfLoaded else { return 20 }
        
        // TODO: accommodate safe area
        return view.convert(CGPoint.init(x: 0, y: self.stackView.bounds.maxY), from: self.stackView).y + 40
    }
}
