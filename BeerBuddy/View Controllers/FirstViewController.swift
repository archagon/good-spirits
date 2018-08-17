//
//  FirstViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit
import DrawerKit
import DataLayer

extension FirstViewController: CheckInViewControllerDelegate
{
    public func defaultCheckIn(for: CheckInViewController) -> Model.Drink
    {
        let defaultPrice: Double = 5
        let defaultDrink = Model.Drink.init(name: nil, style: DrinkStyle.defaultStyle, abv: DrinkStyle.defaultStyle.defaultABV, price: defaultPrice, volume: DrinkStyle.defaultStyle.defaultVolume)
        
        do
        {
            if let model = try self.data.getLastAddedModel()
            {
                return model.checkIn.drink
            }
            else
            {
                return defaultDrink
            }
        }
        catch
        {
            appError("\(error)")
            return defaultDrink
        }
    }
    
    public func calendar(for: CheckInViewController) -> Calendar
    {
        return self.cache.calendar
    }
    
    public func committed(drink: Model.Drink, for: CheckInViewController)
    {
        let range = Time.currentWeek()
        
        let randomTime = range.0.timeIntervalSince1970 + TimeInterval.random(in: 0..<(range.1.timeIntervalSince1970 - range.0.timeIntervalSince1970))
        let randomDate = Date.init(timeIntervalSince1970: randomTime)
        
        let model = Model.init(metadata: Model.Metadata.init(id: GlobalID.init(siteID: self.data!.owner, operationIndex: DataLayer.wildcardIndex), creationTime: Date()), checkIn: Model.CheckIn.init(untappdId: nil, time: randomDate, drink: drink))
        
        self.data.save(model: model)
        {
            switch $0
            {
            case .error(let e):
                appError("\(e)")
            case .value(let v):
                break
            }
        }
    }
}

extension FirstViewController: UITabBarControllerDelegate, ScrollingPopupViewControllerDelegate
{
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool
    {
        if viewController is StubViewController
        {
            pulleyTest: do
            {
                //break pulleyTest
                let storyboard = UIStoryboard.init(name: "Controllers", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "CheckIn") as! CheckInViewController
                controller.delegate = self
                let vc = UIViewController()
                
//                let pulley = PulleyViewController.init(contentViewController: vc, drawerViewController: controller)
                
//                let pulley = ISHPullUpViewController.init()
//                pulley.contentViewController = vc
//                pulley.bottomViewController = controller

                var configuration = DrawerConfiguration.init()
                configuration.fullExpansionBehaviour = .leavesCustomGap(gap: 100)
                configuration.timingCurveProvider = UISpringTimingParameters(dampingRatio: 0.8)
                configuration.cornerAnimationOption = .alwaysShowBelowStatusBar
                
                var handleViewConfiguration = HandleViewConfiguration()
                handleViewConfiguration.autoAnimatesDimming = false
                configuration.handleViewConfiguration = handleViewConfiguration
                
                let drawerShadowConfiguration = DrawerShadowConfiguration(shadowOpacity: 0.25,
                                                                          shadowRadius: 4,
                                                                          shadowOffset: .zero,
                                                                          shadowColor: .black)
                configuration.drawerShadowConfiguration = drawerShadowConfiguration
                
                let pulley = DrawerDisplayController.init(presentingViewController: self, presentedViewController: controller, configuration: configuration, inDebugMode: false)
                self.drawerDisplayController = pulley
                
                self.present(controller, animated: true, completion: nil)
                
                return false
            }
            
            testABV: do
            {
                let storyboard = UIStoryboard.init(name: "Controllers", bundle: nil)
                let controller = storyboard.instantiateViewController(withIdentifier: "ABV") as! ABVViewController
                let nav = UINavigationController.init(rootViewController: controller)
                self.present(nav, animated: true, completion: nil)
                
                return false
            }
            
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

class FirstViewController: UIViewController, DrawerCoordinating
{
    public var drawerDisplayController: DrawerDisplayController?
    
    
    
    public var qqqPopup: UIViewController?
    
    //let debugPast: TimeInterval = -60 * 60 * 24 * 7
    let debugPast: TimeInterval = -60 * 60 * 24 * 50 * 10
    
    @IBOutlet var tableView: UITableView!
    
    var data: DataLayer!
    
    // guaranteed to always be valid
    var cache: (calendar: Calendar, daysOfWeek: [Weekday], range: (Date, Date), data: [Model], token: DataLayer.Token)!
    
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
        
        let path: String? = (NSTemporaryDirectory() as NSString).appendingPathComponent("\(UUID()).db")
        guard let dataImpl = Data_GRDB.init(withDatabasePath: path) else
        {
            fatalError("database could not be created")
        }
        
        self.data = DataLayer.init(withStore: dataImpl)
        
        //do
        //{
        //    let checkins = try data.checkins(from: Date.init(timeInterval: debugPast, since: Date()), to: Date.distantFuture)
        //    dump(checkins)
        //}
        //catch
        //{
        //    assert(false, "Error: \(error)")
        //}
        
        //reloadData()
        
        NotificationCenter.default.addObserver(forName: DataLayer.DataDidChangeNotification, object: nil, queue: OperationQueue.main)
        { _ in
            let calendar = Time.calendar()
            let daysOfWeek = Time.daysOfWeek()
            let range = Time.currentWeek()
            
            print("Requesting change with token \(self.cache?.token ?? DataLayer.NullToken)...")
            
            self.data.getModels(fromIncludingDate: range.0, toExcludingDate: range.1, withToken: self.cache?.token ?? DataLayer.NullToken)
            {
                switch $0
                {
                case .error(let e):
                    fatalError("\(e)")
                case .value(let v):
                    // NEXT: deletions
                    print("Changes received with new token \(v.1)!")
                    var newOps: [GlobalID:Model] = [:]
                    for op in v.0
                    {
                        newOps[op.metadata.id] = op
                    }
                    var updatedOps = self.cache?.data ?? []
                    for i in 0..<updatedOps.count
                    {
                        let op = updatedOps[i]
                        if let newOp = newOps[op.metadata.id]
                        {
                            updatedOps[i] = newOp
                            newOps[op.metadata.id] = nil
                        }
                    }
                    updatedOps += Array(newOps.values)
                    updatedOps = updatedOps.filter { !$0.metadata.deleted }
                    updatedOps.sort { $0.checkIn.time < $1.checkIn.time }
                    
                    self.cache = (calendar, daysOfWeek, range, updatedOps, v.1)
                    self.tableView.reloadData()
                }
            }
        }
        
        self.data.populateWithSampleData()
        //DispatchQueue.main.asyncAfter(deadline:.now() + 3)
        //{
        //    self.data.populateWithSampleData()
        //}
    }
    
    func reloadData()
    {
        //let oldCache = self.cache
        
//        let calendar = Time.calendar()
//        let daysOfWeek = Time.daysOfWeek()
//        let range = Time.currentWeek()
//
//        self.data.getModels(fromIncludingDate: range.0, toExcludingDate: range.1)
//        {
//            switch $0
//            {
//            case .error(let e):
//                fatalError("\(e)")
//            case .value(let v):
//                // TODO: fancy animations, if needed
//                self.cache = (calendar, daysOfWeek, range, v.0, v.1)
//                self.tableView.reloadData()
//            }
//        }
        
        self.tableView.reloadData()
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
        if self.cache == nil { return nil }
        
        var j = indexPath.row
        for (i, item) in self.cache.data.enumerated()
        {
            guard let day = Weekday.init(fromDate: item.checkIn.time, withCalendar: self.cache.calendar) else
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
        if self.cache == nil { return 0 }
        
        // PERF: slow
        let count = self.cache.data.reduce(0)
        { (total, item) -> Int in
            let day = Weekday.init(fromDate: item.checkIn.time, withCalendar: self.cache.calendar)!
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
        if self.cache == nil { return nil }
        
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
        if self.cache == nil { return nil }
        
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
        if self.cache == nil { return 0 }
        
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
        guard let index = dataIndex(forIndexPath: indexPath) else
        {
            return nil
        }
        
        var model = self.cache.data[index]
        
        //let incrementAction = UIContextualAction.init(style: .normal, title: "+1")
        //{ (action, view, handler) in
        //    print("Incrementing...")
        //    handler(true)
        //}
        let deleteAction = UIContextualAction.init(style: .destructive, title: "Delete")
        { (action, view, handler) in
            print("Attempting delete!")
            model.delete()
            self.data.save(model: model) { _ in handler(false) }
        }
        
        //let actions = [incrementAction, deleteAction]
        let actions = [deleteAction]
        let actionsConfig = UISwipeActionsConfiguration.init(actions: actions)
        
        return actionsConfig
    }
}
