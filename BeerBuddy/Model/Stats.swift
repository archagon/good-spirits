//
//  Stats.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-20.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import DataLayer

// This struct is meant to be initialized inline, e.g. Stats(data).progress(from, to)
public struct Stats
{
    private let data: DataLayer
    private let defaults: Defaults
    
    public init(_ data: DataLayer, withDefaults defaults: Defaults = Defaults())
    {
        self.data = data
        self.defaults = defaults
    }
}

extension Stats
{
    public func allowedGramsAlcohol(inRange range: Range<Date>) -> Float
    {
        let standardDrinkSize = self.defaults.standardDrinkSize
        let totalDays = (range.upperBound.timeIntervalSince1970 - range.lowerBound.timeIntervalSince1970) / 60 / 60 / 24
        let allowedGramsAlcohol = totalDays * standardDrinkSize
        
        return Float(allowedGramsAlcohol)
    }
    
    public func percentToDrinks(_ percent: Float, inRange range: Range<Date>) -> Float
    {
        let standardDrinkSize = Float(self.defaults.standardDrinkSize)
        let aga = allowedGramsAlcohol(inRange: range)
        
        let gramsAlcohol = aga * percent
        let drinks = gramsAlcohol / standardDrinkSize
        
        return drinks
    }
    
    public func drinksToPercent(_ drinks: Float, inRange range: Range<Date>) -> Float
    {
        let standardDrinkSize = Float(self.defaults.standardDrinkSize)
        let aga = allowedGramsAlcohol(inRange: range)
        
        let gramsAlcohol = drinks * standardDrinkSize
        let percent = gramsAlcohol / aga
        
        return percent
    }
    
    // current + previous is the percentage alcohol consumption for the given date range.
    public func progress(forModels models: [Model], inRange range: Range<Date>) -> (current: Float, previous: Float)
    {
        if models.count == 0
        {
            return (0, 0)
        }
        
        let aga = allowedGramsAlcohol(inRange: range)
        
        let totalGramsAlcohol = models.reduce(Float(0))
        { total, model in
            let alcoholVolume = model.checkIn.drink.abv * model.checkIn.drink.volume.converted(to: .fluidOunces)
            let standardAlcoholVolume = alcoholVolume.value / 0.6
            let gramsAlcohol = standardAlcoholVolume * 14
            
            return total + Float(gramsAlcohol)
        }
        
        return (totalGramsAlcohol / aga, 0)
    }
    
    public func progress(inRange range: Range<Date>) throws -> (current: Float, previous: Float)
    {
        let models = try! self.data.getModels(fromIncludingDate: range.lowerBound, toExcludingDate: range.upperBound)
        
        return progress(forModels: models.0, inRange: range)
    }
}
