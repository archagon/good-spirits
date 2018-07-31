//
//  ABPrettyButton.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-28.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit

public protocol SpyingButtonDelegate: class
{
    func didHighlight(_ button: UIButton)
    func didSelect(_ button: UIButton)
    func didEnable(_ button: UIButton)
}

public class SpyingButton: UIButton
{
    public weak var delegate: SpyingButtonDelegate?
    
    public override var isHighlighted: Bool
    {
        didSet
        {
            self.delegate?.didHighlight(self)
        }
    }
    
    public override var isSelected: Bool
    {
        didSet
        {
            self.delegate?.didSelect(self)
        }
    }
    
    public override var isEnabled: Bool
    {
        didSet
        {
            self.delegate?.didEnable(self)
        }
    }
}

public class ABPrettyButton: UIControl
{
    private let button: SpyingButton
    private let visualEffectView: UIVisualEffectView
    private let shadowView: ABShadowView
    
    private var buttonBaseBackgroundColor: UIColor? = nil
    
    public required init(type buttonType: UIButtonType)
    {
        let button = SpyingButton.init(type: buttonType)
        
        let effect1 = UIVisualEffectView.init(effect: UIBlurEffect.init(style: .dark))
        let effect2 = UIVisualEffectView.init(effect: UIVibrancyEffect.init(blurEffect: .init(style: .dark)))
        effect1.contentView.addSubview(effect2)
        effect2.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effect2.frame = effect1.bounds
        
        self.button = button
        self.visualEffectView = effect1
        self.shadowView = ABShadowView.init(frame: button.frame)
        
        super.init(frame: button.frame)
        
        setupViews()
    }
    
    public override init(frame: CGRect)
    {
        let effect1 = UIVisualEffectView.init(effect: UIBlurEffect.init(style: .dark))
        let effect2 = UIVisualEffectView.init(effect: UIVibrancyEffect.init(blurEffect: .init(style: .dark)))
        effect1.contentView.addSubview(effect2)
        effect2.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effect2.frame = effect1.bounds
        
        self.button = SpyingButton.init(frame: frame)
        self.visualEffectView = effect1
        self.shadowView = ABShadowView.init(frame: frame)
        
        super.init(frame: frame)
        
        setupViews()
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        let button = SpyingButton.init(type: .custom)
        
        let effect1 = UIVisualEffectView.init(effect: UIBlurEffect.init(style: .dark))
        let effect2 = UIVisualEffectView.init(effect: UIVibrancyEffect.init(blurEffect: .init(style: .dark)))
        effect1.contentView.addSubview(effect2)
        effect2.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        effect2.frame = effect1.bounds
        
        self.button = button
        self.visualEffectView = effect1
        self.shadowView = ABShadowView.init(frame: button.frame)
        
        super.init(coder: aDecoder)
        
        setupViews()
    }
    
    private func setupViews()
    {
        self.button.delegate = self
        
        self.shadowView.translatesAutoresizingMaskIntoConstraints = false
        self.visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        self.button.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(self.shadowView)
        self.visualEffectView.contentView.addSubview(self.button)
        self.addSubview(self.visualEffectView)
        
        let shadowOverscan: CGFloat = 20
        let views: [String:Any] = ["button":self.button, "effect":self.visualEffectView, "shadow":self.shadowView]
        let metrics: [String:Any] = ["buttonMargin":4]
        
        let buttonHConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(buttonMargin)-[button]-(buttonMargin)-|", options: [], metrics: metrics, views: views)
        let buttonVConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(buttonMargin)-[button]-(buttonMargin)-|", options: [], metrics: metrics, views: views)
     
        let effectHConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[effect]|", options: [], metrics: metrics, views: views)
        let effectVConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[effect]|", options: [], metrics: metrics, views: views)
        
        let shadowWidth = self.shadowView.widthAnchor.constraint(equalTo: self.visualEffectView.widthAnchor, constant: shadowOverscan)
        let shadowHeight = self.shadowView.heightAnchor.constraint(equalTo: self.visualEffectView.heightAnchor, constant: shadowOverscan)
        let shadowCenterX = self.shadowView.centerXAnchor.constraint(equalTo: self.visualEffectView.centerXAnchor, constant: 0)
        let shadowCenterY = self.shadowView.centerYAnchor.constraint(equalTo: self.visualEffectView.centerYAnchor, constant: 0)
        
        NSLayoutConstraint.activate(
            buttonHConstraints +
            buttonVConstraints +
            effectHConstraints +
            effectVConstraints +
            [shadowWidth, shadowHeight, shadowCenterX, shadowCenterY]
        )
        
        self.shadowView.targetView = self.visualEffectView
        
        appearance: do
        {
            self.backgroundColor = nil
            
            // QQQ:
            self.visualEffectView.layer.cornerRadius = 8
            self.visualEffectView.clipsToBounds = true
            self.shadowView.shadowColor = UIColor.black
            self.shadowView.shadowOpacity = 0.35
            self.shadowView.shadowRadius = 2
            self.shadowView.shadowCornerRadius = 8
            self.shadowView.shadowOffset = .init(width: 0, height: 2)
            
            setTitle("Testing", for: .normal)
            
            setTitleColor(.white, for: .normal)
            setTitleColor(.red, for: [.highlighted, .selected, .disabled])
            
            setBackgroundColor(.init(red: 121.0/255.0, green: 147.0/255.0, blue: 246.0/255.0, alpha: 1), forState: .normal)
        }
    }
    
    public override func layoutSubviews()
    {
        super.layoutSubviews()
        
        self.shadowView.refresh()
    }
    
    public func setBackgroundColor(_ color: UIColor?, forState state: UIControlState)
    {
        // TODO: more granularity
        self.buttonBaseBackgroundColor = color
    }
    
    @objc private func updateColors()
    {
        guard let color = self.buttonBaseBackgroundColor else
        {
            return
        }
        
        if self.isHighlighted || self.isSelected
        {
            let darkColor = color.darkened(by: 0.15)
            (self.visualEffectView.contentView.subviews.first as! UIVisualEffectView).contentView.backgroundColor = darkColor
            //self.visualEffectView.transform = CGAffineTransform.init(translationX: 0, y: 2)
            self.shadowView.shadowRadius = 1
            self.shadowView.shadowOffset = .init(width: 0, height: 1)
            self.shadowView.shadowOpacity = 0.5
        }
        else
        {
            (self.visualEffectView.contentView.subviews.first as! UIVisualEffectView).contentView.backgroundColor = color
            //self.visualEffectView.transform = CGAffineTransform.init(translationX: 0, y: 0)
            self.shadowView.shadowRadius = 2
            self.shadowView.shadowOffset = .init(width: 0, height: 2)
            self.shadowView.shadowOpacity = 0.35
        }
    }
}

extension ABPrettyButton: SpyingButtonDelegate
{
    public func didHighlight(_ button: UIButton)
    {
        updateColors()
    }
    
    public func didSelect(_ button: UIButton)
    {
        updateColors()
    }
    
    public func didEnable(_ button: UIButton)
    {
        updateColors()
    }
}

// UIControl boilerplate.
extension ABPrettyButton
{
    public override var isEnabled: Bool
    {
        get { return self.button.isEnabled }
        set { self.button.isEnabled = newValue }
    }
    
    public override var isSelected: Bool
    {
        get { return self.button.isSelected }
        set { self.button.isSelected = newValue }
    }
    
    public override var isHighlighted: Bool
    {
        get { return self.button.isHighlighted }
        set { self.button.isHighlighted = newValue }
    }
    
    public override var contentVerticalAlignment: UIControlContentVerticalAlignment
    {
        get { return self.button.contentVerticalAlignment }
        set { self.button.contentVerticalAlignment = newValue }
    }
    
    public override var contentHorizontalAlignment: UIControlContentHorizontalAlignment
    {
        get { return self.button.contentHorizontalAlignment }
        set { self.button.contentHorizontalAlignment = newValue }
    }
    
    public override var effectiveContentHorizontalAlignment: UIControlContentHorizontalAlignment
    {
        return self.button.effectiveContentHorizontalAlignment
    }
    
    public override var state: UIControlState
    {
        return self.button.state
    }
    
    public override var isTracking: Bool
    {
        return self.button.isTracking
    }
    
    public override var isTouchInside: Bool
    {
        return self.button.isTouchInside
    }
    
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool
    {
        return self.button.beginTracking(touch, with: event)
    }
    
    public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool
    {
        return self.button.continueTracking(touch, with: event)
    }
    
    public override func endTracking(_ touch: UITouch?, with event: UIEvent?)
    {
        self.button.endTracking(touch, with: event)
    }
    
    public override func cancelTracking(with event: UIEvent?)
    {
        self.button.cancelTracking(with: event)
    }
    
    public override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControlEvents)
    {
        self.button.addTarget(target, action: action, for: controlEvents)
    }
    
    public override func removeTarget(_ target: Any?, action: Selector?, for controlEvents: UIControlEvents)
    {
        self.button.removeTarget(target, action: action, for: controlEvents)
    }
    
    public override var allTargets: Set<AnyHashable>
    {
        return self.button.allTargets
    }
    
    public override var allControlEvents: UIControlEvents
    {
        return self.button.allControlEvents
    }
    
    public override func actions(forTarget target: Any?, forControlEvent controlEvent: UIControlEvents) -> [String]?
    {
        return self.button.actions(forTarget: target, forControlEvent: controlEvent)
    }
    
    public override func sendAction(_ action: Selector, to target: Any?, for event: UIEvent?)
    {
        self.button.sendAction(action, to: target, for: event)
    }
    
    public override func sendActions(for controlEvents: UIControlEvents)
    {
        self.button.sendActions(for: controlEvents)
    }
}

// UIButton boilerplate.
extension ABPrettyButton
{
    public var contentEdgeInsets: UIEdgeInsets
    {
        get { return self.button.contentEdgeInsets }
        set { self.button.contentEdgeInsets = newValue }
    }
    
    public var titleEdgeInsets: UIEdgeInsets
    {
        get { return self.button.titleEdgeInsets }
        set { self.button.titleEdgeInsets = newValue }
    }
    
    public var reversesTitleShadowWhenHighlighted: Bool
    {
        get { return self.button.reversesTitleShadowWhenHighlighted }
        set { self.button.reversesTitleShadowWhenHighlighted = newValue }
    }
    
    public var imageEdgeInsets: UIEdgeInsets
    {
        get { return self.button.imageEdgeInsets }
        set { self.button.imageEdgeInsets = newValue }
    }
    
    public var adjustsImageWhenHighlighted: Bool
    {
        get { return self.button.adjustsImageWhenHighlighted }
        set { self.button.adjustsImageWhenHighlighted = newValue }
    }
    
    public var adjustsImageWhenDisabled: Bool
    {
        get { return self.button.adjustsImageWhenDisabled }
        set { self.button.adjustsImageWhenDisabled = newValue }
    }
    
    public var showsTouchWhenHighlighted: Bool
    {
        get { return self.button.showsTouchWhenHighlighted }
        set { self.button.showsTouchWhenHighlighted = newValue }
    }
    
    override public var tintColor: UIColor!
    {
        get { return self.button.tintColor }
        set { self.button.tintColor = newValue }
    }
    
    public var buttonType: UIButtonType
    {
        get { return self.button.buttonType }
    }
    
    public func setTitle(_ title: String?, for state: UIControlState)
    {
        self.button.setTitle(title, for: state)
    }
    
    public func setTitleColor(_ color: UIColor?, for state: UIControlState)
    {
        self.button.setTitleColor(color, for: state)
    }
    
    public func setTitleShadowColor(_ color: UIColor?, for state: UIControlState)
    {
        self.button.setTitleShadowColor(color, for: state)
    }
    
    public func setImage(_ image: UIImage?, for state: UIControlState)
    {
        self.button.setImage(image, for: state)
    }
    
    public func setBackgroundImage(_ image: UIImage?, for state: UIControlState)
    {
        self.button.setBackgroundImage(image, for: state)
    }
    
    public func setAttributedTitle(_ title: NSAttributedString?, for state: UIControlState)
    {
        self.button.setAttributedTitle(title, for: state)
    }
    
    public func title(for state: UIControlState) -> String?
    {
        return self.button.title(for: state)
    }
    
    public func titleColor(for state: UIControlState) -> UIColor?
    {
        return self.button.titleColor(for: state)
    }
    
    public func titleShadowColor(for state: UIControlState) -> UIColor?
    {
        return self.button.titleShadowColor(for: state)
    }
    
    public func image(for state: UIControlState) -> UIImage?
    {
        return self.button.image(for: state)
    }
    
    public func backgroundImage(for state: UIControlState) -> UIImage?
    {
        return self.button.backgroundImage(for: state)
    }
    
    public func attributedTitle(for state: UIControlState) -> NSAttributedString?
    {
        return self.button.attributedTitle(for: state)
    }
    
    public var currentTitle: String?
    {
        get { return self.button.currentTitle }
    }
    
    public var currentTitleColor: UIColor
    {
        get { return self.button.currentTitleColor }
    }
    
    public var currentTitleShadowColor: UIColor?
    {
        get { return self.button.currentTitleShadowColor }
    }
    
    public var currentImage: UIImage?
    {
        get { return self.button.currentImage }
    }
    
    public var currentBackgroundImage: UIImage?
    {
        get { return self.button.currentBackgroundImage }
    }
    
    public var currentAttributedTitle: NSAttributedString?
    {
        get { return self.button.currentAttributedTitle }
    }
    
    public var titleLabel: UILabel?
    {
        get { return self.button.titleLabel }
    }
    
    public var imageView: UIImageView?
    {
        get { return self.button.imageView }
    }
    
    public func backgroundRect(forBounds bounds: CGRect) -> CGRect
    {
        return self.button.backgroundRect(forBounds: bounds)
    }
    
    public func contentRect(forBounds bounds: CGRect) -> CGRect
    {
        return self.button.contentRect(forBounds: bounds)
    }
    
    public func titleRect(forContentRect contentRect: CGRect) -> CGRect
    {
        return self.button.titleRect(forContentRect: contentRect)
    }
    
    public func imageRect(forContentRect contentRect: CGRect) -> CGRect
    {
        return self.button.imageRect(forContentRect: contentRect)
    }
}

public class ABShadowView: UIView
{
    @IBOutlet public weak var targetView: UIView? { didSet { updateLayerPaths() }}
    
    public var shadowColor: UIColor? = nil { didSet { updateLayerAppearance() }}
    public var shadowOpacity: CGFloat = 0 { didSet { updateLayerAppearance() }}
    public var shadowRadius: CGFloat = 0 { didSet { updateLayerAppearance() }}
    public var shadowOffset: CGSize = .zero { didSet { updateLayerAppearance() }}
    public var shadowCornerRadius: CGFloat = 0 { didSet { updateLayerPaths() }}
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        updateLayerAppearance()
        updateLayerPaths()
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        updateLayerAppearance()
        updateLayerPaths()
    }
    
    public override func layoutSubviews()
    {
        super.layoutSubviews()
        
        updateLayerPaths()
    }
    
    public func refresh()
    {
        updateLayerAppearance()
        updateLayerPaths()
    }
    
    private func updateLayerAppearance()
    {
        self.layer.shadowColor = self.shadowColor?.cgColor
        self.layer.shadowOpacity = Float(self.shadowOpacity)
        self.layer.shadowRadius = self.shadowRadius
        self.layer.shadowOffset = self.shadowOffset
    }
    
    private func updateLayerPaths()
    {
        guard let view = self.targetView else
        {
            self.layer.shadowPath = nil
            return
        }
        
        let localRect = self.convert(view.bounds, from: view)
        
        if !(localRect.minX > bounds.minX && localRect.maxX < bounds.maxX && localRect.minY > bounds.minY && localRect.maxY < bounds.maxY)
        {
            return
        }
        
        let path = UIBezierPath.init(roundedRect: localRect, cornerRadius: self.shadowCornerRadius)
        
        let clippingPath = UIBezierPath.init(rect: self.bounds)
        clippingPath.append(path)
        
        let maskLayer = CAShapeLayer.init()
        maskLayer.fillRule = kCAFillRuleEvenOdd
        maskLayer.path = clippingPath.cgPath
        self.layer.mask = maskLayer
        
        self.layer.shadowPath = path.cgPath
    }
}
