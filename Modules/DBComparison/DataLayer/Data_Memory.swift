//
//  Data_Memory.swift
//  DBComparison
//
//  Created by Alexei Baboulevitch on 2018-8-6.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public class Data_Memory
{
    private var operations: [DataLayer.SiteID:[GlobalID]] = [:]
    private var data: [GlobalID:DataModel] = [:]
    private var dataSortedByDate: [DataModel] = []
    private var lamport: DataLayer.Time = 0
    private let queue: DispatchQueue = DispatchQueue.init(label: "MemoryQueue", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
    
    public init() {}
}

extension Data_Memory: DataAccessEasySyncProtocol {}

// Brute force thread safety by serializing on main thread.
extension Data_Memory: DataAccessProtocol
{
    public func initialize(_ block: @escaping (Error?)->Void)
    {
        self.queue.async
        {
            block(nil)
        }
    }
    
    public func readTransaction(_ block: @escaping (_ data: DataProtocol)->())
    {
        self.queue.async
        {
            block(self)
        }
    }
    
    public func readWriteTransaction(_ block: @escaping (_ data: DataWriteProtocol)->())
    {
        self.queue.async
        {
            block(self)
        }
    }
}

// NOT thread-safe! Be careful!
extension Data_Memory: DataWriteProtocol
{
    public func lamportTimestamp(withCompletionBlock block: (MaybeError<DataLayer.Time>)->())
    {
        block(MaybeError.value(v: self.lamport))
    }
    
    public func vectorTimestamp(withCompletionBlock block: (MaybeError<VectorClock>)->())
    {
        let clock = VectorClock.init(map: self.operations.mapValues { DataLayer.Time($0.count - 1) })
        block(MaybeError.value(v: clock))
    }
    
    public func operationLog(forSite site: DataLayer.SiteID, withCompletionBlock block: (MaybeError<[GlobalID]>)->())
    {
        block(MaybeError.value(v: self.operations[site] ?? []))
    }
    
    public func operationLog(afterTimestamp timestamp: VectorClock, withCompletionBlock block: @escaping (MaybeError<DataLayer.OperationLog>)->())
    {
        var returnSet: [DataLayer.SiteID:(DataLayer.Index,[GlobalID])] = [:]
        
        for (site, operations) in self.operations
        {
            if let index = timestamp.time(forSite: site)
            {
                if index < operations.count
                {
                    returnSet[site] = (DataLayer.Index(index), Array(operations[Int(index)..<operations.count]))
                }
            }
            else
            {
                returnSet[site] = (0, operations)
            }
        }
        
        block(MaybeError.value(v: returnSet))
    }
    
    public func nextOperationIndex(forSite site: DataLayer.SiteID, withCompletionBlock block: (MaybeError<DataLayer.Index>)->())
    {
        block(MaybeError.value(v: DataLayer.Index(operations[site]?.count ?? 0)))
    }
    
    public func data(forID id: GlobalID, withCompletionBlock block: (MaybeError<DataModel?>)->())
    {
        block(MaybeError.value(v: self.data[id]))
    }
    
    public func data(afterTimestamp timestamp: VectorClock, withCompletionBlock block: @escaping (MaybeError<Set<DataModel>>)->())
    {
        operationLog(afterTimestamp: timestamp)
        {
            switch $0
            {
            case .error(let e):
                block(MaybeError.error(e: e))
            case .value(let v):
                let set = v.reduce(Set<GlobalID>()) { set, pair in return set.union(pair.value.operations) }
                var returnSet = Set<DataModel>()
                for item in set { returnSet.insert(self.data[item]!) }
                block(MaybeError.value(v: returnSet))
            }
        }
    }
    
    // TODO: check
    public func data(fromIncludingDate from: Date, toExcludingDate to: Date, withCompletionBlock block: (MaybeError<[DataModel]>)->())
    {
        // PERF: should use binary search
        let startIndex = self.dataSortedByDate.firstIndex
        {
            return Date.init(timeIntervalSince1970: $0.checkIn.time.v) >= from
        }
        
        // PERF: should use binary search
        let endIndex = self.dataSortedByDate.lastIndex
        {
            return Date.init(timeIntervalSince1970: $0.checkIn.time.v) < to
        }
        
        guard let aStartIndex = startIndex, let aEndIndex = endIndex else
        {
            block(MaybeError.value(v: []))
            return
        }
        
        block(MaybeError.value(v: Array(self.dataSortedByDate[aStartIndex...aEndIndex])))
    }
    
    // Assumes passed-in data is complete and filled in, with correct indices, and without any wildcards.
    public func syncInSequence(data: Set<DataModel>, withOperationLog operationLog: DataLayer.OperationLog, completionBlock block: @escaping (Error?)->Void)
    {
        assert(operationLog.values.reduce(Set()) { set, pair in return set.union(pair.operations) } ==
            Set(data.map { return $0.metadata.id }), "data and index map don't match")
        
        if data.count == 0
        {
            block(nil)
            return
        }
        
        var processed: Set<GlobalID> = Set()
        
        func stepTwo(dataID: GlobalID, site: DataLayer.SiteID, index: DataLayer.Index) -> Error?
        {
            // PERF: slow
            let newData = data.first { $0.metadata.id == dataID }!
            
            if !processed.contains(dataID)
            {
                var commitData: DataModel
                
                updateData: do
                {
                    if let previousData = self.data[newData.metadata.id]
                    {
                        commitData = newData
                        commitData.merge(with: previousData)
                        
                        let index = self.dataSortedByDate.firstIndex(of: previousData)!
                        self.dataSortedByDate.remove(at: index)
                    }
                    else
                    {
                        commitData = newData
                    }
                }
                
                updateStores: do
                {
                    self.data[commitData.metadata.id] = commitData
                    
                    if let index = self.dataSortedByDate.lastIndex(where: { commitData.checkIn.time.v >= $0.checkIn.time.v })
                    {
                        self.dataSortedByDate.insert(commitData, at: index + 1)
                    }
                    else
                    {
                        self.dataSortedByDate.insert(commitData, at: 0)
                    }
                }
                
                updateLamport: do
                {
                    self.lamport = max(self.lamport, commitData.lamport)
                }
                
                processed.insert(dataID)
            }
            
            updateOperations: do
            {
                if self.operations[site] != nil
                {
                    self.operations[site]!.append(dataID)
                }
                else
                {
                    self.operations[site] = [dataID]
                }
            }
            
            assert(self.dataSortedByDate.count == self.data.count)
            
            return nil
        }
        
        let group = DispatchGroup()
        var error: Error? = nil
        
        for (site, pair) in operationLog
        {
            for (i, op) in pair.operations.enumerated()
            {
                let idx = Int(pair.startingIndex) + i
                
                // operation exists, check if it's the same
                if idx < self.operations[site]?.count ?? 0
                {
                    let previousOperation = self.operations[site]![idx]
                    
                    if previousOperation != op
                    {
                        error = DataError.mismatchedOperation
                    }
                    else
                    {
                        print("warning: operation \(op) already exists, skipping")
                    }
                }
                // operation does not exist
                else
                {
                    group.enter()
                
                    nextOperationIndex(forSite: site)
                    { index in
                        switch index
                        {
                        case .error(let e):
                            error = e
                            group.leave()
                        case .value(let v):
                            if idx != v
                            {
                                error = DataError.missingPreceedingOperations
                                group.leave()
                            }
                            else
                            {
                                error = stepTwo(dataID: op, site: site, index: v)
                                group.leave()
                            }
                        }
                    }
                    
                    group.wait()
                }
                
                if error != nil  { break }
            }
            
            if let e = error
            {
                block(e)
                break
            }
        }
        
        block(nil)
    }
}

extension Data_Memory: DataDebugProtocol
{
    public func _asserts()
    {
        assert(self.data.count == self.dataSortedByDate.count)
        
        checkUnique: do
        {
            var set = Set(self.data.keys)
            
            for v in self.dataSortedByDate
            {
                set.remove(v.metadata.id)
            }
            
            assert(set.count == 0)
        }
        
        checkLamport: do
        {
            var lamport: DataLayer.Time = 0
            
            for (_, v) in self.data
            {
                lamport = max(lamport, v.lamport)
            }
            
            assert(lamport == self.lamport)
        }
        
        checkSortOrder: do
        {
            for i in 0..<self.dataSortedByDate.count - 1
            {
                assert(self.dataSortedByDate[i].checkIn.time.v <= self.dataSortedByDate[i + 1].checkIn.time.v, "incorrect sort order")
            }
        }
    }
}
