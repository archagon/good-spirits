//
//  DynamicPopupButton.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-22.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import UIKit

class DynamicPopupButton: PopupDialogButton
{
    var fromLabel: UIViewPropertyAnimator?
    var toLabel: UIViewPropertyAnimator?
    var toLight: UIViewPropertyAnimator!
    var originalTitle: String
    
    deinit
    {
    }
    
    override init(title: String, height: Int, dismissOnTap: Bool, action: PopupDialogButtonAction?)
    {
        self.originalTitle = title
        super.init(title: title, height: height, dismissOnTap: dismissOnTap, action: action)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        self.originalTitle = ""
        super.init(coder: aDecoder)
    }
    
    func triggerExplanation(_ explanation: String, withDuration: TimeInterval = 0.4, withDelay: TimeInterval = 1.5)
    {
        if toLabel?.isRunning == true
        {
            toLabel?.stopAnimation(false)
            toLabel?.finishAnimation(at: .end)
        }
        if fromLabel?.isRunning == true
        {
            fromLabel?.stopAnimation(false)
            fromLabel?.finishAnimation(at: .start)
        }
        fromLabel = nil
        toLabel = nil
        
        self.setTitle(explanation, for: .normal)
        
        fromLabel = UIViewPropertyAnimator.init(duration: withDuration/2, curve: UIViewAnimationCurve.easeOut, animations:
        { [weak `self`] in
            self?.titleLabel?.alpha = 0
        })
        toLabel = UIViewPropertyAnimator.init(duration: withDuration/2, curve: UIViewAnimationCurve.easeOut, animations:
        { [weak `self`] in
            self?.titleLabel?.alpha = 1
        })
        fromLabel?.addCompletion(
        { [weak `self`] _ in
            self?.setTitle(self?.originalTitle, for: .normal)
            self?.toLabel?.startAnimation()
        })
        
        fromLabel?.startAnimation(afterDelay: withDelay)
    }
    
    func triggerLight(_ color: UIColor, textColor: UIColor, withDuration: TimeInterval = 0.3)
    {
        if toLight?.isRunning == true
        {
            toLight?.stopAnimation(false)
            toLight?.finishAnimation(at: .end)
        }
        toLight = nil
        
        toLight = UIViewPropertyAnimator.init(duration: withDuration, curve: UIViewAnimationCurve.easeOut, animations:
        { [weak `self`] in
            self?.backgroundColor = color
            self?.setTitleColor(textColor, for: .normal)
        })
        
        toLight?.startAnimation(afterDelay: 0)
    }
}
