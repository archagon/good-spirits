//
//  TextDisplayController.swift
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

class TextDisplayController: UIViewController
{
    var textView: UITextView!
    
    var navigationTitle: String?
    {
        get
        {
            return self.navigationItem.title
        }
        set
        {
            return self.navigationItem.title = newValue
        }
    }
    
    var content: String?
    {
        didSet
        {
            self.loadViewIfNeeded()
            self.textView.text = content
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.textView = UITextView()
        self.textView.isEditable = false
        
        self.view.addSubview(self.textView)
        self.textView.frame = self.view.bounds
        self.textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        self.textView.setContentOffset(CGPoint.zero, animated: false)
    }
}
