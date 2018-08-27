//
//  StatsCells.swift
//  Good Spirits
//
//  Created by Alexei Baboulevitch on 2018-8-26.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import Charts

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
            graphView.backgroundColor = Appearance.themeColor
            graphView.dragEnabled = false
            graphView.setScaleEnabled(false)
            graphView.pinchZoomEnabled = false
            graphView.setViewPortOffsets(left: 0, top: 0, right: 0, bottom: 0)
            
            graphView.chartDescription?.enabled = false
            graphView.legend.enabled = false
            
            graphView.noDataFont = UIFont.systemFont(ofSize: 16, weight: .medium)
            graphView.noDataTextColor = .white
            
            let xAxis = graphView.xAxis
//            xAxis.enabled = true
            xAxis.labelPosition = .bottomInside
            xAxis.labelFont = .systemFont(ofSize: 12)
//            xAxis.drawAxisLineEnabled = true
            xAxis.gridColor = UIColor.init(white: 1, alpha: 0.7)
//            xAxis.drawLabelsEnabled = true
            xAxis.labelTextColor = .white
            xAxis.valueFormatter = AxisDateFormatter()
            
            graphView.leftAxis.enabled = false
            graphView.leftAxis.spaceTop = 0.4
            graphView.leftAxis.spaceBottom = 0.4
            
            graphView.rightAxis.enabled = false
            
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
    
    func populate(withDrinks drinks: [SecondViewController.Point], goal: Double?, inRange range: Swift.ClosedRange<Date>)
    {
        self.graphView.clear()
        
        if drinks.count == 0
        {
            return
        }
        
        let xAxis = graphView.xAxis
        if drinks.count <= 7
        {
            xAxis.setLabelCount(drinks.count, force: false)
        }
        else if drinks.count <= 31
        {
            xAxis.setLabelCount(drinks.count / 2, force: false)
        }
        else
        {
            xAxis.setLabelCount(drinks.count / 30, force: false)
        }
        
        var samples: [ChartDataEntry] = []
        for drink in drinks
        {
            samples.append(ChartDataEntry(x: drink.date.timeIntervalSince1970, y: drink.grams))
        }
        let set = LineChartDataSet.init(values: samples, label: nil)
        set.lineWidth = 1.75
        set.circleRadius = 5.0
        set.circleHoleRadius = 2.5
        set.setColor(.white)
        set.setCircleColor(.white)
        set.highlightColor = .white
        set.drawValuesEnabled = false
        
        if let goal = goal
        {
            var trendlineSamples: [ChartDataEntry] = []
            let samplesCount = 50
            for i in 0..<samplesCount
            {
                let startX = range.lowerBound.timeIntervalSince1970 - (4 * 60 * 60)
                let endX = range.upperBound.timeIntervalSince1970 + (4 * 60 * 60)
                let trendlineSample = ChartDataEntry.init(x: startX + (Double(i) / Double(samplesCount - 1)) * (endX - startX), y: goal)
                trendlineSamples.append(trendlineSample)
            }
            let set2 = LineChartDataSet.init(values: trendlineSamples, label: nil)
            set2.lineWidth = 1.5
            set2.lineDashLengths = [5, 3]
            set2.drawCirclesEnabled = false
            set2.setColor(UIColor.green.mixed(with: .white, by: 0.5))
            set2.drawValuesEnabled = false
            
            let data = LineChartData.init(dataSets: [set2, set])
            graphView.data = data
        }
        else
        {
            let data = LineChartData.init(dataSets: [set])
            graphView.data = data
        }
        
        graphView.setNeedsDisplay()
    }
    
    class AxisDateFormatter: IAxisValueFormatter
    {
        lazy var dateFormatter: DateFormatter =
        {
            let aFormatter = DateFormatter()
            aFormatter.dateFormat = "MMM dd"
            return aFormatter
        }()
        
        public func stringForValue(_ value: Double, axis: Charts.AxisBase?) -> String
        {
            let date = Date.init(timeIntervalSince1970: value)
            return dateFormatter.string(from: date)
        }
    }
}

public class TrendStatsCell: UITableViewCell
{
    var label: UILabel
    var bgView: UIView
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        self.label = UILabel()
        self.bgView = UIView()
        
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        self.label.numberOfLines = 100
        self.label.textColor = .white
        
        let stack = UIStackView()
        stack.axis = .vertical
        
        bgView.backgroundColor = Appearance.darkenedThemeColor
        bgView.layer.cornerRadius = 8
        
        autolayout: do
        {
            stack.translatesAutoresizingMaskIntoConstraints = false
            label.translatesAutoresizingMaskIntoConstraints = false
            bgView.translatesAutoresizingMaskIntoConstraints = false
            
            self.addSubview(bgView)
            stack.addArrangedSubview(label)
            bgView.addSubview(stack)
            
            stack.spacing = 4
            
            let metrics: [String:Any] = ["gap":12, "margin":8, "vMargin":6]
            let views: [String:Any] = ["bg":bgView, "stack":stack]
            
            let hConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(margin)-[bg]-(margin)-|", options: [], metrics: metrics, views: views)
            let vConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(vMargin)-[bg]|", options: [], metrics: metrics, views: views)
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

public class WeekStatsCell: UITableViewCell
{
    var label: UILabel
    var label2: UILabel
    var bgView: UIView
    var bgViewLeft: UIView
    var leftConstraint: NSLayoutConstraint! = nil
    
    var labelText: String?
    {
        get
        {
            return label2.text
        }
        set
        {
            let pg = NSMutableParagraphStyle.init()
            pg.lineSpacing = 2
            let attributes: [NSAttributedStringKey:Any] = [
                NSAttributedStringKey.font:UIFont.systemFont(ofSize: 16, weight: .regular),
                NSAttributedStringKey.paragraphStyle:pg
            ]
            label2.attributedText = NSAttributedString.init(string: newValue ?? "", attributes: attributes)
        }
    }
    
    public override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        self.label = UILabel()
        self.label2 = UILabel()
        self.bgView = UIView()
        self.bgViewLeft = UIView()
        
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        self.label.numberOfLines = 100
        self.label2.numberOfLines = 100
        self.label.textColor = .white
        self.label2.textColor = .white
        
        let stack = UIStackView()
        stack.axis = .vertical
        
        bgView.clipsToBounds = true
        bgView.layer.cornerRadius = 8
        
        labels: do
        {
            label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        }
        
        autolayout: do
        {
            stack.translatesAutoresizingMaskIntoConstraints = false
            label.translatesAutoresizingMaskIntoConstraints = false
            label2.translatesAutoresizingMaskIntoConstraints = false
            bgView.translatesAutoresizingMaskIntoConstraints = false
            bgViewLeft.translatesAutoresizingMaskIntoConstraints = false
            
            self.addSubview(bgView)
            stack.addArrangedSubview(label)
            stack.addArrangedSubview(label2)
            bgView.addSubview(bgViewLeft)
            bgView.addSubview(stack)
            
            stack.spacing = 4
            
            let metrics: [String:Any] = ["gap":12, "margin":8, "vMargin":6]
            let views: [String:Any] = ["bg":bgView, "bgl":bgViewLeft, "stack":stack]
            
            let hConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(margin)-[bg]-(margin)-|", options: [], metrics: metrics, views: views)
            let vConstraints1 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(vMargin)-[bg]|", options: [], metrics: metrics, views: views)
            let hConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(gap)-[stack]-(gap)-|", options: [], metrics: metrics, views: views)
            let vConstraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(gap)-[stack]-(gap)-|", options: [], metrics: metrics, views: views)
            let hConstraints3 = NSLayoutConstraint.constraints(withVisualFormat: "H:|[bgl]", options: [], metrics: metrics, views: views)
            let vConstraints3 = NSLayoutConstraint.constraints(withVisualFormat: "V:|[bgl]|", options: [], metrics: metrics, views: views)
            
            let widthConstraint: NSLayoutConstraint = bgViewLeft.widthAnchor.constraint(equalToConstant: 0)
            self.leftConstraint = widthConstraint
            
            NSLayoutConstraint.activate(hConstraints1 + vConstraints1 + hConstraints2 + vConstraints2 + hConstraints3 + vConstraints3)
            widthConstraint.isActive = true
        }
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setProgress(_ v: Double)
    {
        self.leftConstraint.constant = bgView.bounds.size.width * CGFloat(v)
        
        if v <= 0.3
        {
            bgViewLeft.backgroundColor = UIColor.init(hex: "1CE577").mixed(with: .black, by: 0.15)
            bgView.backgroundColor = bgViewLeft.backgroundColor?.mixed(with: .white, by: 0.3)
        }
        else if v <= 0.85
        {
            bgViewLeft.backgroundColor = Appearance.darkenedThemeColor
            bgView.backgroundColor = bgViewLeft.backgroundColor?.mixed(with: .white, by: 0.3)
        }
        else if v <= 1.0
        {
            bgViewLeft.backgroundColor = UIColor.orange.mixed(with: .white, by: 0.1)
            bgView.backgroundColor = bgViewLeft.backgroundColor?.mixed(with: .white, by: 0.3)
        }
        else
        {
            bgViewLeft.backgroundColor = UIColor.red.mixed(with: .white, by: 0.3)
            bgView.backgroundColor = bgViewLeft.backgroundColor?.mixed(with: .white, by: 0.3)
        }
        
        self.layoutIfNeeded()
    }
    
    func setDefault()
    {
        setProgress(1)
        
        bgViewLeft.backgroundColor = Appearance.darkenedThemeColor
        bgView.backgroundColor = bgViewLeft.backgroundColor?.mixed(with: .white, by: 0.3)
    }
}
