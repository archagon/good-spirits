//
//  DynamicPopupButton.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-22.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//
//  This file is part of Good Spirits.
//
//  Good Spirits is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Good Spirits is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Foobar.  If not, see <https://www.gnu.org/licenses/>.
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
