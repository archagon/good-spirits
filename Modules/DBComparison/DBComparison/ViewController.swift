//
//  ViewController.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-5.
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

import UIKit
import GRDB
import DataLayer

// NEXT: figure out threading woes -- how to link up multiple database calls, when each one might be serialized to its own thread, or even the main thread
// NEXT: database container w/throws and threading

class ViewController: UIViewController
{
    var data: DataLayer!
    
    var firstOwner: DataLayer.SiteID { return data.owner }
    let secondOwner = UUID()
    let thirdOwner = UUID()
    
    var primaryStore: DataAccessProtocol & DataDebugProtocol { return self.data.primaryStore }
    var secondaryStore: DataAccessProtocol & DataDebugProtocol { return self.data.store(atIndex: 1) }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //let memDB = Data_Memory.init()
        //let memDB = Data_FMDB.init()!
        let memDB = Data_GRDB.init()!
        let secondDB = Data_Memory.init()
        //let secondDB = Data_FMDB.init()!
        //let secondDB = Data_GRDB.init()!
        
        self.data = DataLayer.init(withStore: memDB)
        self.data.addStore(secondDB)
        
        print("first owner: \(self.firstOwner.hashValue)")
        print("second owner: \(self.secondOwner.hashValue)")
        
        func compAssert(_ ops: Int)
        {
            let data1 = primaryStore._allData().sorted { $0.metadata.id < $1.metadata.id }
            let data2 = secondaryStore._allData().sorted { $0.metadata.id < $1.metadata.id }
            assert(data1.count == data2.count)
            for i in 0..<data1.count
            {
                let op1 = data1[i]
                let op2 = data2[i]
                if op1 != op2
                {
                    print(op1.debugDescription)
                    print(op2.debugDescription)
                    assert(false)
                }
            }
            
            let ops1 = primaryStore._allOperations()
            let ops2 = secondaryStore._allOperations()
            assert(ops1.count == ops2.count)
            assert(ops1.count == ops)
            for (i, op1) in ops1.enumerated()
            {
                let op2 = ops2[i]
                assert(op1.0 == op2.0)
                assert(op1.1 == op2.1)
                assert(op1.2 == op2.2)
            }
        }
        
        beginnerStuff: do
        {
            break beginnerStuff
            
            additions(10)
            mutations(10)
        }
        
        basicTest: do
        {
            break basicTest
            
            additions(100)
            mutations(100)
            mutations(50, withData: (primaryStore, owner: secondOwner))
            mutations(50)
            additions(20, withData: (primaryStore, owner: secondOwner))
            additions(10)
            
            assert(primaryStore._allOperations().count == 330)
        }
        
        syncTest: do
        {
//            break syncTest
            
            additions(100)
            mutations(100)
            sync(data1: primaryStore, toData2: secondaryStore)
            mutations(50, withData: (primaryStore, owner: secondOwner))
            mutations(50)
            //sync(data1: primaryStore, toData2: primaryStore)
            additions(20, withData: (primaryStore, owner: secondOwner))
            sync(data1: primaryStore, toData2: secondaryStore)
            additions(10)
            sync(data1: primaryStore, toData2: secondaryStore)

            additions(20, withData: (secondaryStore, owner: thirdOwner))
            mutations(20, withData: (secondaryStore, owner: thirdOwner))
            additions(10)
            mutations(30)
            sync(data1: primaryStore, toData2: secondaryStore)
            sync(data1: secondaryStore, toData2: primaryStore)
            
            compAssert(410)
        }
        
        let date = Date()
        let daySeconds: TimeInterval = 24 * 60 * 60
        let from = date.addingTimeInterval(-2 * daySeconds)
        let to = date.addingTimeInterval(2 * daySeconds)
        
        //let request = DataModel.filter(DataModel.Columns.checkin_time_value >= from.timeIntervalSince1970 && DataModel.Columns.checkin_time_value < to.timeIntervalSince1970)
        //try! (self.primaryStore as! Data_GRDB).explain(request: request)
        
        maxLimitSpeedTest: do
        {
            break maxLimitSpeedTest
            
            // 15 seconds
            timeMe({
                additions(100000)
            }, "additions")
            
            sleep(2)
            
            // 0.5 seconds
            timeMe({
                let date = Date()
                let daySeconds: TimeInterval = 24 * 60 * 60
                let from = date.addingTimeInterval(-0.25 * daySeconds)
                let to = date.addingTimeInterval(0.25 * daySeconds)
                
                let entries = primaryStore._data(fromIncludingDate: from, toExcludingDate: to)
                print("number of entries: \(entries.count)")
            }, "date query")
        }
        
        print("tests complete!")
    }
    
    let randomAdj = ["Gentle", "Spicy", "Meticulous", "Raving", "Bland", "Sour", "Ridiculous", "Hoptacular", "Fresh", "Floppy"]
    let randomNoun = ["Fish", "Waterfall", "Farmyard", "Chapel", "Barrel", "Explosion", "Starlight", "Harvest"]
    let properties: [String] = ["date", "abv", "volume", "price"]
    let styles: [DrinkStyle] = [.beer, .wine, .sake]
    let units: [UnitVolume] = [.milliliters, .fluidOunces]
    
    func additions(_ count: Int, withData optData: (store: DataAccessProtocol & DataDebugProtocol, owner: DataLayer.SiteID)? = nil)
    {
        let data = optData ?? (self.primaryStore, self.data.owner)
     
        //let initialCount = data.store._allData().count
        
        var items: Set<DataModel> = Set()
        
        var group = DispatchGroup()
        group.enter()
        
        data.store.readTransaction
        {
            $0.lamportTimestamp()
            { timestamp in
                defer { group.leave() }
                
                switch timestamp
                {
                case .error(let e):
                    assert(false, "\(e)")
                case .value(var tmp):
                    for i in 0..<count
                    {
                        func it() -> DataLayer.Time
                        {
                            tmp += 1
                            return tmp
                        }
                        
                        let r1 = Int.random(in: 0..<self.randomAdj.count)
                        let r2 = Int.random(in: 0..<self.randomNoun.count)
                        let randomName = self.randomAdj[r1] + " " + self.randomNoun[r2]
                        let rs = Int.random(in: 0..<self.styles.count)
                        let randomStyle = self.styles[rs]
                        let randomABV = Double.random(in: 0...0.3)
                        let randomPrice = Double.random(in: 0...50)
                        let ru = Int.random(in: 0..<self.units.count)
                        let randomVolume = Measurement.init(value: Double.random(in: 0...150), unit: self.units[ru])
                        let ds: TimeInterval = 24 * 60 * 60
                        let randomTime = Date.init(timeInterval: TimeInterval.random(in: -(ds * 7)...(ds * 7)), since: Date()).timeIntervalSince1970
                        var randomCreationTime = Date.init(timeInterval: TimeInterval.random(in: -(ds * 0.25)...(ds * 0.25)), since: Date()).timeIntervalSince1970
                        
                        let id = DataLayer.wildcardID(withOwner: data.owner)
                        let metadata = DataModel.Metadata.init(id: id, creationTime: randomCreationTime)
                        let drink = DataModel.Drink.init(name: .init(v: randomName, t: it()), style: .init(v: randomStyle, t: it()), abv: .init(v: randomABV, t: it()), price: .init(v: randomPrice, t: it()), volume: .init(v: randomVolume, t: it()))
                        let checkIn = DataModel.CheckIn.init(untappdId: .init(v: nil, t: it()), time: .init(v: randomTime, t: it()), drink: drink)
                        let item = DataModel.init(metadata: metadata, checkIn: checkIn)
                        
                        items.insert(item)
                    }
                }
            }
        }
        
        group.wait()
        
        group = DispatchGroup()
        group.enter()
        
        data.store.readWriteTransaction
        {
            $0.commit(data: Array(items), withSite: data.owner)
            {
                switch $0
                {
                case .error(let e):
                    assert(false, "\(e)")
                case .value(let v):
                    break
                }
                
                group.leave()
            }
        }
        
        group.wait()
        
        let store = data.store
        store._asserts()
        
        print("commit complete!")
    }
    
    func mutations(_ count: Int, withData optData: (store: DataAccessProtocol & DataDebugProtocol, owner: DataLayer.SiteID)? = nil)
    {
        let data = optData ?? (self.primaryStore, self.data.owner)
        
        let group = DispatchGroup()
        
        for i in 0..<count
        {
            group.enter()
        }
        
        data.store.readWriteTransaction
        { db in
            db.data(afterTimestamp: VectorClock.init(map: [:]))
            {
                for i in 0..<count
                {
                    switch $0
                    {
                    case .error(let e):
                        assert(false, "\(e)")
                        group.leave()
                    case .value(let v):
                        let originalItem = v.randomElement()!
                        var randomItem = originalItem
                        
                        db.lamportTimestamp()
                        {
                            let originalItem = originalItem //for debugging
                            
                            switch $0
                            {
                            case .error(let e):
                                assert(false, "\(e)")
                                group.leave()
                            case .value(var tmp):
                                func it() -> DataLayer.Time
                                {
                                    tmp += 1
                                    return tmp
                                }
                                
                                let properties = Int.random(in: 1..<self.properties.count)
                                var randomProperties = self.properties.shuffled()
                                
                                for i in 0..<properties
                                {
                                    let property = randomProperties[i]
                                    
                                    if property == "date"
                                    {
                                        let ds: TimeInterval = 24 * 60 * 60
                                        let randomTime = Date.init(timeInterval: TimeInterval.random(in: -(ds * 7)...(ds * 7)), since: Date.init(timeIntervalSince1970: randomItem.checkIn.time.v)).timeIntervalSince1970
                                        randomItem.checkIn.time = .init(v: randomTime, t: it())
                                    }
                                    else if property == "abv"
                                    {
                                        let randomABV = Double.random(in: 0...0.3)
                                        randomItem.checkIn.drink.abv = .init(v: randomABV, t: it())
                                    }
                                    else if property == "volume"
                                    {
                                        let ru = Int.random(in: 0..<self.units.count)
                                        let randomVolume = Measurement.init(value: Double.random(in: 0...150), unit: self.units[ru])
                                        randomItem.checkIn.drink.volume = .init(v: randomVolume, t: it())
                                    }
                                    else if property == "price"
                                    {
                                        let randomPrice = Double.random(in: 0...50)
                                        randomItem.checkIn.drink.price = .init(v: randomPrice, t: it())
                                    }
                                }
                                
                                db.commit(data: randomItem, withSite: data.owner)
                                {
                                    switch $0
                                    {
                                    case .error(let e):
                                        assert(false, "\(e)")
                                    case .value(let v):
                                        break
                                    }
                                    
                                    group.leave()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        group.wait()
        
        let store = data.store
        store._asserts()
        
        print("mutations complete!")
    }
    
    func sync(data1: DataAccessProtocol & DataDebugProtocol, toData2 data2: DataAccessProtocol & DataDebugProtocol)
    {
        let gate = DispatchGroup()
        
        var d2Timestamp: VectorClock! = nil
        var ops: Set<DataModel>! = nil
        var opLog: DataLayer.OperationLog! = nil
        
        func commitData()
        {
            data2.readWriteTransaction
            { db2 in
                db2.sync(data: ops, withOperationLog: opLog)
                {
                    if let error = $0
                    {
                        assert(false, "\(error)")
                    }

                    gate.leave()
                }
            }
        }
        
        func getData()
        {
            data1.readTransaction
            { db1 in
                db1.data(afterTimestamp: d2Timestamp)
                {
                    switch $0
                    {
                    case .error(let e):
                        assert(false, "\(e)")
                        gate.leave()
                    case .value(let ops2):
                        db1.operationLog(afterTimestamp: d2Timestamp)
                        {
                            switch $0
                            {
                            case .error(let e):
                                assert(false, "\(e)")
                                gate.leave()
                            case .value(let opLog2):
                                ops = ops2
                                opLog = opLog2
                                gate.leave()
                            }
                        }
                    }
                }
            }
        }
        
        func getTimestamp()
        {
            data2.readTransaction
            { db2 in
                db2.vectorTimestamp()
                {
                    switch $0
                    {
                    case .error(let e):
                        assert(false, "\(e)")
                        gate.leave()
                    case .value(let d2Timestamp2):
                        d2Timestamp = d2Timestamp2
                        gate.leave()
                    }
                }
            }
        }
        
        gate.enter()
        getTimestamp()
        gate.wait()
        
        gate.enter()
        getData()
        gate.wait()
        
        gate.enter()
        commitData()
        gate.wait()
        
        print("sync complete!")
    }
}

