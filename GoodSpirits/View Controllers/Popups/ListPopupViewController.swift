//
//  ListPopupViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-21.
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
class SettingsPopupViewController: ListPopupViewController<SettingsViewController> {}
