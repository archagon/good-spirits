//
//  FirstViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit

extension FirstViewController: UITabBarControllerDelegate, ScrollingPopupViewControllerDelegate
{
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool
    {
        if viewController is StubViewController
        {
            if let token = Defaults.untappdToken
            {
                Untappd.UserCheckIns(token)
                { (checkIns, error) in
                }
                return false
            }
            
            if qqqPopup == nil
            {
                untappd: do
                {
                    let untappdVC = UntappdLoginViewController.init
                    { (token, e) in
                        if let e = e
                        {
                            print("token error: \(e)")
                        }
                        else
                        {
                            print("found token: \(token)")
                            Defaults.untappdToken = token
                            //self.dismiss(animated: true, completion: nil)
                            self.qqqPopup?.dismiss(animated: true, completion: nil)
                            self.qqqPopup = nil
                        }
                    }
                    untappdVC.modalPresentationStyle = .popover
                    self.present(untappdVC, animated: true, completion: nil)
                    untappdVC.load()
                    self.qqqPopup = untappdVC
                }
                
                popup: do
                {
                    break popup
                    
                    let vc = UIViewController()
                    vc.view.backgroundColor = UIColor.red
                    let label = UITextView.init()
                    label.text = "This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah."
                    label.font = UIFont.systemFont(ofSize: 12)
                    label.isEditable = false
                    label.isSelectable = false
                    label.isScrollEnabled = false
                    label.textContainerInset = UIEdgeInsets.zero
                    label.translatesAutoresizingMaskIntoConstraints = false
                    vc.view.addSubview(label)
                    let labelHConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(32)-[label]-(32)-|", options: [], metrics: nil, views: ["label":label])
                    let labelVConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(64)-[label]-(64)-|", options: [], metrics: nil, views: ["label":label])
                    NSLayoutConstraint.activate(labelHConstraints + labelVConstraints)
                    
                    vc.preferredContentSize = CGSize.init(width: 400, height: 0)

                    let popup = ScrollingPopupViewController.init()
                    popup.viewController = vc
                    popup.delegate = self

                    //.custom? A custom view presentation style that is managed by a custom presentation controller and one or more custom animator objects.
                    popup.modalPresentationStyle = .overFullScreen

                    
                    self.qqqPopup = popup
                    
                    self.present(popup, animated: false)
                    {
                    }
                }
            }
            
            return false
        }
        else
        {
            return true
        }
    }
    
    public func scrollingPopupDidTapToDismiss(_ vc: ScrollingPopupViewController)
    {
        if qqqPopup != nil && self.presentedViewController == qqqPopup
        {
            dismiss(animated: false, completion: nil)
            qqqPopup = nil
        }
    }
}

class FirstViewController: UIViewController
{
    public var qqqPopup: UIViewController?
    
    //let debugPast: TimeInterval = -60 * 60 * 24 * 7
    let debugPast: TimeInterval = -60 * 60 * 24 * 50 * 10
    
    @IBOutlet var tableView: UITableView!
    
    var data: Data<DataImpl_JSON>!
    
    // guaranteed to always be valid
    var cache: (calendar: Calendar, daysOfWeek: [Weekday], range: (Date, Date), data: [Model.CheckIn])!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // QQQ:
        if let tabBarVC = self.tabBarController
        {
            tabBarVC.delegate = self
        
            if let view = tabBarVC.tabBar.viewWithTag(1)
            {
                dump(view)
            }
        
            dump(tabBarVC.tabBar.items)
        }
        
        tableSetup: do
        {
            self.tableView.register(DayHeaderCell.self, forHeaderFooterViewReuseIdentifier: "DayHeaderCell")
            self.tableView.register(DayHeaderCell.self, forHeaderFooterViewReuseIdentifier: "FooterCell")
            self.tableView.register(CheckInCell.self, forCellReuseIdentifier: "CheckInCell")
            //self.tableView.register(AddItemCell.self, forCellReuseIdentifier: "AddItemCell")
            
            self.tableView.separatorStyle = .none
            
            self.tableView.allowsSelection = false
            self.tableView.allowsMultipleSelectionDuringEditing = false

            self.tableView.rowHeight = UITableViewAutomaticDimension
            self.tableView.estimatedRowHeight = 20 //TODO: actual estimate
        }
        
        guard let jsonPath = Bundle.main.url(forResource: "stub", withExtension: "json") else
        {
            assert(false, "JSON file not found")
        }
        
        guard let dataImpl = DataImpl_JSON.init(withURL: jsonPath) else
        {
            assert(false, "JSON file not found")
        }
        
        let data = Data.init(impl: dataImpl)
        
        self.data = data
        
        //do
        //{
        //    let checkins = try data.checkins(from: Date.init(timeInterval: debugPast, since: Date()), to: Date.distantFuture)
        //    dump(checkins)
        //}
        //catch
        //{
        //    assert(false, "Error: \(error)")
        //}
        
        reloadData()
    }
    
    func reloadData()
    {
        //let oldCache = self.cache
        
        do
        {
            let calendar = Time.calendar()
            let daysOfWeek = Time.daysOfWeek()
            let range = Time.currentWeek()
            let data = try self.data.checkins(from: range.0, to: range.1)
            
            // TODO: fancy animations, if needed
            self.cache = (calendar, daysOfWeek, range, data)
            
            self.tableView.reloadData()
        }
        catch
        {
            assert(false, "Error: \(error)")
            self.cache = (Time.calendar(), Time.daysOfWeek(), Time.currentWeek(), [])
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}

extension FirstViewController: UITableViewDataSource, UITableViewDelegate
{
    // PERF: slow
    private func dataIndex(forIndexPath indexPath: IndexPath) -> Int?
    {
        var j = indexPath.row
        for (i, item) in self.cache.data.enumerated()
        {
            guard let day = Weekday.init(fromDate: item.time, withCalendar: self.cache.calendar) else
            {
                appError("invalid day for checkin")
                return nil
            }
            
            if day == self.cache.daysOfWeek[indexPath.section]
            {
                if j == 0
                {
                    return i
                }
                else
                {
                    j -= 1
                }
            }
        }
        
        return nil
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int
    {
        return 7
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        // PERF: slow
        let count = self.cache.data.reduce(0)
        { (total, item) -> Int in
            let day = Weekday.init(fromDate: item.time, withCalendar: self.cache.calendar)!
            if day == self.cache.daysOfWeek[section]
            {
                return total + 1
            }
            else
            {
                return total
            }
        }
        
        return count + 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "DayHeaderCell") as? DayHeaderCell else
        {
            return DayHeaderCell()
        }
        
        let formatter = DateFormatter.init()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        guard let day = self.cache.calendar.date(byAdding: .day, value: section, to: self.cache.range.0) else
        {
            appError("could not add day to date")
            return nil
        }
        
        //return formatter.string(from: day)
        cell.textLabel?.text = formatter.string(from: day)
//        cell.backgroundColor = UIColor.clear
//        cell.textLabel?.backgroundColor = UIColor.clear
//        cell.backgroundView = nil
//        cell.setNeedsDisplay()
//        cell.setNeedsLayout()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        if section == self.cache.daysOfWeek.count - 1
        {
            guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "FooterCell") else
            {
                return nil
            }
            
            return view
        }
        else
        {
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        if section == self.cache.daysOfWeek.count - 1
        {
            return 20
        }
        else
        {
            return 0
        }
    }
    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
//    {
//        let formatter = DateFormatter.init()
//        formatter.dateFormat = "EEEE, MMMM d, yyyy"
//        guard let day = self.cache.calendar.date(byAdding: .day, value: section, to: self.cache.range.0) else
//        {
//            appError("could not add day to date")
//            return nil
//        }
//
//        return formatter.string(from: day)
//    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if let index = dataIndex(forIndexPath: indexPath)
        {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CheckInCell") as? CheckInCell else
            {
                return CheckInCell()
            }
            
            let checkin = self.cache.data[index]
            cell.populateWithData(checkin)
            
            return cell
        }
        else
        {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CheckInCell") as? CheckInCell else
            {
                return AddItemCell.init(style: .default, reuseIdentifier: nil)
            }
            
            cell.populateWithStub()
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let incrementAction = UIContextualAction.init(style: .normal, title: "+1")
        { (action, view, handler) in
            print("Incrementing...")
            handler(true)
        }
        let deleteAction = UIContextualAction.init(style: .destructive, title: "Delete")
        { (action, view, handler) in
            handler(true)
        }
        
        let actions = [incrementAction, deleteAction]
        let actionsConfig = UISwipeActionsConfiguration.init(actions: actions)
        
        return actionsConfig
    }
}
