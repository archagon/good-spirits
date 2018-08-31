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
    public static let dateFormat = "E, d MMM yyyy HH:mm:ss Z"
    public static let untappdOwner: DataLayer.SiteID = UUID.init(uuidString: "a7419258-9b21-4eca-a719-5ce2963f42e0")!
    //https://api.untappd.com/v4/method_name?access_token=ACESSTOKENHERE
    
    public static let shared = Untappd()
    
    public enum UntappdError: Error, LocalizedError
    {
        case notReachable
        case notEnabled
        case webError(type: String?, message: String?)
        case rateLimitExceeded
        case unknown
        
        public var errorDescription: String?
        {
            switch self
            {
            case .notReachable:
                return "no connection to Untappd servers"
            case .notEnabled:
                return "not enabled"
            case .webError(let type, let message):
                return "web error\(type != nil ? " \(type!)" : "")\(message != nil ? ": \(message!)" : "")"
            case .unknown:
                return "unknown"
            case .rateLimitExceeded:
                return "too many requests made in an hour, please try again a bit later"
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
        
        if Defaults.untappdToken != nil
        {
            return .enabledAndAuthorized
        }
        else
        {
            return .disabled
        }
    }
    
    // The display name can be retrieved later from Defaults, and will be updated as new check-ins come in.
    public func authenticate(withToken token: String, block: @escaping (MaybeError<String?>)->())
    {
        switch self.loginStatus
        {
        case .unreachable:
            block(.error(e: UntappdError.notReachable))
            return
        case .disabled:
            break
        case .enabledAndAuthorized:
            block(.value(v: Defaults.untappdDisplayName))
            return
        }
        
        // TODO: this might not belong here, given that it's also done in settings VC
        clearCaches()
        Defaults.untappdToken = token
        
        // populates the caches
        userCheckIns(withBaseline: nil, limit: 1)
        {
            switch $0
            {
            case .error(let e):
                block(.error(e: e))
            case .value(_):
                block(.value(v: Defaults.untappdDisplayName))
            }
        }
    }
    
    func userCheckIns(withBaseline: Int? = nil, limit: Int = 50, block: @escaping (MaybeError<[CheckIn]>)->())
    {
        switch self.loginStatus
        {
        case .unreachable:
            block(.error(e: UntappdError.notReachable))
            return
        case .disabled:
            block(.error(e: UntappdError.notEnabled))
            return
        case .enabledAndAuthorized:
            break
        }
        
        guard let token = Defaults.untappdToken else
        {
            block(.error(e: UntappdError.unknown))
            return
        }
        
        //let minId = (baseline != nil ? "&min_id=\(baseline!)" : "")
        let minId = "" //AB: min_id has age requirements that make it unsuitable for our use case
        let newUrlString = (Untappd.apiURL.absoluteString as NSString).appendingPathComponent("/v4/user/checkins?access_token=\(token)\(minId)&limit=\(limit)")
        let url = URL.init(string: newUrlString)!
        var request = URLRequest.init(url: url)
        request.httpMethod = "GET"
        
        appDebug("request to \(url)...")
        
        let task = URLSession.shared.dataTask(with: request)
        { [weak `self`] (data, response, error) in
            self?.updateRateLimits(response)
            
            if let error = error
            {
                onMain
                {
                    block(.error(e: error))
                }
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
                    
                    // PERF: these probably arrive in order, so we can binary search
                    var checkIns = newData.response?.checkins?.items ?? []
                    if let baseline = withBaseline
                    {
                        checkIns = checkIns.filter { $0.checkin_id > baseline }
                    }
                    
                    self?.updateDisplayName(newData)
                    
                    onMain
                    {
                        block(.value(v: checkIns))
                    }
                }
                catch
                {
                    do
                    {
                        let errorData = try parser.decode(Response<NullStruct>.self, from: data)
                        
                        if errorData.meta.error_type == "invalid_limit"
                        {
                            throw UntappdError.rateLimitExceeded
                        }
                        else
                        {
                            throw UntappdError.webError(type: errorData.meta.error_type, message: errorData.meta.error_detail)
                        }
                    }
                    catch
                    {
                        onMain
                        {
                            block(.error(e: error))
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    func updateRateLimits(_ response: URLResponse?)
    {
        if
            let response = response as? HTTPURLResponse,
            let rateLimitString = response.allHeaderFields[Untappd.rateLimitHeader] as? String,
            let rateLimitRemainingString = response.allHeaderFields[Untappd.rateLimitRemainingHeader] as? String,
            let rateLimit = Int(rateLimitString),
            let rateLimitRemaining = Int(rateLimitRemainingString)
        {
            Defaults.untappdRateLimit = rateLimit
            Defaults.untappdRateLimitRemaining = rateLimitRemaining
            appDebug("rate limit \(rateLimit)")
            appDebug("rate limit remaining \(rateLimitRemaining)")
        }
    }
    
    func updateDisplayName(_ response: Response<CheckInsResponse>)
    {
        if let checkIn = response.response?.checkins?.items.first
        {
            if let firstName = checkIn.user.first_name
            {
                let lastName = (checkIn.user.last_name != nil ? " \(checkIn.user.last_name!)" : "")
                Defaults.untappdDisplayName = "\(firstName)\(lastName) (\(checkIn.user.user_name))"
            }
            else
            {
                Defaults.untappdDisplayName = "\(checkIn.user.user_name)"
            }
            appDebug("set display name to \(Defaults.untappdDisplayName!)")
        }
    }
    
    // AKA "deauth".
    func clearCaches()
    {
        appDebug("clearing Untappd caches")
        
        // TODO: should be part of Defaults
        if Defaults.untappdToken != nil { Defaults.untappdToken = nil }
        if Defaults.untappdDisplayName != nil { Defaults.untappdDisplayName = nil }
        if Defaults.untappdRateLimit != nil { Defaults.untappdRateLimit = nil }
        if Defaults.untappdRateLimitRemaining != nil { Defaults.untappdRateLimitRemaining = nil }
    }
}
