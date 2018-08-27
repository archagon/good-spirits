//
//  SecondViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit
import DataLayer
import Charts

class SecondViewController: UIViewController
{
    @IBOutlet var progressSpinner: UIActivityIndicatorView! = nil
    @IBOutlet var tableView: UITableView! = nil
    
    var notificationObserver: Any? = nil
    var dataObserver: Any? = nil
    
    enum Mode
    {
        case week
        case month
        case year
    }
    var mode: Mode = .month
    
    var data: DataLayer?
    {
        return (self.tabBarController as? RootViewController)?.data
    }
    
    struct Stat
    {
        let range: Swift.Range<Date>
        let price: Double
        let calories: Double
        let drinks: Double
    }
    struct Point
    {
        let date: Date
        let grams: Double
    }
    
    var cache: (weekStats: [Stat], weekPoints: [Point], monthPoints: [Point], yearPoints: [Point], endDate: Date, weeklyLimit: Double?, standardDrink: Double, startsOnMonday: Bool, token: DataLayer.Token) = ([], [], [], [], Date(), Defaults.weeklyLimit, Defaults.standardDrinkSize, Defaults.weekStartsOnMonday, DataLayer.NullToken)
    {
        didSet
        {
            self.tableView.reloadData()
        }
    }
    
    deinit
    {
        if let observer = self.notificationObserver
        {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = self.dataObserver
        {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tableView.register(DayHeaderCell.self, forHeaderFooterViewReuseIdentifier: "DayHeaderCell")
        self.tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "EmptyHeaderFooterCell")
        self.tableView.register(TrendStatsCell.self, forCellReuseIdentifier: "TrendStatsCell")
        self.tableView.register(YearStatsCell.self, forCellReuseIdentifier: "YearStatsCell")
        self.tableView.register(WeekStatsCell.self, forCellReuseIdentifier: "WeekStatsCell")
        
        var inset = self.tableView.contentInset
        inset.bottom += 20
        self.tableView.contentInset = inset
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 75
        self.tableView.separatorStyle = .none
        
        self.dataObserver = NotificationCenter.default.addObserver(forName: DataLayer.DataDidChangeNotification, object: nil, queue: OperationQueue.main)
        { [weak `self`] _ in
            self?.reloadData()
        }
        self.notificationObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: OperationQueue.main)
        { [weak `self`] _ in
            if Defaults.weeklyLimit != self?.cache.weeklyLimit
            {
                self?.reloadData()
            }
            else if Defaults.standardDrinkSize != self?.cache.standardDrink
            {
                self?.reloadData()
            }
            else if Defaults.weekStartsOnMonday != self?.cache.startsOnMonday
            {
                self?.reloadData()
            }
        }
        
        reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.setBackgroundImage(UIColor.clear.pixel, for: .default)
        
        // AB: can rely on notifications or viewDidLoad
        //reloadData()
    }
    
    func reloadData()
    {
        //self.tableView.isHidden = true
        //self.progressSpinner.isHidden = false
        //self.progressSpinner.startAnimating()
        
        if let data = self.data
        {
            // PERF: this should be done through the database
            data.getModels(fromIncludingDate: Date.distantPast, toExcludingDate: Date.distantFuture)
            { [weak `self`] in
                switch $0
                {
                case .error(let e):
                    appError("stats database error -- \(e.localizedDescription)")
                case .value(let v):
                    // AB: this fails on starts-on-monday changes... maybe perf is good enough?
                    //if self.cache.token == v.1
                    //{
                    //    appDebug("no changes in stats")
                    //    self.tableView.isHidden = false
                    //    self.progressSpinner.isHidden = true
                    //    self.progressSpinner.stopAnimating()
                    //    return
                    //}
                    
                    appDebug("stats db reloaded")
                    
                    let weeklyLimit = Defaults.weeklyLimit
                    let standardDrink = Defaults.standardDrinkSize
                    let weekStartsOnMonday = Defaults.weekStartsOnMonday
                    
                    //let sortedModels = SortedArray<Model>.init(sorted: v.0) { $0.checkIn.time < $1.checkIn.time }
                    let sortedModels = v.0
                    
                    if sortedModels.count == 0
                    {
                        self?.tableView.isHidden = true
                        self?.progressSpinner.isHidden = true
                        self?.progressSpinner.stopAnimating()
                        
                        self?.tableView.reloadData()
                        // NEXT: "nothing to show"
                    }
                    else
                    {
                        var stats: [Stat] = []
                        
                        let earliestDate = sortedModels.first!.checkIn.time
                        let latestDate = min(sortedModels.last!.checkIn.time, Date())
                        var currentWeek = Time.week(forDate: earliestDate)
                        var currentIndex = 0
                        
                        // PERF: could probably use some of those sorting methods
                        while currentWeek.0 <= latestDate
                        {
                            var nextIndex = currentIndex
                            for i in currentIndex..<sortedModels.count
                            {
                                if sortedModels[i].checkIn.time < currentWeek.1
                                {
                                    nextIndex = i + 1
                                }
                            }
                                
                            let range = currentIndex..<nextIndex
                            
                            let totalPrice = sortedModels[range].reduce(0) { $0 + ($1.checkIn.drink.price ?? 0) }
                            let totalDrinks = sortedModels[range].reduce(0) { $0 + Stats(data).standardDrinks($1) }
                            let totalGramsAlcohol = sortedModels[range].reduce(0) { $0 + Stats(data).gramsOfAlcohol($1) }
                            
                            let stat = Stat.init(range: currentWeek.0..<currentWeek.1, price: totalPrice, calories: totalGramsAlcohol * Constants.calorieMultiplier, drinks: totalDrinks)
                            
                            stats.append(stat)
                            
                            currentIndex = nextIndex
                            currentWeek = Time.week(forDate: currentWeek.1)
                        }
                        
                        let currentDate = Date()
                        var weekStats: [Point] = []
                        var monthStats: [Point] = []
                        var yearStats: [Point] = []
                        
                        populatePoints: do
                        {
                            let earliestWeekDate = DataLayer.calendar.date(byAdding: .day, value: -7, to: currentDate)!
                            let earliestMonthDate = DataLayer.calendar.date(byAdding: .day, value: -30, to: currentDate)!
                            let earliestYearDate = DataLayer.calendar.date(byAdding: .day, value: -365, to: currentDate)!
                            
                            for model in sortedModels.reversed()
                            {
                                let point = Point.init(date: model.checkIn.time, grams: Stats(data).gramsOfAlcohol(model))
                                
                                if model.checkIn.time >= earliestWeekDate
                                {
                                    weekStats.append(point)
                                }
                                if model.checkIn.time >= earliestMonthDate
                                {
                                    monthStats.append(point)
                                }
                                if model.checkIn.time >= earliestYearDate
                                {
                                    yearStats.append(point)
                                }
                                else
                                {
                                    break
                                }
                            }
                        }
                        
                        self?.tableView.isHidden = false
                        self?.progressSpinner.isHidden = true
                        self?.progressSpinner.stopAnimating()
                        self?.cache = (stats.reversed(), weekStats, monthStats, yearStats, currentDate, weeklyLimit, standardDrink, weekStartsOnMonday, v.1)
                    }
                }
            }
        }
    }
}

extension SecondViewController: UITableViewDelegate, UITableViewDataSource
{
    public func numberOfSections(in tableView: UITableView) -> Int
    {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            return 1
        }
        else if section == 1
        {
            return 5
        }
        else
        {
            return self.cache.weekStats.count
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
    {
        (view as? UITableViewHeaderFooterView)?.backgroundView?.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        if section == 0
        {
            return 0
        }
        else if section == 1
        {
            return 6
        }
        else
        {
            return 6
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        if section == 0
        {
            return 0
        }
        else if section == 1
        {
            return 40
        }
        else
        {
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    {
        if section == 0
        {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "DayHeaderCell")
        }
        else if section == 1
        {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "DayHeaderCell")
        }
        else
        {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "DayHeaderCell")
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        if section == 0
        {
            guard let headerView = view as? DayHeaderCell else
            {
                return
            }
            
            headerView.textLabel?.text = nil
            headerView.textLabel?.textColor = UIColor.black
        }
        else if section == 1
        {
            guard let headerView = view as? DayHeaderCell else
            {
                return
            }
            
            headerView.textLabel?.text = "General Trends"
            headerView.textLabel?.textColor = UIColor.black
        }
        else if section == 2
        {
            guard let headerView = view as? DayHeaderCell else
            {
                return
            }
            
            headerView.textLabel?.text = "Weekly Stats"
            headerView.textLabel?.textColor = UIColor.black
        }
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath?
    {
        if indexPath.section == 2
        {
            return indexPath
        }
        else
        {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // NEXT: show week in stats view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if indexPath.section == 0
        {
            let cell: YearStatsCell = (tableView.dequeueReusableCell(withIdentifier: "YearStatsCell") as? YearStatsCell) ?? YearStatsCell()
            cell.segment.removeTarget(self, action: nil, for: .valueChanged)
            cell.segment.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
            updateCellAppearance(cell, forRowAt: indexPath)
            return cell
        }
        else if indexPath.section == 1
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TrendStatsCell") ?? TrendStatsCell()
            updateCellAppearance(cell, forRowAt: indexPath)
            return cell
        }
        else
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "WeekStatsCell") ?? WeekStatsCell()
            updateCellAppearance(cell, forRowAt: indexPath)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        updateCellAppearance(cell, forRowAt: indexPath)
    }
    
    func updateCellAppearance(_ cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        cell.selectionStyle = .none
        
        if indexPath.section == 0, let cell = cell as? YearStatsCell
        {
            switch self.mode
            {
            case .week:
                cell.header.text = "Last Week"
                let from = DataLayer.calendar.date(byAdding: .day, value: -7, to: cache.endDate)!
                cell.populate(withDrinks: self.cache.weekPoints, goal: Defaults.weeklyLimit, inRange: from...cache.endDate)
            case .month:
                cell.header.text = "Last Month"
                let from = DataLayer.calendar.date(byAdding: .day, value: -30, to: cache.endDate)!
                cell.populate(withDrinks: self.cache.monthPoints, goal: Defaults.weeklyLimit, inRange: from...cache.endDate)
            case .year:
                cell.header.text = "Last Year"
                let from = DataLayer.calendar.date(byAdding: .day, value: -365, to: cache.endDate)!
                cell.populate(withDrinks: self.cache.yearPoints, goal: Defaults.weeklyLimit, inRange: from...cache.endDate)
            }
        }
        else if indexPath.section == 1, let cell = cell as? TrendStatsCell
        {
            if indexPath.row == 0
            {
                cell.label.text = "Your running average over the last year is \("1.2 drinks per day"), which is \("within your target range"). Good job!"
            }
            else if indexPath.row == 1
            {
                cell.label.text = "Your favorite drink is \("beer") and your ABV is \("12.5%") on average. You tend to drink \("12 fl oz") servings."
            }
            else
            {
                cell.label.text = "You did blah-de-di-blah today!"
            }
            
            cell.label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            
            cell.bgView.backgroundColor = UIColor.purple.mixed(with: .white, by: 0.5)
        }
        else if indexPath.section == 2, let cell = cell as? WeekStatsCell
        {
            let stats = self.cache.weekStats[indexPath.row]
            
            let percentOverLimit: Double?
            
            if let data = self.data, Defaults.weeklyLimit != nil
            {
                let percent = Stats(data).drinksToPercent(Float(stats.drinks), inRange: stats.range)
                cell.setProgress(Double(percent))
                percentOverLimit = (percent > 1 ? Double(percent - 1) : nil)
            }
            else
            {
                cell.setDefault()
                percentOverLimit = nil
            }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            let date1 = formatter.string(from: stats.range.lowerBound)
            let date2 = formatter.string(from: stats.range.upperBound)
            
            cell.label.text = "\(date1) to \(date2)"
            
            var infoLabel = ""
            if stats.drinks > 0
            {
                let p1 = "\(Format.format(drinks: stats.drinks)) drinks, or \(Format.format(drinks: stats.drinks/7)) avg. drinks per day"
                
                infoLabel = "\(p1)"
                
                let p3 = "Gained \(Format.format(calories: stats.calories)) calories"
                infoLabel += "\n\(p3)"
                
                if stats.price > 0
                {
                    let p4 = "and spent \(Format.format(price: stats.price))"
                    infoLabel += " \(p4)"
                }
                
                if let percent = percentOverLimit
                {
                    let format = String.init(format: "%.0f", percent * 100)
                    let p2 = "Went \(format)% over the weekly limit"
                    infoLabel += "\n\(p2)"
                }
            }
            else
            {
                infoLabel = "No drinking this week"
            }
            cell.labelText = infoLabel
        }
    }
}

extension SecondViewController
{
    @objc func modeChanged(_ sender: UISegmentedControl)
    {
        if sender.selectedSegmentIndex == 0
        {
            self.mode = .week
        }
        else if sender.selectedSegmentIndex == 1
        {
            self.mode = .month
        }
        else
        {
            self.mode = .year
        }
        
        self.tableView.reloadRows(at: [IndexPath.init(item: 0, section: 0)], with: .none)
    }
}
