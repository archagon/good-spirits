//
//  TextDisplayController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-22.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
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
