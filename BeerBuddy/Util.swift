//
//  Util.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-18.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public func equalish<T: Dimension>(first: Measurement<T>, second: Measurement<T>, delta: Measurement<T>) -> Bool
{
    let baseFirst = first.converted(to: T.baseUnit())
    let baseSecond = second.converted(to: T.baseUnit())
    var baseDelta = delta.converted(to: T.baseUnit())
    
    if baseDelta.value < 0
    {
        baseDelta = baseDelta * -1
    }
    
    var diff = baseFirst - baseSecond

    if diff.value < 0
    {
        diff = diff * -1
    }
    
    return diff <= baseDelta
}
