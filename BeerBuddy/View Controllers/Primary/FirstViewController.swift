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
import DeepDiff

class FirstViewController: UIViewController
{
    @IBOutlet var tableView: UITableView!
    @IBOutlet var calendar: FSCalendar!
    @IBOutlet var calendarHeight: NSLayoutConstraint!
    
    var progressBar: UIView!
    var overflowProgressBar: UIView!
    var progressLabel: UILabel!
    
    var notificationObserver: Any?
    
    // guaranteed to always be valid
    var cache: (calendar: Calendar, range: (Date, Date), days: Int, data: [Int:[Model]], token: DataLayer.Token)!
    
    var data: DataLayer?
    {
        return (self.tabBarController as? RootViewController)?.data
    }
    
    func testAnimateProgressView()
    {
        if let progress = self.progressBar as? UIProgressView, let progress2 = self.overflowProgressBar as? UIProgressView
        {
            let goodRange = Float(0)...0.5
            let warningRange = goodRange.lowerBound...0.7

            let random = Float.random(in: 0...1.0)
            let random2 = Float.random(in: 0...random)

            progress.setProgress(random, animated: true)
            progress2.setProgress(random2, animated: true)
            
            if goodRange.contains(random)
            {
                //self.progressBar.progressTintColor = UIColor.init(red: 21/255.0, green: 126/255.0, blue: 251/255.0, alpha: 0.6)
                progress.progressTintColor = nil
            }
            else if warningRange.contains(random)
            {
                //self.progressBar.progressTintColor = UIColor.yellow
                progress.progressTintColor = UIColor.yellow.mixed(with: .black, by: 0.1)
            }
            else
            {
                //self.progressBar.progressTintColor = UIColor.red.withAlphaComponent(0.6)
                progress.progressTintColor = UIColor.red.withAlphaComponent(0.6)
            }
        }
    }
    
    deinit
    {
        if let observer = notificationObserver
        {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIColor.clear.pixel, for: .default)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        calendar.isHidden = true
        calendar.setScope(.week, animated: false)
        let range = Time.currentWeek()
        let midpoint = Date.init(timeIntervalSince1970: (range.0.timeIntervalSince1970 + range.0.timeIntervalSince1970) / 2)
        self.calendar.setCurrentPage(midpoint, animated: false)
        let bar = UIProgressView.init()
        bar.layer.cornerRadius = bar.intrinsicContentSize.height/2
        bar.progress = 0.5
        let bar2 = UIProgressView.init()
        bar2.layer.cornerRadius = bar2.intrinsicContentSize.height/2
        bar2.progress = 0.25
        bar.trackTintColor = UIColor.init(white: 0.95, alpha: 1)
        bar2.progressTintColor = UIColor.lightGray
        bar2.trackTintColor = UIColor.clear
        
        let progressView = UIView()
        progressView.translatesAutoresizingMaskIntoConstraints = false
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar2.translatesAutoresizingMaskIntoConstraints = false
        progressView.addSubview(bar)
        progressView.addSubview(bar2)
        var hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[bar]|", options: [], metrics: nil, views: ["bar":bar])
        var vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[bar]|", options: [], metrics: nil, views: ["bar":bar])
        NSLayoutConstraint.activate(hConstraints + vConstraints)
        hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[bar]|", options: [], metrics: nil, views: ["bar":bar2])
        vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[bar]|", options: [], metrics: nil, views: ["bar":bar2])
        NSLayoutConstraint.activate(hConstraints + vConstraints)
        let label = UILabel()
        label.text = "1.2 of 5.2 weekly drinks, including 1.2 drink overflow"
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.lightGray.mixed(with: .white, by: 0.1)
        label.textAlignment = .center
        let stack = UIStackView.init(arrangedSubviews: [progressView, label])
        stack.axis = .vertical
        stack.spacing = 4
        self.progressBar = bar
        self.overflowProgressBar = bar2
        self.progressLabel = label
        self.calendar.progressView = stack
        self.calendar.progressViewHeight = bar.intrinsicContentSize.height + 4 + label.intrinsicContentSize.height + 50
        self.navigationItem.title = nil
        
        tableSetup: do
        {
            self.tableView.register(DayHeaderCell.self, forHeaderFooterViewReuseIdentifier: "DayHeaderCell")
            self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "FooterCell")
            self.tableView.register(CheckInCell.self, forCellReuseIdentifier: "CheckInCell")
            self.tableView.register(AddItemCell.self, forCellReuseIdentifier: "AddItemCell")
            
            self.tableView.separatorStyle = .none
            
            self.tableView.allowsSelection = true
            self.tableView.allowsMultipleSelectionDuringEditing = false

            self.tableView.rowHeight = UITableViewAutomaticDimension
            self.tableView.estimatedRowHeight = 30 //TODO: actual estimate
        }
        
        self.reloadData(animated: false, fromScratch: false)
        
        self.notificationObserver = NotificationCenter.default.addObserver(forName: DataLayer.DataDidChangeNotification, object: nil, queue: OperationQueue.main)
        { [unowned `self`] _ in
            appDebug("requesting change with token \(self.cache?.token ?? DataLayer.NullToken)...")
            self.reloadData(animated: true, fromScratch: false)
        }
        
        self.data?.populateWithSampleData()
        //DispatchQueue.main.asyncAfter(deadline:.now() + 3)
        //{
        //    self.data?.populateWithSampleData()
        //}
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        var previousInset = self.tableView.contentInset
        previousInset.top = self.calendar.bounds.size.height
        self.tableView.contentInset = previousInset
    }
    
    // Reloads the current data based on the dates provided by the calendar. (The calendar is not reloaded.)
    func reloadData(animated: Bool, fromScratch: Bool = true)
    {
        let calendar = Time.calendar()
        //let range = Time.currentWeek()
        
        let from = self.calendar.currentPage
        let to = calendar.date(byAdding: .day, value: 7, to: from)!
        
        //self.cache?.token != nil && !fromScratch ? self.cache!.token : DataLayer.NullToken
        let token = DataLayer.NullToken
        
        self.data?.getModels(fromIncludingDate: from, toExcludingDate: to, withToken: token)
        {
            switch $0
            {
            case .error(let e):
                appError("could not get model data in reloadData")
            case .value(let v):
                if self.cache?.token != v.1
                {
                    appDebug("changes received with new token \(v.1)!")
                }
                
                // NEXT: QQQ:move this
                if self.cache == nil
                {
                    self.calendar.isHidden = false
                }
                
                // PERF: could be sorted, but need to double-check inequalities
                let sortedNewOps = SortedArray<Model>.init(unsorted: v.0.filter { !$0.metadata.deleted }) { return $0.checkIn.time < $1.checkIn.time }
                var outOps: [Int:[Model]] = [:]
                
                var startDay = from
                var nextDay = calendar.date(byAdding: .day, value: 1, to: startDay)!
                var i = 0
                
                // TODO: check inequalities
                while nextDay <= to
                {
                    let models: [Model] = sortedNewOps.filter { startDay <= $0.checkIn.time && $0.checkIn.time < nextDay }
                    
                    if models.count > 0
                    {
                        outOps[i] = models
                    }
                    
                    startDay = nextDay
                    nextDay = calendar.date(byAdding: .day, value: 1, to: startDay)!
                    i += 1
                }
                
                tableAdjustment: do
                {
                    let previousData = self.cache?.data ?? [:]
                    let previousDays = self.cache?.days ?? 0
                    let previousRange = self.cache?.range ?? (Date.distantPast, Date.distantFuture)
                    self.cache = (calendar, (from, to), i, outOps, v.1)
                    
                    if previousRange.0 == self.cache.range.0 && previousRange.1 == self.cache.range.1 && previousDays == self.cache.days
                    {
                        let unionKeys = Set(previousData.keys).union(Set(outOps.keys))
                        var allChanges: ChangeWithIndexPath = ChangeWithIndexPath.init(inserts: [], deletes: [], replaces: [], moves: [])
                        
                        for section in unionKeys
                        {
                            let old = (previousData[section] ?? [])//.map { $0.metadata.id }
                            let new = (outOps[section] ?? [])//.map { $0.metadata.id }
                            let changes = diff(old: old, new: new, algorithm: WagnerFischer())
                            
                            let converter = IndexPathConverter()
                            let indexPaths = converter.convert(changes: changes, section: section)
                            allChanges.moves += indexPaths.moves
                            allChanges.deletes += indexPaths.deletes
                            allChanges.replaces += indexPaths.replaces
                            allChanges.inserts += indexPaths.inserts
                        }
                        
                        self.tableView.reload(changesWithIndexPath: allChanges, insertionAnimation: UITableViewRowAnimation.fade, deletionAnimation: UITableViewRowAnimation.fade, replacementAnimation: .automatic, completion: { _ in })
                    }
                    else
                    {
                        // TODO: pretty animation
                        if false && !UIAccessibility.isReduceMotionEnabled && previousDays == self.cache?.days
                        {
                            if previousRange.1 <= self.cache.range.0
                            {
                                self.tableView.reloadSections(IndexSet.init(integersIn: 0..<self.tableView.numberOfSections), with: .left)
                            }
                            else if previousRange.0 >= self.cache.range.1
                            {
                                self.tableView.reloadSections(IndexSet.init(integersIn: 0..<self.tableView.numberOfSections), with: .right)
                            }
                            else
                            {
                                self.tableView.reloadData()
                            }
                        }
                        else
                        {
                            self.tableView.reloadData()
                        }
                    }
                }
                
                progressAdjustment: do
                {
                    let progress = Stats(self.data!).progress(forModels: v.0, inRange: from..<to)
                    
                    (self.progressBar as? UIProgressView)?.setProgress(progress.previous + progress.current, animated: true)
                    (self.overflowProgressBar as? UIProgressView)?.setProgress(progress.previous, animated: true)
                    
                    let drinksDrank = Stats(self.data!).percentToDrinks(progress.current + progress.previous, inRange: from..<to)
                    let drinksPrevious = Stats(self.data!).percentToDrinks(progress.previous, inRange: from..<to)
                    let drinksTotal = Stats(self.data!).percentToDrinks(1, inRange: from..<to)
                    
                    // TODO: monthly
                    let previousText = String.init(format: "including %.1f drink overflow", drinksPrevious)
                    let text = String.init(format: "%.1f of %.1f weekly drinks\(progress.previous > 0 ? ", \(previousText)" : "")", drinksDrank, drinksTotal)
                    
                    self.progressLabel.text = text
                }
            }
        }
    }
}

extension FirstViewController: UITableViewDataSource, UITableViewDelegate
{
    public func numberOfSections(in tableView: UITableView) -> Int
    {
        if self.cache == nil { return 0 }
        
        return self.cache.days
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if self.cache == nil { return 0 }
        
        return (self.cache.data[section]?.count ?? 0) + 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "DayHeaderCell")
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        if self.cache == nil { return }
        
        guard let headerView = view as? DayHeaderCell else
        {
            return
        }
        
        let formatter = DateFormatter.init()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        
        let day = self.cache.calendar.date(byAdding: .day, value: section, to: self.cache.range.0)!
        
        headerView.textLabel?.text = formatter.string(from: day)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        if self.cache == nil { return nil }
        
        if section == self.cache.days - 1
        {
            guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "FooterCell") else
            {
                return nil
            }
            
            if view.backgroundView == nil
            {
                let bgView = UIView()
                bgView.backgroundColor = .clear
                view.backgroundView = bgView
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
        
        if section == self.cache.days - 1
        {
            return 20
        }
        else
        {
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let sectionData = self.cache.data[indexPath.section] ?? []
        if indexPath.row < sectionData.count
        {
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: "CheckInCell") as? CheckInCell,
                let data = self.data
                else
            {
                return CheckInCell()
            }
            
            let checkin = sectionData[indexPath.row]
            cell.populateWithData(checkin, stats: Stats(data))

            return cell
        }
        else
        {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "AddItemCell") as? AddItemCell else
            {
                return AddItemCell()
            }

            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        let sectionData = self.cache.data[indexPath.section] ?? []
        if indexPath.row < sectionData.count
        {
            guard
                let cell = cell as? CheckInCell,
                let data = self.data
                else
            {
                return
            }
            
            let checkin = sectionData[indexPath.row]
            cell.populateWithData(checkin, stats: Stats(data))
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let sectionData = self.cache.data[indexPath.section] ?? []
        if indexPath.row >= sectionData.count
        {
            return UISwipeActionsConfiguration.init(actions: [])
        }
        
        var model = sectionData[indexPath.row]
        
        //let incrementAction = UIContextualAction.init(style: .normal, title: "+1")
        //{ (action, view, handler) in
        //    print("Incrementing...")
        //    handler(true)
        //}
        let deleteAction = UIContextualAction.init(style: .destructive, title: "Delete")
        { (action, view, handler) in
            appDebug("attempting delete")
            model.delete()
            if let data = self.data
            {
                data.save(model: model) { _ in handler(false) }
            }
            else
            {
                handler(false)
            }
        }
        
        //let actions = [incrementAction, deleteAction]
        let actions = [deleteAction]
        let actionsConfig = UISwipeActionsConfiguration.init(actions: actions)
        
        return actionsConfig
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == (self.cache.data[indexPath.section]?.count ?? 0)
        {
            let section = indexPath.section
            
            let startDay = self.cache.calendar.date(byAdding: .day, value: section, to: self.cache.range.0)!
            let endDay = self.cache.calendar.date(byAdding: .day, value: section + 1, to: self.cache.range.0)!
            let lastDate = self.cache.data[section]?.last?.checkIn.time ?? startDay
            let nextDate = self.cache.calendar.date(byAdding: .minute, value: 1, to: lastDate)!
            
            let todayComp = self.cache.calendar.dateComponents([.day, .month, .year], from: Date())
            let startComp = self.cache.calendar.dateComponents([.day, .month, .year], from: startDay)
            
            if todayComp == startComp
            {
                appDebug("it's today!")
                (self.tabBarController as? RootViewController)?.showCheckInDrawer()
                return
            }
            
            let date: Date
            
            if nextDate >= endDay
            {
                // AB: exceptional case where we're down to the last minute in a day
                date = Date.init(timeIntervalSince1970: (lastDate.timeIntervalSince1970 + endDay.timeIntervalSince1970) / 2)
            }
            else
            {
                date = nextDate
            }
            
            (self.tabBarController as? RootViewController)?.showCheckInDrawer(withModel: nil, orDate: date)
        }
        else if let item = self.cache.data[indexPath.section]?[indexPath.row]
        {
            (self.tabBarController as? RootViewController)?.showCheckInDrawer(withModel: item)
        }
    }
}

extension FirstViewController: FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance
{
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool)
    {
        self.calendarHeight.constant = bounds.size.height
        print("Calendar bounds did change: \(calendar.scope.rawValue)")
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar)
    {
        let components = DataLayer.calendar.dateComponents([.month, .year], from: calendar.currentPage)
        
        let monthFormat = DateFormatter()
        monthFormat.dateFormat = "MM"
        let month = monthFormat.monthSymbols[components.month! - 1]
        
        self.navigationItem.title = "\(month) \(components.year!)"
        
        reloadData(animated: false, fromScratch: true)
    }
    
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int
    {
        do
        {
            let data = try self.data?.getModels(fromIncludingDate: date, toExcludingDate: date.addingTimeInterval(24 * 60 * 60)).0
            return data?.count ?? 0
        }
        catch
        {
            fatalError("\(error)")
        }
    }
    
    @IBAction func todayTapped(_ sender: UIBarButtonItem)
    {
        self.calendar.setCurrentPage(Date(), animated: true)
    }
}

//{
//    if let token = Defaults.untappdToken
//    {
//        Untappd.UserCheckIns(token)
//        { (checkIns, error) in
//        }
//        return false
//    }
//
//    if qqqPopup == nil
//    {
//        untappd: do
//        {
//            let untappdVC = UntappdLoginViewController.init
//            { (token, e) in
//                if let e = e
//                {
//                    print("token error: \(e)")
//                }
//                else
//                {
//                    print("found token: \(token)")
//                    Defaults.untappdToken = token
//                    //self.dismiss(animated: true, completion: nil)
//                    self.qqqPopup?.dismiss(animated: true, completion: nil)
//                    self.qqqPopup = nil
//                }
//            }
//            untappdVC.modalPresentationStyle = .popover
//            self.present(untappdVC, animated: true, completion: nil)
//            untappdVC.load()
//            self.qqqPopup = untappdVC
//        }
//
//        popup: do
//        {
//            break popup
//
//            let vc = UIViewController()
//            vc.view.backgroundColor = UIColor.red
//            let label = UITextView.init()
//            label.text = "This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah. This is a test label for fitting. It has multiple lines for testing. Blah blah blah."
//            label.font = UIFont.systemFont(ofSize: 12)
//            label.isEditable = false
//            label.isSelectable = false
//            label.isScrollEnabled = false
//            label.textContainerInset = UIEdgeInsets.zero
//            label.translatesAutoresizingMaskIntoConstraints = false
//            vc.view.addSubview(label)
//            let labelHConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(32)-[label]-(32)-|", options: [], metrics: nil, views: ["label":label])
//            let labelVConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(64)-[label]-(64)-|", options: [], metrics: nil, views: ["label":label])
//            NSLayoutConstraint.activate(labelHConstraints + labelVConstraints)
//
//            vc.preferredContentSize = CGSize.init(width: 400, height: 0)
//
//            let popup = ScrollingPopupViewController.init()
//            popup.viewController = vc
//            popup.delegate = self
//
//            //.custom? A custom view presentation style that is managed by a custom presentation controller and one or more custom animator objects.
//            popup.modalPresentationStyle = .overFullScreen
//
//
//            self.qqqPopup = popup
//
//            self.present(popup, animated: false)
//            {
//            }
//        }
//    }
//}
