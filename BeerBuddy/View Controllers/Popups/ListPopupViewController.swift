//
//  ListPopupViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-21.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import UIKit

class ListPopupViewController<T: UIViewController>: UINavigationController
{
    var child: T
    {
        return self.topViewController as! T
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor:Appearance.themeColor]
        self.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor:Appearance.themeColor]
    }
    
    var popupController: PopupDialog?
    {
        return self.parent as? PopupDialog
    }
}

// AB: kludge to work with interface builder, which does not support generics
class StartupListPopupViewController: ListPopupViewController<StartupViewController> {}
