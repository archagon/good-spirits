//
//  Data_Null.swift
//  DataLayer
//
//  Created by Alexei Baboulevitch on 2018-8-23.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public class Data_Null
{
    public init() {}
}

extension Data_Null: DataAccessProtocol, DataAccessProtocolImmediate
{
    public func readTransaction(_ block: @escaping (DataProtocol) -> ()) {
        block(self)
    }
    
    public func readWriteTransaction(_ block: @escaping (DataWriteProtocol) -> ()) {
        block(self)
    }
    
    public func initialize() throws {
    }
    
    public func readTransaction<T>(_ block: @escaping (DataProtocolImmediate) throws -> T) rethrows -> T {
        return try block(self)
    }
    
    public func readWriteTransaction<T>(_ block: @escaping (DataWriteProtocolImmediate) throws -> T) rethrows -> T {
        return try block(self)
    }
    
}

extension Data_Null: DataObservationProtocol
{
    public static var DataDidChangeNotification: Notification.Name = Notification.Name.init("NullDataDidChangeNotification")
}

extension Data_Null: DataWriteProtocol, DataWriteProtocolImmediate
{
    public func commit(data: DataModel, withSite: DataLayer.SiteID) throws -> GlobalID {
        return GlobalID.zero
    }
    
    public func commit(data: [DataModel], withSite: DataLayer.SiteID) throws -> [GlobalID] {
        return []
    }
    
    public func sync(data: Set<DataModel>, withOperationLog: DataLayer.OperationLog) throws {
    }
    
    public func lamportTimestamp() throws -> DataLayer.Time {
        return 0
    }
    
    public func vectorTimestamp() throws -> VectorClock {
        return VectorClock.init(map: [:])
    }
    
    public func operationLog(forSite site: DataLayer.SiteID) throws -> [GlobalID] {
        return []
    }
    
    public func operationLog(afterTimestamp timestamp: VectorClock) throws -> DataLayer.OperationLog {
        return [:]
    }
    
    public func nextOperationIndex(forSite site: DataLayer.SiteID) throws -> DataLayer.Index {
        return 0
    }
    
    public func data(forID id: GlobalID) throws -> DataModel? {
        return nil
    }
    
    public func lastAddedData() throws -> DataModel? {
        return nil
    }
    
    public func data(afterTimestamp timestamp: VectorClock) throws -> (Set<DataModel>, VectorClock) {
        return ([], VectorClock.init(map: [:]))
    }
    
    public func data(fromIncludingDate from: Date, toExcludingDate to: Date, afterTimestamp: VectorClock?) throws -> ([DataModel], VectorClock) {
        return ([], VectorClock.init(map: [:]))
    }
    
    public func pendingUntappd() throws -> ([DataModel], VectorClock) {
        return ([], VectorClock.init(map: [:]))
    }
}

extension Data_Null: DataDebugProtocol
{
    public func _asserts() {}
}

