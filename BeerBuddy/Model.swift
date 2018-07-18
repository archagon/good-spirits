//
//  Model.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-17.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

public struct Model
{
    public typealias ID = UInt64
    
    public struct CheckIn
    {
        public let id: ID
        public let untappdId: ID?
        public let time: Date
        public let drink: Drink
    }
    
    public struct Drink
    {
        public enum Style
        {
            case beer
            case wine
            case sake
            
            // TODO: move to data file?
            public var defaultABV: Double
            {
                get
                {
                    switch self
                    {
                    case .beer: return 0.065
                    case .wine: return 0.14
                    case .sake: return 0.17
                    }
                }
            }
        }
        
        public let name: String?
        public let style: Style
        public let abv: Double
        public let price: Double?
        public let volume: Volume
    }
    
    public enum Volume
    {
        case fluidOunces(v: Double)
        case mililiters(v: Double)
    }
}
