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
        if by == 0
        {
            return self
        }
        
        let nby = min(max(by, 0), 1)
        
        let l = 1 - nby
        let r = nby
        
        return UIColor.init(red: l * self.r + r * with.r, green: l * self.g + r * with.g, blue: l * self.b + r * with.b, alpha: l * self.a + r * with.a)
    }
    
    // https://stackoverflow.com/a/33675160/89812
    public var pixel: UIImage
    {
        let rect = CGRect(origin: .zero, size: CGSize.init(width: 1, height: 1))
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        
        self.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image ?? UIImage()
    }
    
    public func resizableImage(withCornerRadius r: CGFloat) -> UIImage
    {
        let rect = CGRect(origin: .zero, size: CGSize.init(width: 1 + 2 * r, height: 1 + 2 * r))
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        
        self.setFill()
        let shape = UIBezierPath.init(roundedRect: rect, byRoundingCorners: .allCorners, cornerRadii: CGSize.init(width: r, height: r))
        shape.fill()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image?.resizableImage(withCapInsets: UIEdgeInsets.init(top: r, left: r, bottom: r, right: r)) ?? UIImage()
    }
}

// https://crunchybagel.com/working-with-hex-colors-in-swift-3/
extension UIColor
{
    convenience init(hex: String)
    {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}
