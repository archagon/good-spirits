//
//  Untappd_Schema.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-24.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

extension Untappd
{
    struct Response<T: Decodable>: Decodable
    {
        public let meta: Meta
        //public let notifications: Notifications?
        public let response: T?
    }
    
    struct NullStruct: Decodable {}
    
    struct Meta: Decodable
    {
        public struct ResponseTime: Decodable
        {
            public let time: Double
            public let measure: String
        }
        
        public let code: Int
        
        public let error_detail: String?
        public let error_type: String?
        public let developer_friendly: String?
        
        public let response_time: ResponseTime?
    }
    
    struct CheckInsResponse: Decodable
    {
        public struct CheckIns: Decodable
        {
            public let items: [CheckIn]
        }
        
        public let checkins: CheckIns?
    }
    
    public struct CheckIn
    {
        public let checkin_id: Int
        public let created_at: String?
        public let checkin_comment: String?
        public let rating_score: Double?
        //public let user: User
        public let beer: Beer
        public let venue: Venue?
    }
    
    public struct Beer: Decodable
    {
        public let bid: Int
        public let beer_name: String?
        public let beer_abv: Double?
    }
    
    public struct Venue: Decodable
    {
        public let venue_id: Int
        public let venue_name: String?
    }
}

// AB: necessary due to "bug" in Untappd API: an empty venue is an empty array instad of nothing
extension Untappd.CheckIn: Decodable
{
    enum CodingKeys: CodingKey
    {
        case checkin_id
        case created_at
        case checkin_comment
        case rating_score
        case beer
        case venue
    }
    
    init(from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.checkin_id = try container.decode(Int.self, forKey: .checkin_id)
        self.created_at = try container.decode(String?.self, forKey: .created_at)
        self.checkin_comment = try container.decode(String?.self, forKey: .checkin_comment)
        self.rating_score = try container.decode(Double?.self, forKey: .rating_score)
        self.beer = try container.decode(Untappd.Beer.self, forKey: .beer)
        
        do
        {
            let _ = try container.decode(Array<Untappd.Venue>.self, forKey: .venue)
            self.venue = nil
        }
        catch
        {
            self.venue = try container.decode(Untappd.Venue?.self, forKey: .venue)
        }
    }
}
