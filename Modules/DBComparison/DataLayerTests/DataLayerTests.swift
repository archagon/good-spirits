//
//  DataLayerTests.swift
//  DataLayerTests
//
//  Created by Alexei Baboulevitch on 2018-8-15.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import XCTest
@testable import DataLayer

class DataLayerTests: XCTestCase
{
    static let id = UUID()
    var data: DataLayer! = nil
    
    override func setUp()
    {
        //print("setup")
        let database = Data_GRDB.init()!
        self.data = DataLayer.init(withStore: database, owner: DataLayerTests.id)
    }
    
    override func tearDown()
    {
        //print("teardown")
        self.data = nil
    }
    
    let randomAdj = ["Gentle", "Spicy", "Meticulous", "Raving", "Bland", "Sour", "Ridiculous", "Hoptacular", "Fresh", "Floppy"]
    let randomNoun = ["Fish", "Waterfall", "Farmyard", "Chapel", "Barrel", "Explosion", "Starlight", "Harvest"]
    let ids = [DataLayerTests.id, DataLayerTests.id, DataLayerTests.id, DataLayerTests.id, DataLayerTests.id, UUID(), UUID()]
    let properties: [String] = ["date", "abv", "volume", "price"]
    let styles: [DrinkStyle] = [.beer, .wine, .sake]
    let units: [UnitVolume] = [.milliliters, .fluidOunces]
    
    func randomData(_ date: Date? = nil) -> Model
    {
        let randomId = self.ids[Int.random(in: 0..<self.ids.count)]
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
        let randomTime = date ?? Date.init(timeInterval: TimeInterval.random(in: -(ds * 7)...(ds * 7)), since: Date())
        
        let id = GlobalID.init(siteID: randomId, operationIndex: DataLayer.wildcardIndex)
        let metadata = Model.Metadata.init(id: id, creationTime: Date(), deleted: false)
        let drink = Model.Drink.init(name: randomName, style: randomStyle, abv: randomABV, price: randomPrice, volume: randomVolume)
        let checkIn = Model.CheckIn.init(untappdId: nil, untappdApproved: false, time: randomTime, drink: drink)
        let model = Model.init(metadata: metadata, checkIn: checkIn)
        
        return model
    }
    
    func testBasics()
    {
        let additions = 50
        let mutations = 20
        
        let centerDate = Date()
        var earliestDate: Date = Date.distantFuture
        var latestDate: Date = Date.distantPast
        var createdModels: [GlobalID:Model] = [:]
        
        testAdditions: do
        {
            for i in 0..<additions
            {
                let date = centerDate.addingTimeInterval(24 * 60 * 60 * TimeInterval(i) - 5)
                earliestDate = min(earliestDate, date)
                latestDate = max(latestDate, date)
                
                let model = randomData(date)
                
                // TODO: how TF does this work?
                let anExpectation = expectation(description: "save data")
                self.data.save(model: model)
                {
                    switch $0
                    {
                    case .error(let e):
                        XCTAssertNil(e)
                    case .value(let v):
                        createdModels[v] = model
                    }

                    anExpectation.fulfill()
                }
                waitForExpectations(timeout: 1, handler: nil)
            }
        }
        
        testIDRetrieval: do
        {
            for (id, oldData) in createdModels
            {
                let anExpectation = expectation(description: "get data")
                self.data.load(model: id)
                {
                    switch $0
                    {
                    case .error(let e):
                        XCTAssertNil(e)
                    case .value(let v):
                        if let newData = v
                        {
                            XCTAssertEqual(oldData.checkIn, newData.checkIn)
                            XCTAssertEqual(oldData.metadata.creationTime, newData.metadata.creationTime)
                            XCTAssertEqual(oldData.metadata.id.siteID, newData.metadata.id.siteID)
                            XCTAssertNotEqual(oldData.metadata.id.operationIndex, newData.metadata.id.operationIndex)
                            XCTAssertNotEqual(newData.metadata.id.operationIndex, DataLayer.wildcardIndex)
                        }
                        else
                        {
                            XCTAssert(false)
                        }
                    }
                    
                    anExpectation.fulfill()
                }
                waitForExpectations(timeout: 1, handler: nil)
            }
        }
        
        testDateRetrieval: do
        {
            let anExpectation = expectation(description: "get data")
            self.data.getModels(fromIncludingDate: earliestDate, toExcludingDate: latestDate.addingTimeInterval(1))
            {
                switch $0
                {
                case .error(let e):
                    XCTAssertNil(e)
                case .value(let set):
                    var retrievedModels: [GlobalID:Model] = [:]
                    set.0.forEach { retrievedModels[$0.metadata.id] = $0 }
                    
                    XCTAssertEqual(retrievedModels.count, createdModels.count)
                    
                    for (site, oldData) in createdModels
                    {
                        if let newData = retrievedModels[site]
                        {
                            XCTAssertEqual(oldData.checkIn, newData.checkIn)
                            XCTAssertEqual(oldData.metadata.creationTime, newData.metadata.creationTime)
                            XCTAssertEqual(oldData.metadata.id.siteID, newData.metadata.id.siteID)
                            XCTAssertNotEqual(oldData.metadata.id.operationIndex, newData.metadata.id.operationIndex)
                            XCTAssertNotEqual(newData.metadata.id.operationIndex, DataLayer.wildcardIndex)
                        }
                        else
                        {
                            XCTAssert(false)
                        }
                    }
                    
                    anExpectation.fulfill()
                }
            }
            waitForExpectations(timeout: 1, handler: nil)
        }
        
        mutations: do
        {
            for _ in 0..<mutations
            {
                let key = Array(createdModels.keys)[Int.random(in: 0..<createdModels.keys.count)]
                
                
                let anExpectation = expectation(description: "mutate data")
                self.data.load(model: key)
                {
                    switch $0
                    {
                    case .error(let e):
                        XCTAssertNil(e)
                        anExpectation.fulfill()
                    case .value(let v):
                        if let model = v
                        {
                            var newModel = model
                            
                            let randomValues = self.randomData()
                            newModel.checkIn.time = randomValues.checkIn.time
                            newModel.checkIn.drink.abv = randomValues.checkIn.drink.abv
                            newModel.checkIn.drink.volume = randomValues.checkIn.drink.volume
                        
                            self.data.save(model: newModel)
                            {
                                switch $0
                                {
                                case .error(let e):
                                    XCTAssertNil(e)
                                    anExpectation.fulfill()
                                case .value(let v):
                                    self.data.load(model: v)
                                    {
                                        switch $0
                                        {
                                        case .error(let e):
                                            XCTAssertNil(e)
                                        case .value(let v):
                                            if let v = v
                                            {
                                                XCTAssertEqual(v.checkIn.drink.price, model.checkIn.drink.price)
                                                XCTAssertEqual(v.checkIn.drink.style, model.checkIn.drink.style)
                                                XCTAssertEqual(v.checkIn.drink.name, model.checkIn.drink.name)
                                                XCTAssertNotEqual(v.checkIn.time, model.checkIn.time)
                                                XCTAssertNotEqual(v.checkIn.drink.abv, model.checkIn.drink.abv)
                                                XCTAssertNotEqual(v.checkIn.drink.volume, model.checkIn.drink.volume)
                                            }
                                            else
                                            {
                                                XCTAssert(false)
                                            }
                                        }
                                        
                                        anExpectation.fulfill()
                                    }
                                }
                            }
                        }
                        else
                        {
                            XCTAssert(false)
                            anExpectation.fulfill()
                        }
                    }
                }
                waitForExpectations(timeout: 1, handler: nil)
            }
        }
        
        noOpSave: do
        {
            let key = Array(createdModels.keys)[Int.random(in: 0..<createdModels.keys.count)]
            
            let anExpectation = expectation(description: "no-op save data")
            self.data.load(model: key)
            {
                switch $0
                {
                case .error(let e):
                    XCTAssertNil(e)
                    anExpectation.fulfill()
                case .value(let v):
                    if let model = v
                    {
                        self.data.save(model: model)
                        {
                            switch $0
                            {
                            case .error(let e):
                                XCTAssertNil(e)
                                anExpectation.fulfill()
                            case .value(let v):
                                self.data.load(model: v)
                                {
                                    switch $0
                                    {
                                    case .error(let e):
                                        XCTAssertNil(e)
                                    case .value(let v):
                                        if let v = v
                                        {
                                            XCTAssertEqual(v, model)
                                        }
                                        else
                                        {
                                            XCTAssert(false)
                                        }
                                        
                                        anExpectation.fulfill()
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        XCTAssert(false)
                        anExpectation.fulfill()
                    }
                }
            }
            waitForExpectations(timeout: 1, handler: nil)
        }
    }
    
    func testBatchCommit()
    {
        let count = 1000
        
        //measureSingle: do
        //{
        //    var data: [Model] = []
        //    for _ in 0..<count { data.append(randomData()) }
        //
        //    self.measure
        //    {
        //        for i in 0..<count
        //        {
        //            let anExpectation = expectation(description: "get data")
        //            self.data.save(model: data[i])
        //            { _ in
        //                anExpectation.fulfill()
        //            }
        //            waitForExpectations(timeout: 1, handler: nil)
        //        }
        //    }
        //}
        
        measureBatch: do
        {
            var data: [DataModel] = []
            for i in 0..<count { data.append(randomData().toData(withLamport: DataLayer.Time(i))) }
            
            self.measure
            {
                let anExpectation = expectation(description: "batch save data")
                self.data.primaryStore.readWriteTransaction
                { db in
                    db.commit(data: data, withSite: DataLayerTests.id)
                    {
                        switch $0
                        {
                        case .error(let e):
                            XCTAssertNil(e)
                        case .value(_):
                            break
                        }
                        
                        anExpectation.fulfill()
                    }
                }
                waitForExpectations(timeout: 30, handler: nil)
            }
        }
    }
    
}
