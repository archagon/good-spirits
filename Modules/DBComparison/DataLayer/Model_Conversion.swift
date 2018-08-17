//
//  Model_Conversion.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-15.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

extension Model
{
    // Checks for differences and only updates the lamport timestamp when differences are found.
    public func toData(withLamport t: DataLayer.Time, existingData: DataModel? = nil) -> DataModel
    {
        if let existingData = existingData
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
            
            let metadata = DataModel.Metadata.init(id: self.metadata.id, creationTime: self.metadata.creationTime.timeIntervalSince1970, deleted: deleted)
            let drink = DataModel.Drink.init(name: comp(self.checkIn.drink.name, existingData.checkIn.drink.name), style: comp(self.checkIn.drink.style, existingData.checkIn.drink.style), abv: comp(self.checkIn.drink.abv, existingData.checkIn.drink.abv), price: comp(self.checkIn.drink.price, existingData.checkIn.drink.price), volume: comp(self.checkIn.drink.volume, existingData.checkIn.drink.volume))
            let checkIn = DataModel.CheckIn.init(untappdId: comp(self.checkIn.untappdId, existingData.checkIn.untappdId), time: comp(self.checkIn.time.timeIntervalSince1970, existingData.checkIn.time), drink: drink)
            let data = DataModel.init(metadata: metadata, checkIn: checkIn)
            
            return data
        }
        else
        {
            let metadata = DataModel.Metadata.init(id: self.metadata.id, creationTime: self.metadata.creationTime.timeIntervalSince1970, deleted: .init(v: self.metadata.deleted, t: t))
            let drink = DataModel.Drink.init(name: .init(v: self.checkIn.drink.name, t: t), style: .init(v: self.checkIn.drink.style, t: t), abv: .init(v: self.checkIn.drink.abv, t: t), price: .init(v: self.checkIn.drink.price, t: t), volume: .init(v: self.checkIn.drink.volume, t: t))
            let checkIn = DataModel.CheckIn.init(untappdId: .init(v: self.checkIn.untappdId, t: t), time: .init(v: self.checkIn.time.timeIntervalSince1970, t: t), drink: drink)
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
        let checkIn = Model.CheckIn.init(untappdId: self.checkIn.untappdId.v, time: Date.init(timeIntervalSince1970: self.checkIn.time.v), drink: drink)
        let model = Model.init(metadata: metadata, checkIn: checkIn)
        
        return model
    }
}
