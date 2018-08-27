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
    
    var cache: (weekStats: [Stat], weeklyLimit: Double?, standardDrink: Double, startsOnMonday: Bool, token: DataLayer.Token) = ([], Defaults.weeklyLimit, Defaults.standardDrinkSize, Defaults.weekStartsOnMonday, DataLayer.NullToken)
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
            {
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
                    
                    let sortedModels = SortedArray<Model>.init(sorted: v.0) { $0.checkIn.time < $1.checkIn.time }
                    
                    if sortedModels.count == 0
                    {
                        self.tableView.isHidden = true
                        self.progressSpinner.isHidden = true
                        self.progressSpinner.stopAnimating()
                        
                        self.tableView.reloadData()
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
                        
                        self.tableView.isHidden = false
                        self.progressSpinner.isHidden = true
                        self.progressSpinner.stopAnimating()
                        self.cache = (stats.reversed(), weeklyLimit, standardDrink, weekStartsOnMonday, v.1)
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
            return 0
        }
        else
        {
            return 0
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
            
            headerView.textLabel?.text = "Overall Trends"
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "YearStatsCell") ?? YearStatsCell()
            updateCellAppearance(cell, forRowAt: indexPath)
            return cell
        }
        else if indexPath.section == 1
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "WeekStatsCell") ?? WeekStatsCell()
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
//            let totalPrice = self.cache.weekStats.reduce(0) { $0 + $1.price }
//            let totalCalories = self.cache.weekStats.reduce(0) { $0 + $1.calories }
//            let totalDrinks = self.cache.weekStats.reduce(0) { $0 + $1.drinks }
//
//            cell.label.text = "Stats from 2018: \(Format.format(price: totalPrice)), \(Format.format(drinks: totalDrinks)) drinks, \(Format.format(drinks: totalCalories)) calories"
        }
        else if indexPath.section == 1, let cell = cell as? WeekStatsCell
        {
            cell.label.text = "You did blah-de-di-blah today!"
            cell.label2.text = "Blah things in blah time"
            cell.bgView.backgroundColor = UIColor.red.mixed(with: .white, by: 0.3)
        }
        else if indexPath.section == 2, let cell = cell as? WeekStatsCell
        {
            let stats = self.cache.weekStats[indexPath.row]
            
            cell.label.text = "Stats from \(stats.range.lowerBound) to \(stats.range.upperBound)"
            cell.label2.text = "\(Format.format(drinks: stats.drinks)) drinks, with \(Format.format(drinks: stats.calories)) calories and \(Format.format(price: stats.price)) total price"
        }
    }
}

public class YearStatsCell: UITableViewCell
{
    var header: UILabel
    var graphView: LineChartView
    var segment: UISegmentedControl
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        self.header = UILabel()
        self.graphView = LineChartView.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 100))
        self.segment = UISegmentedControl.init(items: ["Week", "Month", "Year"])
        
        chartSetup: do
        {
            var samples: [ChartDataEntry] = []
            for i in 0..<30
            {
                let val = Double(arc4random_uniform(100)) + 3
                samples += [ChartDataEntry(x: Double(i), y: val)]
            }
            let set = LineChartDataSet(values: samples, label: "DataSet 1")
            set.lineWidth = 1.75
            set.circleRadius = 5.0
            set.circleHoleRadius = 2.5
            set.setColor(.white)
            set.setCircleColor(.white)
            set.highlightColor = .white
            set.drawValuesEnabled = false
            let data = LineChartData(dataSet: set)
            
            graphView.data = data
            
            graphView.backgroundColor = Appearance.themeColor
            graphView.dragEnabled = true
            graphView.setScaleEnabled(true)
            graphView.pinchZoomEnabled = false
            graphView.setViewPortOffsets(left: 10, top: 0, right: 10, bottom: 0)
            
            graphView.chartDescription?.enabled = false
            graphView.legend.enabled = false
            
            graphView.leftAxis.enabled = false
            graphView.leftAxis.spaceTop = 0.4
            graphView.leftAxis.spaceBottom = 0.4
            graphView.rightAxis.enabled = false
            graphView.xAxis.enabled = false
            
            graphView.data = data
            
            graphView.animate(xAxisDuration: 1)
            
            graphView.layer.cornerRadius = 8
            graphView.clipsToBounds = true
        }
        
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        let stack = UIStackView()
        stack.axis = .vertical
        
        header.text = "August 2018"
        header.textAlignment = .center
        header.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        header.textColor = .gray
        
        autolayout: do
        {
            stack.translatesAutoresizingMaskIntoConstraints = false
            header.translatesAutoresizingMaskIntoConstraints = false
            graphView.translatesAutoresizingMaskIntoConstraints = false
            segment.translatesAutoresizingMaskIntoConstraints = false
            
            stack.addArrangedSubview(header)
            stack.addArrangedSubview(graphView)
            stack.addArrangedSubview(segment)
            self.addSubview(stack)
            
            stack.spacing = 8
            
            let metrics: [String:Any] = ["gap":8]
            
            let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(gap)-[stack]-(gap)-|", options: [], metrics: metrics, views: ["stack":stack])
            let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(gap)-[stack]-(gap)-|", options: [], metrics: metrics, views: ["stack":stack])
            
            let graphHeight = graphView.heightAnchor.constraint(equalToConstant: 250)
            
            NSLayoutConstraint.activate(hConstraints + vConstraints + [graphHeight])
        }
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}

public class WeekStatsCell: UITableViewCell
{
    var label: UILabel
    var label2: UILabel
    var bgView: UIView
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        self.label = UILabel()
        self.label2 = UILabel()
        self.bgView = UIView()
        
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        self.label.numberOfLines = 100
        self.label2.numberOfLines = 100
        self.label.textColor = .white
        self.label2.textColor = .white
        
        let stack = UIStackView()
        stack.axis = .vertical
        
        bgView.backgroundColor = Appearance.darkenedThemeColor
        bgView.layer.cornerRadius = 8
        
        autolayout: do
        {
            stack.translatesAutoresizingMaskIntoConstraints = false
            label.translatesAutoresizingMaskIntoConstraints = false
            label2.translatesAutoresizingMaskIntoConstraints = false
            bgView.translatesAutoresizingMaskIntoConstraints = false
            
            self.addSubview(bgView)
            stack.addArrangedSubview(label)
            stack.addArrangedSubview(label2)
            bgView.addSubview(stack)
            
            stack.spacing = 4
            
            let metrics: [String:Any] = ["gap":8, "margin":8, "halfMargin":8/2]
            let views: [String:Any] = ["bg":bgView, "stack":stack]
            
            let hConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(margin)-[bg]-(margin)-|", options: [], metrics: metrics, views: views)
            let vConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(halfMargin)-[bg]-(halfMargin)-|", options: [], metrics: metrics, views: views)
            let hConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(gap)-[stack]-(gap)-|", options: [], metrics: metrics, views: views)
            let vConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(gap)-[stack]-(gap)-|", options: [], metrics: metrics, views: views)
            
            NSLayoutConstraint.activate(hConstraints1 + vConstraints1 + hConstraints2 + vConstraints2)
        }
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}
