//
//  FirstViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
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
    var defaultsNotificationObserver: Any?
    
    // guaranteed to always be valid; section 0 represents Untappd pending changes
    var cache: (calendar: Calendar, range: (Date, Date), days: Int, data: [Int:[Model]], token: DataLayer.Token, prefs: (Double, Double?))!
    
    var data: DataLayer?
    {
        return (self.tabBarController as? RootViewController)?.data
    }
    
    deinit
    {
        if let observer = notificationObserver
        {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = defaultsNotificationObserver
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

        self.tabBarItem.badgeColor = Untappd.themeColor.darkened(by: 0.05)
        
        setupCalendar: do
        {
            calendar.setScope(.week, animated: false)
            
            if Defaults.weekStartsOnMonday
            {
                self.calendar.firstWeekday = 2
            }
            else
            {
                self.calendar.firstWeekday = 1
            }
            
            let range = Time.currentWeek()
            let midpoint = Date.init(timeIntervalSince1970: (range.0.timeIntervalSince1970 + range.0.timeIntervalSince1970) / 2)
            fixCalendar(withDate: midpoint)
            
            let bar = UIProgressView.init()
            let bar2 = UIProgressView.init()
            let progressView = UIView()
            progressView.addSubview(bar)
            progressView.addSubview(bar2)
            
            let label = UILabel()
            
            let guide1 = UIView()
            let guide2 = UIView()
            
            let stack = UIStackView.init(arrangedSubviews: [guide1, progressView, label, guide2])
            stack.frame = CGRect.init(x: 0, y: 0, width: 100, height: 100)
            stack.axis = .vertical
            stack.spacing = 6
            
            progressView.translatesAutoresizingMaskIntoConstraints = false
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar2.translatesAutoresizingMaskIntoConstraints = false
            label.translatesAutoresizingMaskIntoConstraints = false
            guide1.translatesAutoresizingMaskIntoConstraints = false
            guide2.translatesAutoresizingMaskIntoConstraints = false
            
            guide1.heightAnchor.constraint(equalTo: guide2.heightAnchor).isActive = true
            var hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[bar]|", options: [], metrics: nil, views: ["bar":bar])
            var vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[bar]|", options: [], metrics: nil, views: ["bar":bar])
            NSLayoutConstraint.activate(hConstraints + vConstraints)
            hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[bar]|", options: [], metrics: nil, views: ["bar":bar2])
            vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[bar]|", options: [], metrics: nil, views: ["bar":bar2])
            NSLayoutConstraint.activate(hConstraints + vConstraints)
            
            bar.layer.cornerRadius = bar.intrinsicContentSize.height/2
            bar2.layer.cornerRadius = bar2.intrinsicContentSize.height/2
            bar.trackTintColor = UIColor.init(white: 0.9, alpha: 1)
            bar2.progressTintColor = UIColor.lightGray
            bar2.trackTintColor = UIColor.clear
            
            label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
            label.textColor = UIColor.gray //UIColor.lightGray.mixed(with: .white, by: 0.1)
            label.textAlignment = .center
            
            calendar.allowsSelection = false
            
            //bar.progress = 0.5
            label.text = "Stats"
            
            self.progressBar = bar
            self.overflowProgressBar = bar2
            self.progressLabel = label
            self.calendar.progressView = stack
            self.calendar.progressViewHeight = bar.intrinsicContentSize.height + 6 + label.intrinsicContentSize.height + 10
            
            calendar.isHidden = true
            self.navigationItem.title = nil
        }
        
        tableSetup: do
        {
            self.tableView.register(DayHeaderCell.self, forHeaderFooterViewReuseIdentifier: "DayHeaderCell")
            self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "UntappdHeaderCell")
            self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "FooterCell")
            self.tableView.register(CheckInCell.self, forCellReuseIdentifier: "CheckInCell")
            self.tableView.register(AddItemCell.self, forCellReuseIdentifier: "AddItemCell")
            
            self.tableView.separatorStyle = .none
            
            self.tableView.allowsSelection = true
            self.tableView.allowsMultipleSelectionDuringEditing = false

            self.tableView.rowHeight = UITableViewAutomaticDimension
            self.tableView.estimatedRowHeight = 50
        }
        
        self.notificationObserver = NotificationCenter.default.addObserver(forName: DataLayer.DataDidChangeNotification, object: nil, queue: OperationQueue.main)
        { [unowned `self`] _ in
            appDebug("requesting database changes with token \(self.cache?.token ?? DataLayer.NullToken)...")
            self.reloadData(animated: true, fromScratch: false)
        }
        
        self.notificationObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: OperationQueue.main)
        { [unowned `self`] _ in
            if Defaults.weekStartsOnMonday && self.calendar.firstWeekday != 2
            {
                let date = DataLayer.calendar.date(byAdding: .day, value: 3, to: self.calendar.currentPage)!
                self.calendar.firstWeekday = 2
                self.fixCalendar(withDate: date)
            }
            else if !Defaults.weekStartsOnMonday && self.calendar.firstWeekday != 1
            {
                let date = DataLayer.calendar.date(byAdding: .day, value: 3, to: self.calendar.currentPage)!
                self.calendar.firstWeekday = 1
                self.fixCalendar(withDate: date)
            }
            
            if Defaults.untappdToken != nil && self.tableView.refreshControl == nil
            {
                self.setupUntappdPullToRefresh(true)
            }
            else if Defaults.untappdToken == nil && self.tableView.refreshControl != nil
            {
                self.setupUntappdPullToRefresh(false)
            }
            
            if Defaults.standardDrinkSize != self.cache?.prefs.0 || Defaults.weeklyLimit != self.cache?.prefs.1
            {
                self.reloadData(animated: false, fromScratch: true)
            }
        }
        
        self.reloadData(animated: false, fromScratch: false)
        setupUntappdPullToRefresh(Defaults.untappdToken != nil)
    }
    
    func fixCalendar(withDate date: Date)
    {
        // KLUDGE: ensures that currentPage is set to the correct value by the time data is reloaded
        let offset = date.addingTimeInterval(-100 * 24 * 60 * 60)
        let offset2 = date
        self.calendar.setCurrentPage(offset, animated: false)
        self.calendar.setCurrentPage(offset2, animated: false)
    }
    
    func setupUntappdPullToRefresh(_ enable: Bool)
    {
        if enable
        {
            if self.tableView.refreshControl == nil
            {
                let widget = UIRefreshControl()
                let attributes: [NSAttributedStringKey:Any] = [
                    .font:UIFont.systemFont(ofSize: 13, weight: .semibold),
                    .foregroundColor:Appearance.darkenedThemeColor
                ]
                widget.attributedTitle = NSAttributedString.init(string: "Refreshing Untappd data...", attributes: attributes)
                widget.tintColor = Appearance.darkenedThemeColor
                widget.addTarget(self, action: #selector(refreshUntappd), for: .valueChanged)
                
                self.tableView.refreshControl = widget
                widget.layer.zPosition = -1
            }
        }
        else
        {
            self.tableView.refreshControl = nil
        }
    }
    
    @objc func refreshUntappd(_ sender: UIRefreshControl)
    {
        if let controller = (self.tabBarController as? RootViewController)
        {
            controller.syncUntappd
            { err in
                sender.endRefreshing()
                
                switch err
                {
                case .error(let error):
                    // KLUDGE: without this, the refresh control does not stop
                    let when = DispatchTime.now() + 0.2
                    DispatchQueue.main.asyncAfter(deadline: when)
                    {
                        appAlert("Could not sync with Untappd: \(error.localizedDescription).")
                    }
                case .value(_):
                    break
                }
            }
        }
        else
        {
            sender.endRefreshing()
        }
    }
    
    override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        var previousInset = self.tableView.contentInset
        previousInset.top = self.calendar.bounds.size.height
        self.tableView.contentInset = previousInset
        self.tableView.scrollIndicatorInsets = previousInset
    }
    
    // Reloads the current data based on the dates provided by the calendar. (The calendar is not reloaded.)
    func reloadData(animated: Bool, fromScratch: Bool = true)
    {
        appDebug("reloading data...")
        
        let calendar = DataLayer.calendar
        //let range = Time.currentWeek()
        
        let from = DataLayer.calendar.date(bySettingHour: 0, minute: 0, second: 0, of: self.calendar.currentPage)!
        assert(from == self.calendar.currentPage)
        let to = calendar.date(byAdding: .day, value: 7, to: from)!
        
        //self.cache?.token != nil && !fromScratch ? self.cache!.token : DataLayer.NullToken
        let token = DataLayer.NullToken
        
        self.data?.getModels(fromIncludingDate: from, toExcludingDate: to, withToken: token, includingDeleted: false, includingUntappdPending: true)
        { [weak `self`] in
            guard let `self` = self else
            {
                return
            }
            
            switch $0
            {
            case .error(let e):
                appError("could not get model data in reloadData -- \(e.localizedDescription)")
            case .value(let v):
                appDebug("data loaded!")
                
                if self.cache?.token != v.1
                {
                    appDebug("changes received with new token \(v.1)!")
                }
                
                // TODO: KLUDGE: this doesn't exactly belong here
                if self.cache == nil
                {
                    self.calendar.isHidden = false
                }
                
                // PERF: could be sorted, but need to double-check inequalities
                let ops = v.0
                let sortedRegularOps = ops.filter { $0.checkIn.untappdId == nil || $0.checkIn.untappdApproved }
                let sortedUntappdOps = ops.filter { $0.checkIn.untappdId != nil && !$0.checkIn.untappdApproved }
                var outOps: [Int:[Model]] = [:]
                
                var startDay = from
                var nextDay = calendar.date(byAdding: .day, value: 1, to: startDay)!
                var i = 0
                var mi = 0
                
                assert(sortedRegularOps.sorted(by: { $0.checkIn.time < $1.checkIn.time }) == sortedRegularOps)
                
                // TODO: check inequalities
                // PERF: this is very slow at O(n)^2, need to iterate as in Stats
                while nextDay <= to
                {
                    //var models: [Model] = []
                    //while mi < sortedRegularOps.count
                    //{
                    //    let model = sortedRegularOps[i]
                    //    if startDay <= model.checkIn.time && model.checkIn.time < nextDay
                    //    {
                    //        models.append(model)
                    //        mi += 1
                    //    }
                    //    else
                    //    {
                    //        break
                    //    }
                    //}
                    
                    let models: [Model] = sortedRegularOps.filter { startDay <= $0.checkIn.time && $0.checkIn.time < nextDay }
                    
                    if models.count > 0
                    {
                        outOps[i + 1] = models
                    }
                    
                    startDay = nextDay
                    nextDay = calendar.date(byAdding: .day, value: 1, to: startDay)!
                    i += 1
                }
                if sortedUntappdOps.count > 0
                {
                    outOps[0] = Array(sortedUntappdOps)
                }
                
                tableAdjustment: do
                {
                    let previousData = self.cache?.data ?? [:]
                    let previousDays = self.cache?.days ?? 0
                    let previousRange = self.cache?.range ?? (Date.distantPast, Date.distantFuture)
                    self.cache = (calendar, (from, to), i, outOps, v.1, (Defaults.standardDrinkSize, Defaults.weeklyLimit))
                    
                    if previousRange.0 == self.cache.range.0 && previousRange.1 == self.cache.range.1 && previousDays == self.cache.days
                    {
                        let unionKeys = Array(Set(previousData.keys).union(Set(outOps.keys))).sorted()
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
                        
                        if allChanges.moves.isEmpty && allChanges.deletes.isEmpty && allChanges.replaces.isEmpty && allChanges.inserts.isEmpty
                        {
                            // nothing to do
                        }
                        else
                        {
                            self.tableView.reload(changesWithIndexPath: allChanges, insertionAnimation: UITableViewRowAnimation.fade, deletionAnimation: UITableViewRowAnimation.fade, replacementAnimation: .automatic, completion:
                            { _ in
                            })
                            
                            // AB: only scroll to non-untappd rows, since untappd check-in confirmations should be rapid
                            //for change in allChanges.inserts.reversed()
                            //{
                            //    let model = self.cache.data[change.section]![change.row]
                            //    if model.checkIn.untappdId == nil
                            //    {
                            //        self.tableView.scrollToRow(at: change, at: .middle, animated: true)
                            //        break
                            //    }
                            //}
                            
                            self.calendar.reloadData()
                        }
                    }
                    else
                    {
                        // TODO: pretty animation
                        if false && /*!UIAccessibility.isReduceMotionEnabled &&*/ previousDays == self.cache?.days
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
                
                self.tabBarItem.badgeValue = sortedUntappdOps.count > 0 ? "\(sortedUntappdOps.count)" : nil
                
                self.updateTitle()
                
                progressAdjustment: do
                {
                    if let data = self.data
                    {
                        let aProgress = Stats(data).progress(forModels: Array(sortedRegularOps), inRange: from..<to)
                        
                        // KLUDGE: BUGFIX: ensures that table view animations don't interfere with animation
                        let when = DispatchTime.now() + 0.1
                        DispatchQueue.main.asyncAfter(deadline: when)
                        {
                            if let progress = aProgress
                            {
                                (self.progressBar as? UIProgressView)?.setProgress(progress.previous + progress.current, animated: true)
                                (self.overflowProgressBar as? UIProgressView)?.setProgress(progress.previous, animated: true)
                                
                                let totalProgress = progress.previous + progress.current
                                if totalProgress <= 0.3
                                {
                                    (self.progressBar as? UIProgressView)?.progressTintColor = Appearance.greenProgressColor
                                }
                                else if totalProgress <= 0.85
                                {
                                    (self.progressBar as? UIProgressView)?.progressTintColor = Appearance.blueProgressColor
                                }
                                else if totalProgress <= 1
                                {
                                    (self.progressBar as? UIProgressView)?.progressTintColor = Appearance.orangeProgressColor
                                }
                                else
                                {
                                    (self.progressBar as? UIProgressView)?.progressTintColor = Appearance.redProgressColor
                                }
                            }
                            else
                            {
                                (self.progressBar as? UIProgressView)?.setProgress(1, animated: false)
                                (self.overflowProgressBar as? UIProgressView)?.setProgress(0, animated: false)
                                (self.progressBar as? UIProgressView)?.progressTintColor = Appearance.blueProgressColor
                            }
                        }
                        
                        if
                            let progress = aProgress,
                            let drinksDrank = Stats(data).percentToDrinks(progress.current + progress.previous, inRange: from..<to),
                            let drinksPrevious = Stats(data).percentToDrinks(progress.previous, inRange: from..<to),
                            let drinksTotal = Stats(data).percentToDrinks(1, inRange: from..<to)
                        {
                            let previousText = String.init(format: "including %.1f drink overflow", drinksPrevious)
                            let text = String.init(format: "%.1f of %.1f weekly drinks\(progress.previous > 0 ? ", \(previousText)" : "")", drinksDrank, drinksTotal)
                            
                            self.progressLabel.text = text
                        }
                        else
                        {
                            let totalDrinks = (try? Stats(data).drinks(inRange: from..<to)) ?? 0
                            
                            let text = String.init(format: "%.1f weekly drinks", totalDrinks)
                            
                            self.progressLabel.text = text
                        }
                    }
                }
            }
        }
    }
    
    func showPendingUntappd()
    {
        if self.cache.data[0]?.count ?? 0 > 0
        {
            self.tableView.scrollToRow(at: IndexPath.init(row: 0, section: 0), at: .top, animated: true)
        }
    }
}

extension FirstViewController: UITableViewDataSource, UITableViewDelegate
{
    public func numberOfSections(in tableView: UITableView) -> Int
    {
        if self.cache == nil { return 0 }
        
        return self.cache.days + 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if self.cache == nil { return 0 }
        
        if section == 0
        {
            // AB: no "add item" row for Untappd section
            return (self.cache.data[section]?.count ?? 0)
        }
        else
        {
            return (self.cache.data[section]?.count ?? 0) + 1
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        if section == 0
        {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UntappdHeaderCell")
        }
        else
        {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "DayHeaderCell")
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        if self.cache == nil { return }
        
        if section == 0
        {
            guard let headerView = view as? UITableViewHeaderFooterView else
            {
                return
            }
            
            if headerView.backgroundView == nil
            {
                headerView.backgroundView = UIView()
            }
            headerView.backgroundView?.backgroundColor = Untappd.themeColor.mixed(with: .white, by: 0.8)
            
            headerView.textLabel?.text = "Pending Untappd Check-Ins"
            headerView.textLabel?.textColor = Untappd.themeColor.darkened(by: 0.2)
        }
        else
        {
            guard let headerView = view as? DayHeaderCell else
            {
                return
            }
            
            let formatter = DateFormatter.init()
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
            let day = self.cache.calendar.date(byAdding: .day, value: section - 1, to: self.cache.range.0)!
            
            headerView.textLabel?.text = formatter.string(from: day)
            headerView.textLabel?.textColor = UIColor.black
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        if section == 0
        {
            if self.cache.data[section]?.count ?? 0 > 0
            {
                return 40
            }
            else
            {
                return 0
            }
        }
        else
        {
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    {
        if self.cache == nil { return nil }
        
        if section == 0 || section == tableView.numberOfSections - 1
        {
            guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "FooterCell") else
            {
                return nil
            }
            
            if view.backgroundView == nil
            {
                view.backgroundView = UIView()
            }
            
            return view
        }
        else
        {
            return nil
        }
        
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
    {
        if self.cache == nil { return }
        
        if section == 0
        {
            (view as? UITableViewHeaderFooterView)?.backgroundView?.backgroundColor = Untappd.themeColor.darkened(by: 0.0)
        }
        else
        {
            (view as? UITableViewHeaderFooterView)?.backgroundView?.backgroundColor = .clear
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        if self.cache == nil { return 0 }
        
        if section == tableView.numberOfSections - 1
        {
            // TODO: just make this an inset
            return 20
        }
        else if section == 0 && self.cache.data[0]?.count ?? 0 > 0
        {
            return 0.5
        }
        else
        {
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if self.cache == nil { return UITableViewCell() }
        
        let section = indexPath.section
        let sectionData = self.cache.data[section] ?? []
        if section == 0 || indexPath.row < sectionData.count
        {
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: "CheckInCell") as? CheckInCell,
                let data = self.data
                else
            {
                return CheckInCell()
            }
            
            let checkin = sectionData[indexPath.row]
            cell.populateWithData(checkin, stats: Stats(data), isUntappd: (section == 0))

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
        if self.cache == nil { return }
        
        let section = indexPath.section
        let sectionData = self.cache.data[section] ?? []
        if section == 0 || indexPath.row < sectionData.count
        {
            guard
                let cell = cell as? CheckInCell,
                let data = self.data
                else
            {
                return
            }
            
            let checkin = sectionData[indexPath.row]
            cell.populateWithData(checkin, stats: Stats(data), isUntappd: (section == 0))
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        if self.cache == nil { return UISwipeActionsConfiguration.init(actions: []) }
        
        let section = indexPath.section
        let sectionData = self.cache.data[section] ?? []
        if section == 0
        {
            var model = sectionData[indexPath.row]
            
            let volumes = model.checkIn.drink.style.assortedVolumes
            var actions: [UIContextualAction] = []
            for i in 0..<min(volumes.count, 3)
            {
                let volume = volumes[i]
                let volumeAction = UIContextualAction.init(style: .normal, title: "Approve\n\(Format.format(volume: volume))")
                { [weak `self`] (action, view, handler) in
                    appDebug("attempting approve")
                    model.approve()
                    model.checkIn.drink.volume = volume
                    if let data = self?.data
                    {
                        data.save(model: model) { _ in handler(false) }
                    }
                    else
                    {
                        handler(false)
                    }
                }
                volumeAction.backgroundColor = Appearance.themeColor.darkened(by: 0.07 * CGFloat(i))
                actions.append(volumeAction)
            }
            
            let actionsConfig = UISwipeActionsConfiguration.init(actions: actions)
            actionsConfig.performsFirstActionWithFullSwipe = false
            
            return actionsConfig
        }
        else
        {
            if indexPath.row >= sectionData.count
            {
                return UISwipeActionsConfiguration.init(actions: [])
            }
            
            let model = sectionData[indexPath.row]
            
            let section = indexPath.section
            let sectionDay = section - 1
            let startDay = self.cache.calendar.date(byAdding: .day, value: sectionDay, to: self.cache.range.0)!
            let endDay = self.cache.calendar.date(byAdding: .day, value: sectionDay + 1, to: startDay)!
            let lastDate = self.cache.data[section]?.last?.checkIn.time ?? startDay
            
            var actions: [UIContextualAction] = []
            let againAction = UIContextualAction.init(style: .normal, title: "Add\nOne")
            { [weak `self`] (action, view, handler) in
                if let data = self?.data
                {
                    var newModel = model
                    
                    newModel.metadata = Model.Metadata.init(id: GlobalID.init(siteID: data.owner, operationIndex: DataLayer.wildcardIndex), creationTime: Date())
                    newModel.checkIn.untappdId = nil
                    newModel.checkIn.untappdApproved = false
                    newModel.checkIn.time = self?.checkInDate(forEndDay: endDay, withLastDay: lastDate) ?? Date()
                    
                    data.save(model: newModel) { _ in handler(false) }
                }
                else
                {
                    handler(false)
                }
            }
            againAction.backgroundColor = Appearance.themeColor.darkened(by: 0)
            actions.append(againAction)
            
            let actionsConfig = UISwipeActionsConfiguration.init(actions: actions)
            actionsConfig.performsFirstActionWithFullSwipe = true
            
            return actionsConfig
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        if self.cache == nil { return UISwipeActionsConfiguration.init(actions: []) }
        
        let section = indexPath.section
        let sectionData = self.cache.data[section] ?? []
        if section != 0 && indexPath.row >= sectionData.count
        {
            return UISwipeActionsConfiguration.init(actions: [])
        }
        
        var model = sectionData[indexPath.row]
        
        //let incrementAction = UIContextualAction.init(style: .normal, title: "+1")
        //{ (action, view, handler) in
        //    print("Incrementing...")
        //    handler(true)
        //}
        let deleteAction = UIContextualAction.init(style: .destructive, title: (section == 0 ? "Dismiss" : "Delete"))
        { [weak `self`] (action, view, handler) in
            appDebug("attempting delete")
            model.delete()
            if let data = self?.data
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
        
        if self.cache == nil { return }
        
        let section = indexPath.section
        if section != 0 && indexPath.row == (self.cache.data[section]?.count ?? 0)
        {
            let section = indexPath.section
            let sectionDay = section - 1
            
            let startDay = self.cache.calendar.date(byAdding: .day, value: sectionDay, to: self.cache.range.0)!
            let endDay = self.cache.calendar.date(byAdding: .day, value: sectionDay + 1, to: startDay)!
            let lastDate = self.cache.data[section]?.last?.checkIn.time ?? startDay
            
            if startDay.today(self.cache.calendar)
            {
                appDebug("it's today!")
                (self.tabBarController as? RootViewController)?.showCheckInDrawer()
                return
            }
            
            let date = checkInDate(forEndDay: endDay, withLastDay: lastDate)
            
            (self.tabBarController as? RootViewController)?.showCheckInDrawer(withModel: nil, orDate: date)
        }
        else if let item = self.cache.data[section]?[indexPath.row]
        {
            (self.tabBarController as? RootViewController)?.showCheckInDrawer(withModel: item)
        }
    }
    
    func checkInDate(forEndDay endDay: Date, withLastDay lastDay: Date) -> Date
    {
        let nextDate = self.cache.calendar.date(byAdding: .minute, value: 1, to: lastDay)!
        
        let date: Date
        
        if nextDate >= endDay
        {
            // AB: exceptional case where we're down to the last minute in a day
            date = Date.init(timeIntervalSince1970: (lastDay.timeIntervalSince1970 + endDay.timeIntervalSince1970) / 2)
        }
        else
        {
            date = nextDate
        }
        
        return date
    }
}

extension FirstViewController: FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance
{
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool)
    {
        self.calendarHeight.constant = bounds.size.height
        appDebug("calendar bounds did change: \(calendar.scope.rawValue)")
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar)
    {
        updateTitle()
        reloadData(animated: false, fromScratch: true)
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventOffsetFor date: Date) -> CGPoint
    {
        return CGPoint.init(x: 0, y: 2)
    }
    
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int
    {
        let nextDay = DataLayer.calendar.date(byAdding: .day, value: 1, to: date)!
        do
        {
            let data = try self.data?.getModels(fromIncludingDate: date, toExcludingDate: nextDay, includingDeleted: false).0
            return data?.count ?? 0
        }
        catch
        {
            appError("could not retrieve models for number of events")
            return 0
        }
    }
    
    @IBAction func todayTapped(_ sender: UIBarButtonItem)
    {
        self.calendar.setCurrentPage(Date(), animated: true)
    }
    
    func updateTitle()
    {
        let components = DataLayer.calendar.dateComponents([.month, .year], from: calendar.currentPage)
        
        let monthFormat = DateFormatter()
        monthFormat.dateFormat = "MM"
        let month = monthFormat.monthSymbols[components.month! - 1]
        
        self.navigationItem.title = "\(month) \(components.year!)"
    }
}
