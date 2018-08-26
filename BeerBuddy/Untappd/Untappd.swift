//
//  Untappd.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-23.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import SystemConfiguration
import DataLayer

class Untappd
{
    public static let themeColor: UIColor = UIColor.init(red: 254/255.0, green: 205/255.0, blue: 50/255.0, alpha: 1)
    
    public static let requestURL = "https://untappd.com/oauth/authenticate/?client_id=\(clientID)&response_type=token&redirect_url=\(redirectURL)"
    public static let redirectHost: String = Untappd.redirectURL.host!
    
    private static let clientID: String = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    private static let redirectURL: URL = URL.init(string: "http://archagon.net")!
    private static let apiURL: URL = URL.init(string: "https://api.untappd.com")!
    private static let rateLimitHeader = "X-Ratelimit-Limit"
    private static let rateLimitRemainingHeader = "X-Ratelimit-Remaining"
    //https://api.untappd.com/v4/method_name?access_token=ACESSTOKENHERE
    
    public static let shared = Untappd()
    
    public enum UntappdError: Error, LocalizedError
    {
        case notReachable
        case notEnabled
        case notReady
        case webError(type: String?, message: String?)
        
        public var errorDescription: String?
        {
            switch self
            {
            case .notReachable:
                return "not reachable"
            case .notEnabled:
                return "not enabled"
            case .notReady:
                return "not ready"
            case .webError(let type, let message):
                return "web error\(type != nil ? " \(type!)" : "")\(message != nil ? ": \(message!)" : "")"
            }
        }
    }
    
    public enum UntappdLoginStatus
    {
        case unreachable
        case disabled
        case enabledAndAuthorized
    }
    
    var loginStatus: UntappdLoginStatus
    {
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
    
    // QQQ:
    public func refreshCheckIns(withData: DataLayer) -> UntappdError?
    {
        switch self.loginStatus
        {
        case .unreachable:
            return UntappdError.notReachable
        case .disabled:
            return UntappdError.notEnabled
        case .enabledAndAuthorized:
            break
        }
        
        // QQQ:
        userCheckIns(Defaults.untappdToken ?? "", withBaseline: nil)
        { (checkIns, error) in
            if let error = error
            {
                appError("Untappd refresh error -- \(error.localizedDescription)")
            }
            else
            {
                let checkins = checkIns
                var asdf = 123
                asdf = 2345
            }
        }
        
        return nil
    }
    
    func userCheckIns(_ token: String, withBaseline baseline: Int? = nil, block: @escaping ([CheckIn], Error?)->()) -> UntappdError?
    {
        switch self.loginStatus
        {
        case .unreachable:
            return UntappdError.notReachable
        case .disabled:
            return UntappdError.notEnabled
        case .enabledAndAuthorized:
            break
        }
        
        //let minId = (baseline != nil ? "&min_id=\(baseline!)" : "")
        let minId = "" //AB: min_id has age requirements that make it unsuitable for our use case
        let newUrlString = (Untappd.apiURL.absoluteString as NSString).appendingPathComponent("/v4/user/checkins?access_token=\(token)\(minId)&limit=100")
        let url = URL.init(string: newUrlString)!
        var request = URLRequest.init(url: url)
        request.httpMethod = "GET"
        
        appDebug("request to \(url)...")
        
        let task = URLSession.shared.dataTask(with: request)
        { (data, response, error) in
            if
                let response = response as? HTTPURLResponse,
                let rateLimit = response.allHeaderFields[Untappd.rateLimitHeader],
                let rateLimitRemaining = response.allHeaderFields[Untappd.rateLimitRemainingHeader]
            {
                appDebug("rate limit \(rateLimit)")
                appDebug("rate limit remaining \(rateLimitRemaining)")
            }
            
            if let error = error
            {
                block([], error)
                return
            }
            
            if let data = data
            {
                let parser = JSONDecoder.init()
                do
                {
                    let newData = try parser.decode(Response<CheckInsResponse>.self, from: data)
                    let code = newData.meta.code
                    appDebug("untappd code \(code)")
                    let checkIns = newData.response?.checkins?.items ?? []
                    
                    block(checkIns, nil)
                }
                catch
                {
                    do
                    {
                        let errorData = try parser.decode(Response<NullStruct>.self, from: data)
                        throw UntappdError.webError(type: errorData.meta.error_type, message: errorData.meta.error_detail)
                    }
                    catch
                    {
                        block([], error)
                    }
                }
            }
        }
        task.resume()
        
        return nil
    }
}
