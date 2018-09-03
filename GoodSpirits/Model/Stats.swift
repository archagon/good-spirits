//
//  Stats.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-20.
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
    public func allowedGramsAlcohol(inRange range: Range<Date>) -> Float?
    {
        if let weeklyLimit = self.defaults.weeklyLimit
        {
            let totalDays = (range.upperBound.timeIntervalSince1970 - range.lowerBound.timeIntervalSince1970) / 60 / 60 / 24
            let allowedGramsAlcohol = totalDays * (weeklyLimit / 7)
            
            return Float(allowedGramsAlcohol)
        }
        else
        {
            return nil
        }
    }
    
    public func percentToDrinks(_ percent: Float, inRange range: Range<Date>) -> Float?
    {
        if let aga = allowedGramsAlcohol(inRange: range)
        {
            let standardDrinkSize = Float(self.defaults.standardDrinkSize)
            
            let gramsAlcohol = aga * percent
            let drinks = gramsAlcohol / standardDrinkSize
            
            return drinks
        }
        else
        {
            return nil
        }
    }
    
    public func drinksToPercent(_ drinks: Float, inRange range: Range<Date>) -> Float?
    {
        if let aga = allowedGramsAlcohol(inRange: range)
        {
            let standardDrinkSize = Float(self.defaults.standardDrinkSize)
            
            let gramsAlcohol = drinks * standardDrinkSize
            let percent = gramsAlcohol / aga
            
            return percent
        }
        else
        {
            return nil
        }
    }
    
    // current + previous is the percentage alcohol consumption for the given date range.
    public func progress(forModels models: [Model], inRange range: Range<Date>) -> (current: Float, previous: Float)?
    {
        if let aga = allowedGramsAlcohol(inRange: range)
        {
            let totalGramsAlcohol = models.reduce(Float(0))
            { total, model in
                let gramsAlcohol = gramsOfAlcohol(model)
                return total + Float(gramsAlcohol)
            }
            
            return (totalGramsAlcohol / aga, 0)
        }
        else
        {
            return nil
        }
    }
    
    public func progress(inRange range: Range<Date>) throws -> (current: Float, previous: Float)?
    {
        do
        {
            let models = try self.data.getModels(fromIncludingDate: range.lowerBound, toExcludingDate: range.upperBound, includingDeleted: false)
            return progress(forModels: models.0, inRange: range)
        }
        catch
        {
            appError("could not load models for stats -- \(error)")
            return nil
        }
    }
    
    public func drinks(inRange range: Range<Date>) throws -> Double
    {
        do
        {
            let models = try self.data.getModels(fromIncludingDate: range.lowerBound, toExcludingDate: range.upperBound, includingDeleted: false)
            let allDrinks = models.0.reduce(0) { $0 + standardDrinks($1) }
            return allDrinks
        }
        catch
        {
            appError("could not load models for stats -- \(error)")
            return 0
        }
    }
    
    public func gramsOfAlcohol(_ model: Model) -> Double
    {
        let alcoholVolume = model.checkIn.drink.abv * model.checkIn.drink.volume.converted(to: .fluidOunces)
        let standardAlcoholVolume = alcoholVolume.value / 0.6
        let gramsAlcohol = standardAlcoholVolume * 14
        
        return gramsAlcohol
    }
    
    public func standardDrinks(_ model: Model) -> Double
    {
        let gramsAlcohol = gramsOfAlcohol(model)
        let drinks = gramsAlcohol / Defaults.standardDrinkSize
        
        return drinks
    }
}
