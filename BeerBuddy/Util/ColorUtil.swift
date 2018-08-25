//
//  ColorUtil.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-28.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit

extension UIColor
{
    public var r: CGFloat
    {
        var r: CGFloat = 0
        self.getRed(&r, green: nil, blue: nil, alpha: nil)
        return r
    }
    
    public var g: CGFloat
    {
        var g: CGFloat = 0
        self.getRed(nil, green: &g, blue: nil, alpha: nil)
        return g
    }
    
    public var b: CGFloat
    {
        var b: CGFloat = 0
        self.getRed(nil, green: nil, blue: &b, alpha: nil)
        return b
    }
    
    public var a: CGFloat
    {
        var a: CGFloat = 0
        self.getRed(nil, green: nil, blue: nil, alpha: &a)
        return a
    }
    
    public var h: CGFloat
    {
        var h: CGFloat = 0
        self.getHue(&h, saturation: nil, brightness: nil, alpha: nil)
        return h
    }
    
    public var s: CGFloat
    {
        var s: CGFloat = 0
        self.getHue(nil, saturation: &s, brightness: nil, alpha: nil)
        return s
    }
    
    public var l: CGFloat
    {
        var l: CGFloat = 0
        self.getHue(nil, saturation: nil, brightness: &l, alpha: nil)
        return l
    }
    
    public func darkened(by: CGFloat) -> UIColor
    {
        return mixed(with: .black, by: by)
    }
    
    public func mixed(with: UIColor, by: CGFloat) -> UIColor
    {
        let nby = min(max(by, 0), 1)
        
        let l = 1 - nby
        let r = nby
        
        return UIColor.init(red: l * self.r + r * with.r, green: l * self.g + r * with.g, blue: l * self.b + r * with.b, alpha: l * self.a + r * with.a)
    }
}
