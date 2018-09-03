//
//  Untappd_Schema.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-24.
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
        //public let developer_friendly: Bool?
        
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
        public let user: User
        public let beer: Beer
        public let venue: Venue?
    }
    
    public struct User: Decodable
    {
        public let uid: Int
        public let user_name: String
        public let first_name: String?
        public let last_name: String?
    }
    
    public struct Beer: Decodable
    {
        public let bid: Int
        public let beer_name: String?
        public let beer_style: String?
        public let beer_abv: Double?
    }
    
    public struct Venue: Decodable
    {
        public let venue_id: Int
        public let venue_name: String?
    }
}

// BUGFIX: Necessary due to "bug" in Untappd API: an empty venue is an empty array instad of nothing.
extension Untappd.CheckIn: Decodable
{
    enum CodingKeys: CodingKey
    {
        case checkin_id
        case created_at
        case checkin_comment
        case user
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
        self.user = try container.decode(Untappd.User.self, forKey: .user)
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
