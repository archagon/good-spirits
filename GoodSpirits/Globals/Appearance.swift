//
//  Appearance.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-21.
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

class Appearance
{
    static var themeColor: UIColor = UIColor.init(red: 107/255.0, green: 158/255.0, blue: 255/255.0, alpha: 1)
    static var darkenedThemeColor = themeColor.mixed(with: .black, by: 0.15)
    
    static var greenProgressColor = UIColor.init(hex: "1CE577").mixed(with: .black, by: 0.15)
    static var blueProgressColor = Appearance.darkenedThemeColor
    static var orangeProgressColor = UIColor.orange.mixed(with: .white, by: 0.1)
    static var redProgressColor = UIColor.red.mixed(with: .white, by: 0.3)
    
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
