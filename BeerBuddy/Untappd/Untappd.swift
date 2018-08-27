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
    private static let dateFormat = "E, d MMM yyyy HH:mm:ss Z"
    private static let untappdOwner: DataLayer.SiteID = UUID.init(uuidString: "a7419258-9b21-4eca-a719-5ce2963f42e0")!
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
        
        clearCaches()
        Defaults.untappdToken = token
        
        // populates the caches
        userCheckIns(withBaseline: false, limit: 1)
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
    
    // QQQ:
    public func refreshCheckIns(withData data: DataLayer) -> UntappdError?
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
        userCheckIns
        {
            switch $0
            {
            case .error(let e):
                appError("Untappd refresh error -- \(e.localizedDescription)")
            case .value(let checkIns):
                for checkin in checkIns
                {
                    let time: Date
                    if let stringTime = checkin.created_at
                    {
                        let formatter = DateFormatter()
                        formatter.dateFormat = Untappd.dateFormat
                        if let date = formatter.date(from: stringTime)
                        {
                            time = date
                        }
                        else
                        {
                            appWarning("could not parse date from \(stringTime)")
                            time = Date()
                        }
                    }
                    else
                    {
                        time = Date()
                    }
                    let untappdId = checkin.checkin_id
                    let id = GlobalID.init(siteID: Untappd.untappdOwner, operationIndex: DataLayer.Index(untappdId))
                    let style: DrinkStyle
                    if let stringStyle = checkin.beer.beer_style
                    {
                        if stringStyle.hasPrefix("Mead")
                        {
                            style = .mead
                        }
                        else if stringStyle.hasPrefix("Cider")
                        {
                            style = .cider
                        }
                        else
                        {
                            style = .beer
                        }
                    }
                    else
                    {
                        style = .beer
                    }
                    let abv = checkin.beer.beer_abv != nil ? checkin.beer.beer_abv! / 100 : style.defaultABV
                    
                    let drink = Model.Drink.init(name: checkin.beer.beer_name, style: style, abv: abv, price: nil, volume: style.defaultVolume)
                    let checkIn = Model.CheckIn.init(untappdId: Model.ID(untappdId), untappdApproved: false, time: time, drink: drink)
                    let meta = Model.Metadata.init(id: id, creationTime: time) //TODO: this should be the current time, but w/o overwriting existing data
                    let model = Model.init(metadata: meta, checkIn: checkIn)
                    
                    // AB: we "sync" here because of our fake Untappd UUID scheme
                    data.save(model: model, syncing: true)
                    {
                        switch $0
                        {
                        case .error(let e):
                            appError("Untappd commit error -- \(e.localizedDescription)")
                        case .value(_):
                            appDebug("saved \(untappdId)!")
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    func userCheckIns(withBaseline: Bool = true, limit: Int = 50, block: @escaping (MaybeError<[CheckIn]>)->())
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
        
        let token = Defaults.untappdToken!
        
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
                block(.error(e: error))
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
                    if withBaseline, let baseline = Defaults.untappdBaseline
                    {
                        checkIns = checkIns.filter { $0.checkin_id > baseline }
                    }
                    
                    self?.updateDisplayName(newData)
                    self?.updateBaseline(newData)
                    
                    block(.value(v: checkIns))
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
                        block(.error(e: error))
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
    
    func updateBaseline(_ response: Response<CheckInsResponse>)
    {
        let highestCheckIn = (response.response?.checkins?.items ?? []).max { $0.checkin_id < $1.checkin_id }
        if let highestBaseline = highestCheckIn?.checkin_id
        {
            appDebug("set baseline to \(highestBaseline)")
            Defaults.untappdBaseline = highestBaseline
        }
    }
    
    func clearCaches()
    {
        Defaults.untappdToken = nil
        Defaults.untappdBaseline = nil
        Defaults.untappdDisplayName = nil
        Defaults.untappdRateLimit = nil
        Defaults.untappdRateLimitRemaining = nil
    }
}
