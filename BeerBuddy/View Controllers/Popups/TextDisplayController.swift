//
//  TextDisplayController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-22.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import UIKit

class TextDisplayController: UITableViewController
{
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
            self.tableView.reloadData()
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "Footer")
        
        self.tableView.sectionFooterHeight = UITableViewAutomaticDimension
        self.tableView.estimatedSectionFooterHeight = 500
        
        self.view.backgroundColor = UIColor.white
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Footer")!
        
        footer.textLabel?.numberOfLines = 1000
        
        footer.textLabel?.text = self.content
        
        return footer
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView aView: UIView, forSection section: Int)
    {
        if let footer = aView as? UITableViewHeaderFooterView
        {
            footer.textLabel?.font = UIFont.systemFont(ofSize: 16)
            footer.textLabel?.textColor = UIColor.black
        }
    }
}
