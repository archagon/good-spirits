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
    public typealias DataType = DataAccessProtocol & DataDebugProtocol
    
    public typealias SiteID = UUID
    public typealias Index = UInt32
    public typealias Time = UInt64
    
    public static let calendar = Calendar.init(identifier: .gregorian)
    public let owner: SiteID
    
    private var stores: [DataType]
    private var mainStoreIndex: Int
    
    public var primaryStore: DataAccessProtocol & DataDebugProtocol
    {
        return self.stores[self.mainStoreIndex]
    }
    
    public func store(atIndex i: Int) -> DataAccessProtocol & DataDebugProtocol
    {
        return self.stores[i]
    }
    
    public init(withStore store: DataType, owner: SiteID = UIDevice.current.identifierForVendor!)
    {
        self.owner = owner
        self.mainStoreIndex = 0
        self.stores = []
        
        self.addStore(store)
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
    
    public func getModels(fromIncludingDate from: Date, toExcludingDate to: Date, withCallbackBlock block: @escaping (MaybeError<[Model]>)->Void)
    {
        func ret(_ v: MaybeError<[Model]>)
        {
            onMain
            {
                block(v)
            }
        }
        
        self.primaryStore.readTransaction
        { db in
            db.data(fromIncludingDate: from, toExcludingDate: to)
            {
                switch $0
                {
                case .error(let e):
                    ret(.error(e: e))
                case .value(let v):
                    let models = v.map { $0.toModel() }
                    ret(.value(v: models))
                }
            }
        }
    }
}
