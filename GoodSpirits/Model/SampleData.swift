//
//  SampleData.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-15.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import DataLayer

struct JSONSampleData: Decodable
{
    let checkin_id: Int64
    let untappd_checkin_id: Int64?
    let checkin_time: String
    let drink_name: String?
    let drink_type: String
    let drink_abv: Double
    let drink_price: Double?
    let drink_volume: Double
    let drink_volume_unit: String
}

extension DataLayer
{
    public func populateWithSampleData()
    {
        if
            let path = Bundle.main.path(forResource: "stub", ofType: "json"),
            let data = try? Data.init(contentsOf: URL.init(fileURLWithPath: path))
        {
            let decoder = JSONDecoder.init()
            let sampleData = try! decoder.decode([JSONSampleData].self, from: data)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
            
            for datum in sampleData
            {
                let id = GlobalID.init(siteID: self.owner, operationIndex: DataLayer.wildcardIndex)
                let metadata = Model.Metadata.init(id: id, creationTime: Date())
                let drink = Model.Drink.init(name: datum.drink_name, style: DrinkStyle.init(rawValue: datum.drink_type)!, abv: datum.drink_abv, price: datum.drink_price, volume: Measurement.init(value: datum.drink_volume, unit: UnitVolume.unit(withSymbol: datum.drink_volume_unit)))
                let checkIn = Model.CheckIn.init(untappdId: datum.untappd_checkin_id != nil ? Model.ID(datum.untappd_checkin_id!) : nil, untappdApproved: true, time: dateFormatter.date(from: datum.checkin_time)!, drink: drink)
                let model = Model.init(metadata: metadata, checkIn: checkIn)
                
                self.save(model: model) { _ in }
            }
            
            // QQQ: HACK! at least until we get db notifications working
            // NEXT: why does this work but dispatch etc. does not?
            //sleep(1)
        }
    }
}
