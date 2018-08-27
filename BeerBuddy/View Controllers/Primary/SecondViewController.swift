//
//  SecondViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit
import DataLayer

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
        let range: Range<Date>
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
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            return 1
        }
        else
        {
            return self.cache.weekStats.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        if section == 0
        {
            return 16
        }
        else
        {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if section == 0
        {
            return "Year in Review"
        }
        else
        {
            return "Weekly Stats"
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
        if indexPath.section == 0, let cell = cell as? YearStatsCell
        {
            let totalPrice = self.cache.weekStats.reduce(0) { $0 + $1.price }
            let totalCalories = self.cache.weekStats.reduce(0) { $0 + $1.calories }
            let totalDrinks = self.cache.weekStats.reduce(0) { $0 + $1.drinks }
            
            cell.label.text = "Stats from 2018: \(Format.format(price: totalPrice)), \(Format.format(drinks: totalDrinks)) drinks, \(Format.format(drinks: totalCalories)) calories"
        }
        else if indexPath.section == 1, let cell = cell as? WeekStatsCell
        {
            let stats = self.cache.weekStats[indexPath.row]
            
            cell.label.text = "Stats from \(stats.range.lowerBound) to \(stats.range.upperBound)"
            cell.label2.text = "\(Format.format(drinks: stats.drinks)) drinks, with \(Format.format(drinks: stats.calories)) calories and \(Format.format(price: stats.price)) total price"
        }
    }
}

public class YearStatsCell: UITableViewCell
{
    var label: UILabel
    var graphView: UIView
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        self.label = UILabel()
        self.graphView = UIView()
        
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        self.label.numberOfLines = 100
        self.graphView.backgroundColor = UIColor.green
        
        let stack = UIStackView()
        stack.axis = .vertical
        
        autolayout: do
        {
            stack.translatesAutoresizingMaskIntoConstraints = false
            label.translatesAutoresizingMaskIntoConstraints = false
            graphView.translatesAutoresizingMaskIntoConstraints = false
            
            stack.addArrangedSubview(label)
            stack.addArrangedSubview(graphView)
            self.addSubview(stack)
            
            stack.spacing = 4
            
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
        
        let stack = UIStackView()
        stack.axis = .vertical
        
        bgView.backgroundColor = .orange
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
