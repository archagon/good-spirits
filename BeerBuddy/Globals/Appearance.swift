//
//  Appearance.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-21.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation

class Appearance
{
    static var themeColor: UIColor = UIColor.init(red: 107/255.0, green: 158/255.0, blue: 255/255.0, alpha: 1)
    static var darkenedThemeColor = themeColor.mixed(with: .black, by: 0.15)
    
    public static let shared = Appearance()
    
    private struct DrinkIconCacheKey: Hashable
    {
        let name: String
        let sansCircle: Bool
        let inverted: Bool
    }
    private var _drinkIconCache: [DrinkIconCacheKey:UIImage] = [:]
    
    public func drinkIcon(forImageName imageName: String, sansCircle: Bool = false, highlighted: Bool = false) -> UIImage
    {
        if let image = _drinkIconCache[DrinkIconCacheKey.init(name: imageName, sansCircle: sansCircle, inverted: highlighted)]
        {
            return image
        }
        else
        {
            let size: CGFloat = 100
            let circleWidth: CGFloat = 0 //was 2 for stroke
            
            guard let originalImage = UIImage.init(named: imageName) else
            {
                appError("image \(imageName) not found")
                return UIImage()
            }
            
            UIGraphicsBeginImageContextWithOptions(CGSize.init(width: size, height: size), false, 0)
            defer { UIGraphicsEndImageContext() }
            
            guard let ctx = UIGraphicsGetCurrentContext() else
            {
                appError("image context could not be created")
                return UIImage()
            }
            
            ctx.saveGState()
            drawCircle: do
            {
                // QQQ:
                if sansCircle
                {
                    let circleWidth: CGFloat = 4
                    
                    UIColor.black.setStroke()
                    let circle = UIBezierPath.init(ovalIn: CGRect.init(x: circleWidth/2, y: circleWidth/2, width: size-circleWidth, height: size-circleWidth))
                    circle.lineWidth = circleWidth
                    circle.stroke()
                    
                    break drawCircle
                }
                
                UIColor.black.setStroke()
                let circle = UIBezierPath.init(ovalIn: CGRect.init(x: circleWidth/2, y: circleWidth/2, width: size-circleWidth, height: size-circleWidth))
                circle.lineWidth = circleWidth
                //circle.stroke()
                circle.fill()
            }
            ctx.restoreGState()
            
            ctx.saveGState()
            drawImage: do
            {
                let scale: CGFloat = 1
                originalImage.draw(in: CGRect.init(x: size/2-originalImage.size.width*scale/2, y: size/2-originalImage.size.height*scale/2, width: originalImage.size.width*scale, height: originalImage.size.height*scale), blendMode: (sansCircle ? CGBlendMode.normal : CGBlendMode.xor), alpha: 1)
                    //originalImage.draw(at: CGPoint.init(x: size/2-originalImage.size.width/2, y: size/2-originalImage.size.height/2), blendMode: (sansCircle ? CGBlendMode.normal : CGBlendMode.xor), alpha: 1)
            }
            ctx.restoreGState()
            
            let img = UIGraphicsGetImageFromCurrentImageContext()
            
            guard var retImg = img else
            {
                appError("image could not be rendered")
                return UIImage()
            }
            
            retImg = retImg.withRenderingMode(.alwaysTemplate)
            
            _drinkIconCache[DrinkIconCacheKey.init(name: imageName, sansCircle: sansCircle, inverted: highlighted)] = retImg
            return retImg
        }
    }
}
