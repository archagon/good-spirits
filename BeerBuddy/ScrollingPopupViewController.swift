//
//  ScrollingPopupViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-7-23.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import UIKit

public protocol ScrollingPopupViewControllerDelegate: class
{
    func scrollingPopupDidTapToDismiss(_ vc: ScrollingPopupViewController)
}

public class ScrollingPopupViewController: UIViewController
{
    public weak var delegate: ScrollingPopupViewControllerDelegate?
    
    public var viewController: UIViewController?
    {
        get
        {
            return self._state.viewController
        }
        set
        {
            if let vc = newValue
            {
                transition(to: self.viewIfLoaded == nil ? .noViewController(vc: vc) : .viewController(vc: vc))
            }
            else
            {
                transition(to: self.viewIfLoaded == nil ? .noViewNoController : .viewNoController)
            }
        }
    }
    private var viewControllerConstraints: (width: NSLayoutConstraint, others: [NSLayoutConstraint])?
    
    private let backdrop: UIView
    private let scrollView: UIScrollView
    private var scrollViewTapRecognizer: UITapGestureRecognizer!
    
    public init()
    {
        self.backdrop = UIView()
        self.scrollView = UIScrollView()
        
        super.init(nibName: nil, bundle: nil)
        
        self.scrollViewTapRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(dismissHook))
        self.scrollView.addGestureRecognizer(self.scrollViewTapRecognizer)
        
        viewSetup: do
        {
            self.backdrop.backgroundColor = UIColor.black
            self.backdrop.alpha = 0.5
        }
        
        transition(to: self.viewIfLoaded == nil ? .noViewNoController : .viewNoController)
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad()
    {
        super.viewDidLoad()
        
        viewHierarchy: do
        {
            self.backdrop.translatesAutoresizingMaskIntoConstraints = false
            self.scrollView.translatesAutoresizingMaskIntoConstraints = false
            
            self.view.addSubview(self.backdrop)
            self.view.addSubview(self.scrollView)
            
            self.scrollView.contentSize = CGSize.init(width: 5000, height: 5000)
        }
        
        constraints: do
        {
            let views = ["backdrop":backdrop, "scrollView":scrollView]
            
            let backdropHConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[backdrop]|", options: [], metrics: nil, views: views)
            let backdropVConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[backdrop]|", options: [], metrics: nil, views: views)
            
            let scrollViewHConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|", options: [], metrics: nil, views: views)
            let scrollViewVConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView]|", options: [], metrics: nil, views: views)
            
            let constraints = backdropHConstraints + backdropVConstraints + scrollViewHConstraints + scrollViewVConstraints
            
            NSLayoutConstraint.activate(constraints)
        }
        
        transitionToView()
        adjustScrollViewContents()
    }
    
    public func show(animated: Bool = true)
    {
    }
    
    public func hide(animated: Bool = true)
    {
    }
    
    // Sets the scroll view's content size and adjusts the popup position, if available.
    private func adjustScrollViewContents(withSize size: CGSize? = nil)
    {
        let minHMargin: CGFloat = 32
        let minVMargin: CGFloat = 50
        
        guard let mainView = self.viewIfLoaded else
        {
            return
        }
        
        let viewSize = size ?? mainView.bounds.size
        self.scrollView.contentSize = CGSize.init(width: viewSize.width, height: 0)
        
        if let vc = self.viewController, let view = vc.viewIfLoaded, self.scrollView.subviews.first == view
        {
            view.layer.cornerRadius = 16
            view.clipsToBounds = true
            
            view.translatesAutoresizingMaskIntoConstraints = false
            view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            
            let widthConstant: CGFloat = vc.preferredContentSize.width
            
            if self.viewControllerConstraints == nil
            {
                let width = view.widthAnchor.constraint(equalToConstant: widthConstant)
                width.priority = .defaultHigh
                let left = view.leftAnchor.constraint(greaterThanOrEqualTo: self.scrollView.leftAnchor, constant: minHMargin)
                left.priority = .required
                let center = view.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor)
                center.priority = .required
                
                let top = view.topAnchor.constraint(greaterThanOrEqualTo: self.scrollView.topAnchor, constant: minVMargin)
                top.priority = .defaultHigh
                let centerY = view.centerYAnchor.constraint(equalTo: self.scrollView.centerYAnchor)
                centerY.priority = .defaultLow
                
                self.viewControllerConstraints = (width: width, others: [left, center, top, centerY])
            }
            
            guard let constraints = self.viewControllerConstraints else { return }
            
            constraints.width.constant = vc.preferredContentSize.width
            NSLayoutConstraint.activate([constraints.width] + constraints.others)
        }
    }
    
    public override func viewDidLayoutSubviews()
    {
        super.viewDidLayoutSubviews()
        
        self.scrollView.contentSize.height = 50 + 50 + (self.viewController?.viewIfLoaded?.bounds.size.height ?? 0)
    }
    
    public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer)
    {
        adjustScrollViewContents()
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        adjustScrollViewContents(withSize: size)
    }
    
    // Feel free to point buttons to this method.
    @objc public func dismissHook()
    {
        self.delegate?.scrollingPopupDidTapToDismiss(self)
    }
    
    //////////////////////////////
    // MARK: - State Transitions -
    //////////////////////////////

    private enum State
    {
        case none
        case noViewNoController
        case noViewController(vc: UIViewController)
        case viewNoController
        case viewController(vc: UIViewController)
        
        public var view: Bool
        {
            switch self
            {
            case .none:
                return false
            case .noViewNoController:
                return false
            case .noViewController(_):
                return false
            case .viewNoController:
                return true
            case .viewController(_):
                return true
            }
        }
        
        public var viewController: UIViewController?
        {
            switch self
            {
            case .none:
                return nil
            case .noViewNoController:
                return nil
            case .noViewController(let vc):
                return vc
            case .viewNoController:
                return nil
            case .viewController(let vc):
                return vc
            }
        }
    }
    
    // do not mutate directly -- only via transition function
    private var _state: State = .none
    
    private func transitionToView()
    {
        if let vc = self._state.viewController
        {
            transition(to: .viewController(vc: vc))
        }
        else
        {
            transition(to: .viewNoController)
        }
    }
    
    private func transition(to: State)
    {
        var controllerAdded: Bool = false
        
        func addChildViewController(_ vc: UIViewController?)
        {
            guard let vc = vc else { return }
            
            self.addChildViewController(vc)
            vc.view.autoresizingMask = []
            self.scrollView.addSubview(vc.view)
            vc.didMove(toParentViewController: self)
            
            controllerAdded = true
        }
        
        func removeChildViewController(_ vc: UIViewController?)
        {
            guard let vc = vc else { return }
            
            vc.willMove(toParentViewController: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParentViewController()
            
            self.viewControllerConstraints = nil
        }
        
        stateTransition: do
        {
            switch self._state
            {
            case .none:
                switch to
                {
                case .none:
                    break
                case .noViewNoController:
                    break
                case .noViewController(_):
                    break
                case .viewNoController:
                    break
                case .viewController(let vc):
                    addChildViewController(vc)
                }
            case .noViewNoController:
                switch to
                {
                case .none:
                    throw NSError()
                case .noViewNoController:
                    break
                case .noViewController(_):
                    break
                case .viewNoController:
                    break
                case .viewController(let vc):
                    addChildViewController(vc)
                }
            case .noViewController(_):
                switch to
                {
                case .none:
                    throw NSError()
                case .noViewNoController:
                    break
                case .noViewController(_):
                    break
                case .viewNoController:
                    break
                case .viewController(let vc):
                    addChildViewController(vc)
                }
            case .viewNoController:
                switch to
                {
                case .none:
                    throw NSError()
                case .noViewNoController:
                    throw NSError()
                case .noViewController(_):
                    throw NSError()
                case .viewNoController:
                    break
                case .viewController(let vc):
                    addChildViewController(vc)
                }
            case .viewController(let pvc):
                switch to
                {
                case .none:
                    throw NSError()
                case .noViewNoController:
                    throw NSError()
                case .noViewController(_):
                    throw NSError()
                case .viewNoController:
                    removeChildViewController(pvc)
                case .viewController(let vc):
                    if vc != pvc
                    {
                        removeChildViewController(pvc)
                        addChildViewController(vc)
                    }
                }
            }
        }
        catch
        {
            appError("invalid transition between states")
        }
        
        self._state = to
        
        if controllerAdded
        {
            adjustScrollViewContents()
        }
        
        assertions: do
        {
            assert((self._state.view && self.viewIfLoaded != nil) || (!self._state.view && self.viewIfLoaded == nil))
            assert(!(self._state.view && self._state.viewController != nil) || (self.viewController != nil && self.viewController!.parent == self && self.viewController!.view.superview == self.scrollView))
        }
    }
}
