//
//  UntappdLoginViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-23.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit
import WebKit

public class UntappdLoginViewController: UIViewController
{
    private let webView: WKWebView
    private let loadingView: UIStackView
    private var tokenBlock: ((String, Error?)->())! = nil
    
    public init()
    {
        self.webView = WKWebView.init()
        
        let spinner = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        spinner.startAnimating()
        let image = UIImageView.init(image: #imageLiteral(resourceName: "untappd_logo"))
        let stack = UIStackView.init(arrangedSubviews: [image, spinner])
        stack.spacing = 16
        image.setContentCompressionResistancePriority(.required, for: .horizontal)
        image.setContentCompressionResistancePriority(.required, for: .vertical)
        stack.axis = .vertical
        self.loadingView = stack
        
        super.init(nibName: nil, bundle: nil)
        
        self.webView.navigationDelegate = self
        
        self.webView.allowsLinkPreview = false
        
//        self.webView.scrollView.backgroundColor = UIColor.init(red: 255/255.0, green: 204/255.0, blue: 1/255.0, alpha: 1)
//        self.webView.backgroundColor = UIColor.init(red: 255/255.0, green: 204/255.0, blue: 1/255.0, alpha: 1)
        self.webView.isOpaque = false
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad()
    {
        self.view.backgroundColor = UIColor.init(red: 255/255.0, green: 204/255.0, blue: 1/255.0, alpha: 1)
        
        self.view.addSubview(self.webView)
        self.webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.webView.frame = self.view.bounds
        
        self.loadingView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.loadingView)
        self.loadingView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        self.loadingView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
    }
    
    public func load(withBlock block: @escaping (String, Error?)->())
    {
        let url = "https://untappd.com/oauth/authenticate/?client_id=\(Untappd.clientID)&response_type=token&redirect_url=\(Untappd.redirectURL)"
        let request = URLRequest.init(url: URL.init(string: url)!)
        self.tokenBlock = block
        self.webView.load(request)
    }
}

// TODO: timeouts, etc.
extension UntappdLoginViewController: WKNavigationDelegate
{
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error)
    {
        fatalError("failed")
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void)
    {
        if
            let url = navigationAction.request.url,
            let host = url.host,
            host == Untappd.redirectHost,
            let fragment = url.fragment
        {
            let split = fragment.split(separator: "=")
            
            if split.count == 2 && split[0] == "access_token"
            {
                self.tokenBlock(String(split[1]), nil)
                decisionHandler(.cancel)
            }
            else
            {
                appError("incorrect untappd response: \(url)")
                decisionHandler(.allow)
            }
        }
        else
        {
            decisionHandler(.allow)
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
    {
        webView.isOpaque = true
        self.loadingView.isHidden = true
    }
}
