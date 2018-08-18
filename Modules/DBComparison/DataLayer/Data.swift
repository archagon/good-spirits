//
//  Data.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-5.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import UIKit

// TODO: automatic sync between main and remote store
// TODO: notifications
// Persistent store coordinator.
public class DataLayer
{
    public typealias OperationLog = [DataLayer.SiteID : (startingIndex: DataLayer.Index, operations: [GlobalID])]
    public typealias DataType = DataAccessProtocol & DataDebugProtocol & DataObservationProtocol
    
    public typealias SiteID = UUID
    public typealias Index = UInt32
    public typealias Time = UInt64
    
    public static let calendar = Calendar.init(identifier: .gregorian)
    public let owner: SiteID
    
    private var stores: [DataType]
    private var mainStoreIndex: Int
    
    public var primaryStore: DataType & DataAccessProtocolImmediate
    {
        return self.stores[self.mainStoreIndex] as! (DataType & DataAccessProtocolImmediate)
    }
    
    public func store(atIndex i: Int) -> DataType
    {
        return self.stores[i]
    }
    
    public init(withStore store: DataType & DataAccessProtocolImmediate, owner: SiteID = UIDevice.current.identifierForVendor!)
    {
        self.owner = owner
        self.mainStoreIndex = 0
        self.stores = []
        
        self.addStore(store)
        
        NotificationCenter.default.addObserver(forName: type(of: store).DataDidChangeNotification, object: nil, queue: nil)
        { notification in
            // BUGFIX: We get into a locked state without this async! GRDB posts notification and then locks
            // while waiting on other db access from main thread.
            onMain
            {
                NotificationCenter.default.post(name: type(of: self).DataDidChangeNotification, object: self)
            }
        }
    }
    
    public func addStore(_ store: DataType)
    {
        self.stores.append(store)
        
        let dispatch = DispatchGroup()
        dispatch.enter()
        
        store.initialize
        {
            assert($0 == nil)
            dispatch.leave()
        }
        
        dispatch.wait()
    }
}

extension DataLayer
{
    public static var wildcardIndex: Index = Index.max
    public static func wildcardID(withOwner owner: SiteID) -> GlobalID
    {
        return GlobalID.init(siteID: owner, operationIndex: wildcardIndex)
    }
}

extension DataLayer: DataObservationProtocol
{
    public static var DataDidChangeNotification: Notification.Name = Notification.Name.init(rawValue: "DataDidChangeNotification")
}

public enum DataError: StringLiteralType, Error
{
    case couldNotOpenStore
    case missingPreceedingOperations
    case wrongSyncCommitChoice
    case mismatchedOperation
    case improperOperationFormat
    case internalError
    case unknownError
}

// Intended to be called from the main thread.
extension DataLayer
{
    public typealias Token = VectorClock
    public static var NullToken = VectorClock.init(map: [:])
    
    public func save(model: Model, withCallbackBlock block: @escaping (MaybeError<GlobalID>)->Void)
    {
        func ret(id: GlobalID)
        {
            onMain
            {
                block(.value(v: id))
            }
        }
        func ret(e: Error)
        {
            onMain
            {
                block(.error(e: e))
            }
        }
        
        self.primaryStore.readWriteTransaction
        { db in
            db.lamportTimestamp
            {
                switch $0
                {
                case .error(let e):
                    ret(e: e)
                case .value(let t):
                    db.data(forID: model.metadata.id)
                    {
                        switch $0
                        {
                        case .error(let e):
                            ret(e: e)
                        case .value(let p):
                            let data = model.toData(withLamport: t + 1, existingData: p)
                            db.commit(data: data, withSite: self.owner)
                            {
                                switch $0
                                {
                                case .error(let e):
                                    ret(e: e)
                                case .value(let id):
                                    ret(id: id)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func load(model: GlobalID, withCallbackBlock block: @escaping (MaybeError<Model?>)->Void)
    {
        func ret(_ v: MaybeError<Model?>)
        {
            onMain
            {
                block(v)
            }
        }
        
        self.primaryStore.readTransaction
        { db in
            db.data(forID: model)
            {
                switch $0
                {
                case .error(let e):
                    ret(.error(e: e))
                case .value(let p):
                    let model = p?.toModel()
                    ret(.value(v: model))
                }
            }
        }
    }
    
    public func getModels(fromIncludingDate from: Date, toExcludingDate to: Date, withToken token: Token? = nil, withCallbackBlock block: @escaping (MaybeError<([Model], Token)>)->Void)
    {
        func ret(_ v: MaybeError<([Model], Token)>)
        {
            onMain
            {
                block(v)
            }
        }
        
        self.primaryStore.readTransaction
        { db in
            db.data(fromIncludingDate: from, toExcludingDate: to, afterTimestamp: token)
            {
                switch $0
                {
                case .error(let e):
                    ret(.error(e: e))
                case .value(let v):
                    let models = v.0.map { $0.toModel() }
                    ret(.value(v: (models, v.1)))
                }
            }
        }
    }
    
    public func getModels(fromIncludingDate from: Date, toExcludingDate to: Date, withToken token: Token? = nil) throws -> ([Model], Token)
    {
        return try self.primaryStore.readTransaction
        { db -> ([Model], Token) in
            let v = try db.data(fromIncludingDate: from, toExcludingDate: to, afterTimestamp: token)
            let models = v.0.map { $0.toModel() }
            return (models, v.1)
        }
    }
    
    public func getLastAddedModel() throws -> Model?
    {
        return try self.primaryStore.readTransaction
        { db -> Model? in
            let data = try db.lastAddedData()
            return data?.toModel()
        }
    }
}
