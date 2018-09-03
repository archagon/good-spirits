//
//  Model_Conversion.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-15.
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

extension Model
{
    // Checks for differences and only updates the lamport timestamp when differences are found.
    public func toData(withLamport t: DataLayer.Time, existingData: DataModel? = nil) -> DataModel
    {
        var comparisonData: DataModel? = existingData
        
        // AB: Untappd approval is a special merge case. These checkins are saved to the database on receipt, and we
        // don't want a device that receives an Untappd checkin to overwrite an already approved checkin on another
        // device with the default data, just because the Lamport timestamp is higher. Ergo, the approved flag trumps all.
        // TODO: This is a quick and dirty solution. Ideally, we need to update the Lamport timestamps as well. This
        // only works because we're updating models atomically, not streaming individual LWW changes.
        if let existingData = existingData
        {
            if self.checkIn.untappdApproved && !existingData.checkIn.untappdApproved.v
            {
                comparisonData = nil
            }
            else if !checkIn.untappdApproved && existingData.checkIn.untappdApproved.v
            {
                return existingData
            }
        }
        
        if let existingData = comparisonData
        {
            func comp<T>(_ curr: T, _ prev: LamportValue<T>) -> LamportValue<T>
            {
                assert(prev.t < t)
                
                if prev.v != curr
                {
                    return .init(v: curr, t: t)
                }
                else
                {
                    return prev
                }
            }
            
            let deleted = (self.metadata.deleted && !existingData.metadata.deleted.v ? LamportValue.init(v: true, t: t) : existingData.metadata.deleted)
            let untappdApproved = (self.checkIn.untappdApproved && !existingData.checkIn.untappdApproved.v ? LamportValue.init(v: true, t: t) : existingData.checkIn.untappdApproved)
            
            let metadata = DataModel.Metadata.init(id: self.metadata.id, creationTime: self.metadata.creationTime.timeIntervalSince1970, deleted: deleted)
            let drink = DataModel.Drink.init(name: comp(self.checkIn.drink.name, existingData.checkIn.drink.name), style: comp(self.checkIn.drink.style, existingData.checkIn.drink.style), abv: comp(self.checkIn.drink.abv, existingData.checkIn.drink.abv), price: comp(self.checkIn.drink.price, existingData.checkIn.drink.price), volume: comp(self.checkIn.drink.volume, existingData.checkIn.drink.volume))
            let checkIn = DataModel.CheckIn.init(untappdId: comp(self.checkIn.untappdId, existingData.checkIn.untappdId), untappdApproved: untappdApproved, time: comp(self.checkIn.time.timeIntervalSince1970, existingData.checkIn.time), drink: drink)
            let data = DataModel.init(metadata: metadata, checkIn: checkIn)
            
            return data
        }
        else
        {
            let metadata = DataModel.Metadata.init(id: self.metadata.id, creationTime: self.metadata.creationTime.timeIntervalSince1970, deleted: .init(v: self.metadata.deleted, t: t))
            let drink = DataModel.Drink.init(name: .init(v: self.checkIn.drink.name, t: t), style: .init(v: self.checkIn.drink.style, t: t), abv: .init(v: self.checkIn.drink.abv, t: t), price: .init(v: self.checkIn.drink.price, t: t), volume: .init(v: self.checkIn.drink.volume, t: t))
            let checkIn = DataModel.CheckIn.init(untappdId: .init(v: self.checkIn.untappdId, t: t), untappdApproved: .init(v: self.checkIn.untappdApproved, t: t), time: .init(v: self.checkIn.time.timeIntervalSince1970, t: t), drink: drink)
            let data = DataModel.init(metadata: metadata, checkIn: checkIn)
            
            return data
        }
    }
}

extension DataModel
{
    public func toModel() -> Model
    {
        let metadata = Model.Metadata.init(id: self.metadata.id, creationTime: Date.init(timeIntervalSince1970: self.metadata.creationTime), deleted: self.metadata.deleted.v)
        let drink = Model.Drink.init(name: self.checkIn.drink.name.v, style: self.checkIn.drink.style.v, abv: self.checkIn.drink.abv.v, price: self.checkIn.drink.price.v, volume: self.checkIn.drink.volume.v)
        let checkIn = Model.CheckIn.init(untappdId: self.checkIn.untappdId.v, untappdApproved: self.checkIn.untappdApproved.v, time: Date.init(timeIntervalSince1970: self.checkIn.time.v), drink: drink)
        let model = Model.init(metadata: metadata, checkIn: checkIn)
        
        return model
    }
}
