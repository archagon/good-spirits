//
//  Untappd.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-23.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

class Untappd
{
    public static let clientID: String = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    public static let redirectURL: URL = URL.init(string: "http://archagon.net")!
    public static let redirectHost: String = Untappd.redirectURL.host!
    public static let apiURL: URL = URL.init(string: "https://api.untappd.com")!
    
//    https://api.untappd.com/v4/method_name?access_token=ACESSTOKENHERE
    
    public static func UserCheckIns(_ token: String, block: ([CheckIn], Error?)->())
    {
        let newUrlString = (Untappd.apiURL.absoluteString as NSString).appendingPathComponent("/v4/user/checkins?access_token=\(token)")
        let url = URL.init(string: newUrlString)!
        var request = URLRequest.init(url: url)
        request.httpMethod = "GET"
        
        appDebug("Request to \(url)...")
        
        let task = URLSession.shared.dataTask(with: request)
        { (data, response, error) in
            if let error = error
            {
                return
            }
            
            if let data = data
            {
                let parser = JSONDecoder.init()
                do
                {
                    let newData = try parser.decode(Response<CheckInsResponse>.self, from: data)
                    print(newData)
//                    print("count: \(newData.checkins.count)")
//                    print("first: \(newData.checkins.items.first!)")
                    
                    // code 500 == error
                }
                catch
                {
                    print("error: \(error)")
                }
                dump(data)
            }
        }
        task.resume()
    }
}
