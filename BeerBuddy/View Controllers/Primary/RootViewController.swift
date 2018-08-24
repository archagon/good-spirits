//
//  RootViewController.swift
//  BeerBuddy
//
//  Created by Alexei Baboulevitch on 2018-8-22.
//  Copyright © 2018 Alexei Baboulevitch. All rights reserved.
//

import Foundation
import UIKit
import DrawerKit
import DataLayer

class RootViewController: UITabBarController, DrawerCoordinating
{
    // TODO: technically, this probably ought to go in the app delegate
    var data: DataLayer
    
    public var drawerDisplayController: DrawerDisplayController?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        let path: String? = (NSTemporaryDirectory() as NSString).appendingPathComponent("\(UUID()).db")
        if let dataImpl = Data_GRDB.init(withDatabasePath: path)
        {
            self.data = DataLayer.init(withStore: dataImpl)
        }
        else
        {
            appError("database could not be created")
            let dataImpl = Data_Null()
            self.data = DataLayer.init(withStore: dataImpl)
        }
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        let path: String? = (NSTemporaryDirectory() as NSString).appendingPathComponent("\(UUID()).db")
        if let dataImpl = Data_GRDB.init(withDatabasePath: path)
        {
            self.data = DataLayer.init(withStore: dataImpl)
        }
        else
        {
            appError("database could not be created")
            let dataImpl = Data_Null()
            self.data = DataLayer.init(withStore: dataImpl)
        }
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        popupSetup: do
        {
            let appearance = PopupDialogOverlayView.appearance()
            appearance.blurEnabled = false
            appearance.opacity = 0.4
            
            let containerAppearance = PopupDialogContainerView.appearance()
            containerAppearance.cornerRadius = 16
            containerAppearance.shadowOffset = CGSize(width: 0, height: 4)
        }
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if !Defaults.configured
        {
            showLimitPopup()
        }
    }
    
    func configurePopup(_ controller: UIViewController)
    {
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.widthAnchor.constraint(equalToConstant: self.view.bounds.size.width - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right - 30).isActive = true
        controller.view.heightAnchor.constraint(equalToConstant: self.view.bounds.size.height - self.view.safeAreaInsets.top - self.view.safeAreaInsets.bottom - 100).isActive = true
    }
    
    func showLimitPopup()
    {
        let storyboard = UIStoryboard.init(name: "Controllers", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "FirstTimeSetupTest") as! StartupListPopupViewController
        
        configurePopup(controller)
        
        let popup = PopupDialog.init(viewController: controller, buttonAlignment: .vertical, transitionStyle: .bounceUp, preferredWidth: 100, tapGestureDismissal: false, panGestureDismissal: false, hideStatusBar: false, completion: nil)
        
        // AB: the rest of this is done from the controller itself
        let doneButton = DynamicPopupButton.init(title: "Accept", height: 50, dismissOnTap: false)
        { [unowned popup] in
            guard let button = popup.view.viewWithTag(1) as? DynamicPopupButton else
            {
                return
            }
            
            if controller.child.choiceMade
            {
                Defaults.configured = true
                popup.dismiss()
            }
            else
            {
                button.triggerExplanation("Please make a selection")
                popup.shake()
            }
        }
        
        doneButton.backgroundColor = UIColor.init(white: 0.75, alpha: 1)
        doneButton.titleColor = UIColor.init(white: 0.95, alpha: 1)
        doneButton.titleFont = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.regular)
        
        doneButton.tag = 1
        popup.addButtons([doneButton])
        
        self.present(popup, animated: true, completion: nil)
    }
    
    func showSettingsPopup()
    {
        let storyboard = UIStoryboard.init(name: "Controllers", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "Settings") as! SettingsPopupViewController
        
        configurePopup(controller)
        
        let popup = PopupDialog.init(viewController: controller, buttonAlignment: .vertical, transitionStyle: .bounceUp, preferredWidth: 100, tapGestureDismissal: true, panGestureDismissal: true, hideStatusBar: false, completion: nil)
        
        // AB: the rest of this is done from the controller itself
        let doneButton = DefaultButton.init(title: "Close", height: 50, dismissOnTap: true, action: nil)
        
        doneButton.backgroundColor = Appearance.themeColor.withAlphaComponent(0.7)
        doneButton.titleColor = UIColor.init(white: 1, alpha: 1)
        doneButton.titleFont = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.regular)
        
        doneButton.tag = 1
        popup.addButtons([doneButton])
        
        self.present(popup, animated: true, completion: nil)
    }
    
    func showCheckInDrawer()
    {
        let storyboard = UIStoryboard.init(name: "Controllers", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "CheckIn") as! CheckInViewController
        
        controller.delegate = self
        
        var configuration = DrawerConfiguration.init()
        configuration.fullExpansionBehaviour = .leavesCustomGap(gap: 100)
        configuration.timingCurveProvider = UISpringTimingParameters(dampingRatio: 0.8)
        configuration.cornerAnimationOption = .alwaysShowBelowStatusBar
        
        var handleViewConfiguration = HandleViewConfiguration()
        handleViewConfiguration.autoAnimatesDimming = false
        configuration.handleViewConfiguration = handleViewConfiguration
        
        let drawerShadowConfiguration = DrawerShadowConfiguration(shadowOpacity: 0.25,
                                                                  shadowRadius: 4,
                                                                  shadowOffset: .zero,
                                                                  shadowColor: .black)
        configuration.drawerShadowConfiguration = drawerShadowConfiguration
        
        let pulley = DrawerDisplayController.init(presentingViewController: self, presentedViewController: controller, configuration: configuration, inDebugMode: false)
        self.drawerDisplayController = pulley
        
        self.present(controller, animated: true, completion: nil)
    }
    
    override func performSegue(withIdentifier identifier: String, sender: Any?)
    {
        if identifier == "Settings"
        {
            showSettingsPopup()
        }
    }
}

extension RootViewController: CheckInViewControllerDelegate
{
    public func defaultCheckIn(for: CheckInViewController) -> Model.Drink
    {
        let defaultPrice: Double = 5
        let defaultDrink = Model.Drink.init(name: nil, style: DrinkStyle.defaultStyle, abv: DrinkStyle.defaultStyle.defaultABV, price: defaultPrice, volume: DrinkStyle.defaultStyle.defaultVolume)
        
        do
        {
            if let model = try self.data.getLastAddedModel()
            {
                return model.checkIn.drink
            }
            else
            {
                return defaultDrink
            }
        }
        catch
        {
            appError("\(error)")
            return defaultDrink
        }
    }
    
    public func calendar(for: CheckInViewController) -> Calendar
    {
        return DataLayer.calendar
    }
    
    public func committed(drink: Model.Drink, for: CheckInViewController)
    {
        let range = Time.currentWeek()
        
        let randomTime = range.0.timeIntervalSince1970 + TimeInterval.random(in: 0..<(range.1.timeIntervalSince1970 - range.0.timeIntervalSince1970))
        let randomDate = Date.init(timeIntervalSince1970: randomTime)
        
        let model = Model.init(metadata: Model.Metadata.init(id: GlobalID.init(siteID: self.data.owner, operationIndex: DataLayer.wildcardIndex), creationTime: Date()), checkIn: Model.CheckIn.init(untappdId: nil, time: randomDate, drink: drink))
        
        self.data.save(model: model)
        {
            switch $0
            {
            case .error(let e):
                appError("\(e)")
            case .value(let v):
                break
            }
        }
    }
}

// AB: this is a hack, but hey, it works
class SettingsSegue: UIStoryboardSegue
{
    override func perform()
    {
        (self.source.tabBarController as? RootViewController)?.showSettingsPopup()
    }
}
