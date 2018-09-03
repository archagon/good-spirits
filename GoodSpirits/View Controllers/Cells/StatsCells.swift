//
//  StatsCells.swift
//  Good Spirits
//
//  Created by Alexei Baboulevitch on 2018-8-26.
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
            graphView.layer.cornerRadius = 8
            graphView.clipsToBounds = true
            
            graphView.dragEnabled = false
            graphView.setScaleEnabled(false)
            graphView.pinchZoomEnabled = false
            graphView.highlightPerTapEnabled = false
            graphView.highlightPerDragEnabled = false
            
            graphView.chartDescription?.enabled = false
            graphView.legend.enabled = false
            
            graphView.setViewPortOffsets(left: 30, top: 0, right: 30, bottom: 0)
            
            graphView.noDataFont = UIFont.systemFont(ofSize: 16, weight: .medium)
            graphView.noDataTextColor = .white
            
            let xAxis = graphView.xAxis
            xAxis.labelPosition = .bottomInside
            //xAxis.drawAxisLineEnabled = true
            //xAxis.drawLabelsEnabled = true
            xAxis.labelFont = .systemFont(ofSize: 12)
            xAxis.gridColor = UIColor.init(white: 1, alpha: 0.4)
            xAxis.labelTextColor = UIColor.init(white: 1, alpha: 0.7)
            xAxis.valueFormatter = AxisDateFormatter()
            
            graphView.rightAxis.enabled = false
            
            let yAxis = graphView.leftAxis
            yAxis.enabled = true
            yAxis.drawZeroLineEnabled = true
            yAxis.drawLabelsEnabled = false
            yAxis.drawAxisLineEnabled = false
            yAxis.drawGridLinesEnabled = false
            yAxis.zeroLineColor = UIColor.init(white: 1, alpha: 0.4)
            yAxis.spaceTop = 0.4
            yAxis.spaceBottom = 0.4
        }
        
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        
        let stack = UIStackView()
        stack.axis = .vertical
        
        header.text = ""
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
    
    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func populate(withDrinks drinks: [SecondViewController.Point], goal: Double?, goalLabel: String?, granularity: Int = 1)
    {
        assert(drinks.count % granularity == 0)
        
        let xAxis = graphView.xAxis
        let yAxis = graphView.leftAxis
        
        yAxis.removeAllLimitLines()
        graphView.data = nil
        
        if drinks.count == 0
        {
            return
        }

        xAxis.setLabelCount(drinks.count / granularity, force: true)
        
        if let goal = goal
        {
            let limitLine = ChartLimitLine.init(limit: goal)
            limitLine.lineColor = UIColor.green.mixed(with: .white, by: 0.5)
            limitLine.drawLabelEnabled = false
            limitLine.lineWidth = 1.5
            limitLine.lineDashLengths = [5, 3]
            //limitLine.valueFont = UIFont.systemFont(ofSize: 12, weight: .bold)
            //limitLine.valueTextColor = UIColor.green.mixed(with: .white, by: 0.5)
            limitLine.label = goalLabel ?? ""
            
            yAxis.drawLimitLinesBehindDataEnabled = true
            yAxis.addLimitLine(limitLine)
        }
        
        // TODO: don't exclude odd numbers
        var samples: [ChartDataEntry] = []
        calculateSamples: do
        {
            var i = 0
            while i < (drinks.count-(granularity-1))
            {
                let drinks = drinks[i..<i+granularity]
                let lastDate = drinks.last?.date
                let entry = drinks.reduce(ChartDataEntry.init(x: 0, y: 0))
                {
                    let date = lastDate?.timeIntervalSince1970 ?? $0.x + (1/Double(granularity)) * $1.date.timeIntervalSince1970
                    return ChartDataEntry.init(x: date, y: $0.y + $1.grams)
                }
                samples.append(entry)
                i += granularity
            }
        }
        
        let set = LineChartDataSet.init(values: samples, label: nil)
        set.lineWidth = 1.75
        set.circleRadius = 4
        set.setColor(.white)
        set.setCircleColor(.white)
        set.highlightColor = .white
        set.drawValuesEnabled = true
        set.valueTextColor = Appearance.themeColor.mixed(with: .white, by: 0.75)
        set.valueFont = UIFont.systemFont(ofSize: 12, weight: .bold)
        set.valueFormatter = DrinksFormatter()
        set.mode = .horizontalBezier
            
        let data = LineChartData.init(dataSets: [set])
        graphView.data = data
        
        //graphView.animate(xAxisDuration: 0.5)
        graphView.animate(yAxisDuration: 0.5, easingOption: .easeOutCubic)
    }
    
    class DrinksFormatter: IValueFormatter
    {
        public func stringForValue(_ value: Double, entry: Charts.ChartDataEntry, dataSetIndex: Int, viewPortHandler: Charts.ViewPortHandler?) -> String
        {
            if value == 0
            {
                return ""
            }
            else
            {
                return Format.format(drinks: value)
            }
        }
    }
    
    class AxisDateFormatter: IAxisValueFormatter
    {
        lazy var dateFormatter: DateFormatter =
        {
            let aFormatter = DateFormatter()
            aFormatter.dateFormat = "M/dd"
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
    
    required public init?(coder aDecoder: NSCoder)
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
    
    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setProgress(_ v: Double)
    {
        self.leftConstraint.constant = bgView.bounds.size.width * CGFloat(v)
        
        if v <= 0.3
        {
            bgViewLeft.backgroundColor = Appearance.greenProgressColor
            bgView.backgroundColor = bgViewLeft.backgroundColor?.mixed(with: .white, by: 0.3)
        }
        else if v <= 0.85
        {
            bgViewLeft.backgroundColor = Appearance.blueProgressColor
            bgView.backgroundColor = bgViewLeft.backgroundColor?.mixed(with: .white, by: 0.3)
        }
        else if v <= 1.0
        {
            bgViewLeft.backgroundColor = Appearance.orangeProgressColor
            bgView.backgroundColor = bgViewLeft.backgroundColor?.mixed(with: .white, by: 0.3)
        }
        else
        {
            bgViewLeft.backgroundColor = Appearance.redProgressColor
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
