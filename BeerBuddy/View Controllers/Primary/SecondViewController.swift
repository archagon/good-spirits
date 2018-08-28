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
    @IBOutlet var tableView: UITableView! = nil
    
    var notificationObserver: Any? = nil
    var dataObserver: Any? = nil
    
    enum Mode
    {
        case week
        case month
        case year
    }
    var mode: Mode = .week
    
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
    struct Facts
    {
        let averageDrinksPerDay: Double
        let averageABV: Double
        let favoriteDrink: DrinkStyle
        let typicalVolume: Measurement<UnitVolume>
        let percentDaysDrank: Double
        let totalPrice: Double
        let mostDrinksOnADay: (Date, Double)
        
        let range: Int
    }
    
    var cache: (weekStats: [Stat], weekPoints: [Point], monthPoints: [Point], yearPoints: [Point], weeklyLimit: Double?, standardDrink: Double, startsOnMonday: Bool, token: DataLayer.Token, facts: Facts?) = ([], [], [], [], Defaults.weeklyLimit, Defaults.standardDrinkSize, Defaults.weekStartsOnMonday, DataLayer.NullToken, nil)
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
    }
    
    func reloadData()
    {
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
                        self?.cache = ([], [], [], [], weeklyLimit, standardDrink, weekStartsOnMonday, v.1, nil)
                    }
                    else
                    {
                        let now = Date()
                     
                        var stats: [Stat] = []
                        
                        // PERF: could probably use some of those sorting methods
                        iterateWeeks: do
                        {
                            //let earliestDate = sortedModels.first!.checkIn.time
                            let latestDate = min(sortedModels.last!.checkIn.time, now)
                            let currentWeek = Time.week(forDate: latestDate)
                            
                            var range = currentWeek.0..<currentWeek.1
                            var modelIndex = sortedModels.count - 1
                            while modelIndex >= 0
                            {
                                var price: Double = 0
                                var drinks: Double = 0
                                var gramsAlcohol: Double = 0
                                
                                while modelIndex >= 0, range.lowerBound <= sortedModels[modelIndex].checkIn.time
                                {
                                    let model = sortedModels[modelIndex]
                                    
                                    if model.checkIn.time <= now
                                    {
                                        price += model.checkIn.drink.price ?? 0
                                        drinks += Stats(data).standardDrinks(model)
                                        gramsAlcohol += Stats(data).gramsOfAlcohol(model)
                                    }
                                    
                                    modelIndex -= 1
                                }
                                
                                let stat = Stat.init(range: range, price: price, calories: gramsAlcohol * 7 * Constants.calorieMultiplier, drinks: drinks)
                                
                                stats.append(stat)
                                
                                let newLowerBound = DataLayer.calendar.date(byAdding: .day, value: -7, to: range.lowerBound)!
                                range = newLowerBound..<range.lowerBound
                            }
                        }

                        var weekStats: [Point] = []
                        var monthStats: [Point] = []
                        var yearStats: [Point] = []
                        
                        var totalDrinks: Double = 0
                        var totalABV: Double = 0
                        var drinkCounts: [DrinkStyle:Int] = [:]
                        var volumeCounts: [Measurement<UnitVolume>:Int] = [:]
                        var drinkingDays = 0
                        var maxDrinksPerDay: Double = 0
                        var dateForMaxDrinks: Date = Date()
                        var totalPrice: Double = 0
                        var numberOfDays = 1
                        var numberOfCheckIns: Int = 0
                        
                        iterateDays: do
                        {
                            let today = DataLayer.calendar.date(bySettingHour: 0, minute: 0, second: 0, of: now)!
                            let tomorrow = DataLayer.calendar.date(byAdding: .day, value: 1, to: today)!
                            
                            var yearPoints: [Point] = []
                            
                            let weeks = 50
                            let total = 7 * weeks
                            
                            var range = today..<tomorrow
                            var modelIndex = sortedModels.count - 1
                            for _ in 0..<total
                            {
                                var drinks: Double = 0
                                
                                while modelIndex >= 0, range.lowerBound <= sortedModels[modelIndex].checkIn.time
                                {
                                    let model = sortedModels[modelIndex]
                                    
                                    if model.checkIn.time <= now
                                    {
                                        let checkInDrinks = Stats(data).standardDrinks(model)
                                        drinks += checkInDrinks
                                        
                                        facts: do
                                        {
                                            if volumeCounts[model.checkIn.drink.volume] == nil
                                            {
                                                volumeCounts[model.checkIn.drink.volume] = 0
                                            }
                                            volumeCounts[model.checkIn.drink.volume]! += 1
                                            
                                            if drinkCounts[model.checkIn.drink.style] == nil
                                            {
                                                drinkCounts[model.checkIn.drink.style] = 0
                                            }
                                            drinkCounts[model.checkIn.drink.style]! += 1
                                            
                                            totalABV += model.checkIn.drink.abv
                                            
                                            totalDrinks += checkInDrinks
                                            
                                            totalPrice += model.checkIn.drink.price ?? 0
                                            
                                            numberOfCheckIns += 1
                                        }
                                    }
                                    
                                    modelIndex -= 1
                                }
                                
                                yearPoints.append(Point.init(date: range.lowerBound, grams: drinks))
                                
                                facts: do
                                {
                                    if modelIndex >= 0
                                    {
                                        numberOfDays += 1
                                    }
                                    
                                    if drinks > maxDrinksPerDay
                                    {
                                        maxDrinksPerDay = drinks
                                        dateForMaxDrinks = range.lowerBound
                                    }
                                    
                                    if drinks > 0
                                    {
                                        drinkingDays += 1
                                    }
                                }
                                
                                let newLowerBound = DataLayer.calendar.date(byAdding: .day, value: -1, to: range.lowerBound)!
                                range = newLowerBound..<range.lowerBound
                            }
                            
                            weekStats = Array(yearPoints[0..<7].reversed())
                            monthStats = Array(yearPoints[0..<30].reversed())
                            yearStats = yearPoints.reversed()
                        }
                        
                        let favoriteDrink = drinkCounts.max(by: { (first, second) -> Bool in first.value < second.value })!.key
                        let favoriteVolume = volumeCounts.max(by: { (first, second) -> Bool in first.value < second.value })!.key
                        
                        let facts = Facts.init(averageDrinksPerDay: totalDrinks/Double(numberOfDays), averageABV: totalABV/Double(numberOfCheckIns), favoriteDrink: favoriteDrink, typicalVolume: favoriteVolume, percentDaysDrank: Double(drinkingDays)/Double(numberOfDays), totalPrice: totalPrice, mostDrinksOnADay: (dateForMaxDrinks, maxDrinksPerDay), range: numberOfDays)

                        self?.cache = (stats, weekStats, monthStats, yearStats, weeklyLimit, standardDrink, weekStartsOnMonday, v.1, facts)
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
        // TODO: need more explicit logic here
        if self.cache.facts == nil
        {
            return 1
        }
        else
        {
            return 3
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            return 1
        }
        else if section == 1
        {
            return 4
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
            
            headerView.textLabel?.text = "Running Tally Over \(self.cache.facts?.range ?? 0) Days"
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
        
        if indexPath.section == 2
        {
            let dates = self.cache.weekStats[indexPath.row].range
            
            if
                let tabController = self.tabBarController,
                let navController = tabController.viewControllers?.first as? UINavigationController,
                let viewController = navController.viewControllers.first as? FirstViewController
            {
                let date = Date.init(timeIntervalSince1970: (dates.lowerBound.timeIntervalSince1970 + dates.upperBound.timeIntervalSince1970) / 2)
                viewController.calendar?.setCurrentPage(date, animated: false)
                tabController.selectedIndex = 0
            }
        }
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
            let granularity: Int
            switch self.mode
            {
            case .week:
                granularity = 1
            case .month:
                granularity = 5
            case .year:
                granularity = 50
            }
            
            let goal: Double?
            let goalLabel: String?
            if let limit = self.cache.weeklyLimit
            {
                goal = ((limit / 7) / self.cache.standardDrink) * Double(granularity)
                goalLabel = "\(goal!) drinks"
            }
            else
            {
                goal = nil
                goalLabel = nil
            }
            
            switch self.mode
            {
            case .week:
                cell.header.text = "Last Week"
                cell.populate(withDrinks: self.cache.weekPoints, goal: goal, goalLabel: goalLabel, granularity: 1)
                cell.segment.selectedSegmentIndex = 0
            case .month:
                cell.header.text = "Last Month"
                cell.populate(withDrinks: self.cache.monthPoints, goal: goal, goalLabel: goalLabel, granularity: 5)
                cell.segment.selectedSegmentIndex = 1
            case .year:
                cell.header.text = "Last Year"
                cell.populate(withDrinks: self.cache.yearPoints, goal: goal, goalLabel: goalLabel, granularity: 50)
                cell.segment.selectedSegmentIndex = 2
            }
        }
        else if indexPath.section == 1, let cell = cell as? TrendStatsCell
        {
            guard let facts = self.cache.facts else { return }
            
            let regularAttributes: [NSAttributedStringKey:Any] = [
                NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16, weight: .regular),
                NSAttributedStringKey.foregroundColor:UIColor.white
            ]
            let boldAttributes: [NSAttributedStringKey:Any] = [
                NSAttributedStringKey.font:UIFont.systemFont(ofSize: 16, weight: .bold),
                NSAttributedStringKey.foregroundColor:UIColor.white
            ]
            
            if indexPath.row == 0
            {
                if let limit = self.cache.weeklyLimit
                {
                    let text = "You are averaging $avg$ drinks per day, compared to your target of $target$ drinks per day."
                    
                    let attrText = NSMutableAttributedString.init(string: text, attributes: regularAttributes)
                    attrText.replaceAnchorText("avg", value: Format.format(drinks: facts.averageDrinksPerDay), withDelimiter: "$", attributes: boldAttributes)
                    attrText.replaceAnchorText("target", value: Format.format(drinks: (limit / self.cache.standardDrink) / 7), withDelimiter: "$", attributes: boldAttributes)
                    
                    cell.label.attributedText = attrText
                }
                else
                {
                    let text = "You are averaging $avg$ drinks per day."
                    
                    let attrText = NSMutableAttributedString.init(string: text, attributes: regularAttributes)
                    attrText.replaceAnchorText("avg", value: Format.format(drinks: facts.averageDrinksPerDay), withDelimiter: "$", attributes: boldAttributes)
                    
                    cell.label.attributedText = attrText
                }
            }
            else if indexPath.row == 1
            {
                let text = "Your favorite drink is $fav$ and your average ABV is $abv$. You tend to drink $vol$ servings."
                
                let attrText = NSMutableAttributedString.init(string: text, attributes: regularAttributes)
                attrText.replaceAnchorText("fav", value: Format.format(style: facts.favoriteDrink), withDelimiter: "$", attributes: boldAttributes)
                attrText.replaceAnchorText("abv", value: Format.format(abv: facts.averageABV), withDelimiter: "$", attributes: boldAttributes)
                attrText.replaceAnchorText("vol", value: Format.format(volume: facts.typicalVolume), withDelimiter: "$", attributes: boldAttributes)
                
                cell.label.attributedText = attrText
            }
            else if indexPath.row == 2
            {
                let format = DateFormatter()
                format.dateFormat = "MMMM dd, yyyy"
                
                let text = "You drank on $num$ of days. The most drinks you had was $most$, on $date$."
                
                let attrText = NSMutableAttributedString.init(string: text, attributes: regularAttributes)
                attrText.replaceAnchorText("num", value: Format.format(abv: facts.percentDaysDrank), withDelimiter: "$", attributes: boldAttributes)
                attrText.replaceAnchorText("most", value: Format.format(drinks: facts.mostDrinksOnADay.1), withDelimiter: "$", attributes: boldAttributes)
                attrText.replaceAnchorText("date", value: format.string(from: facts.mostDrinksOnADay.0), withDelimiter: "$", attributes: boldAttributes)
                
                cell.label.attributedText = attrText
            }
            else
            {
                let text = "You have spent a total of $price$."
                
                let attrText = NSMutableAttributedString.init(string: text, attributes: regularAttributes)
                attrText.replaceAnchorText("price", value: Format.format(price: facts.totalPrice), withDelimiter: "$", attributes: boldAttributes)
                
                cell.label.attributedText = attrText
            }
            
            cell.bgView.backgroundColor = UIColor.purple.mixed(with: .white, by: 0.5)
        }
        else if indexPath.section == 2, let cell = cell as? WeekStatsCell
        {
            let stats = self.cache.weekStats[indexPath.row]
            
            let percentOverLimit: Double?
            
            if let data = self.data, self.cache.weeklyLimit != nil
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
        
        let row = IndexPath.init(item: 0, section: 0)
        if let chart = self.tableView.cellForRow(at: row) as? YearStatsCell
        {
            updateCellAppearance(chart, forRowAt: row)
        }
    }
}
