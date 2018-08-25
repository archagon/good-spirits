//
//  Untappd.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-23.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import SystemConfiguration

class Untappd
{
    public static let clientID: String = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    public static let redirectURL: URL = URL.init(string: "http://archagon.net")!
    public static let redirectHost: String = Untappd.redirectURL.host!
    public static let apiURL: URL = URL.init(string: "https://api.untappd.com")!
    //https://api.untappd.com/v4/method_name?access_token=ACESSTOKENHERE
    
    public static let shared = Untappd()
    
    public enum UntappdError: Error
    {
        case notReachable
        case notEnabled
        case notReady
    }
    
    private var loginPending: Bool = false
    public enum UntappdLoginStatus
    {
        case unreachable
        case disabled
        case pendingAuthorization
        case enabledAndAuthorized
    }
    
    var loginStatus: UntappdLoginStatus
    {
        if self.loginPending
        {
            return .pendingAuthorization
        }
        
        let reachability = SCNetworkReachabilityCreateWithName(nil, Untappd.apiURL.absoluteString)
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability!, &flags)
        let isReachable = flags.contains(.reachable)
        //let needsConnection = flags.contains(.connectionRequired)
        //let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        //let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        
        if !isReachable
        {
            return .unreachable
        }
        
        if Defaults.untappdEnabled && Defaults.untappdToken != nil
        {
            return .enabledAndAuthorized
        }
        else
        {
            return .disabled
        }
    }
    
    public func UserCheckIns(_ token: String, withBaseline baseline: String? = nil, block: ([CheckIn], UntappdError?)->()) -> UntappdError?
    {
        switch self.loginStatus
        {
        case .unreachable:
            return UntappdError.notReachable
        case .disabled:
            return UntappdError.notEnabled
        case .pendingAuthorization:
            return UntappdError.notReady
        case .enabledAndAuthorized:
            break
        }
        
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
        
        return nil
    }
}
