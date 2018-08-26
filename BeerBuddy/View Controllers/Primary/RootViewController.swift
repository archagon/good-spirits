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
    // BUGFIX: KLUDGE: lazy-loaded because this controller is created whenever a popup appears
    lazy var data: DataLayer =
    {
        let data: DataLayer
        
        let path: String? = (NSTemporaryDirectory() as NSString).appendingPathComponent("\(UUID()).db")
        if let dataImpl = Data_GRDB.init(withDatabasePath: path)
        {
            data = DataLayer.init(withStore: dataImpl)
        }
        else
        {
            appError("database could not be created")
            let dataImpl = Data_Null()
            data = DataLayer.init(withStore: dataImpl)
        }
        
        // TODO: this probably does not belong here, either
        self.notificationObserver = NotificationCenter.default.addObserver(forName: DataLayer.DataDidChangeNotification, object: nil, queue: OperationQueue.main)
        { [weak `self`] _ in
            self?.syncHealthKit()
        }
        
        return data
    }()
    
    var notificationObserver: Any?
    var lastHealthKitToken: DataLayer.Token = DataLayer.NullToken
    
    // TODO: this is sort of a memory leak until the next controller shows up
    public var drawerDisplayController: DrawerDisplayController?
    
    var modelForCheckIn: Model?
    
    // TODO: figure out why this happens
    //deinit
    //{
    //    print("removing root view controller")
    //}
    
    deinit
    {
        if let observer = notificationObserver
        {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.delegate = self
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
    
    private func syncHealthKit()
    {
        self.data.getModels(fromIncludingDate: Date.distantPast, toExcludingDate: Date.distantFuture, withToken: self.lastHealthKitToken, includingDeleted: true, includingUntappdPending: false)
        {
            switch $0
            {
            case .error(let e):
                appError("could not get models from database -- \(e)")
            case .value(let v):
                for model in v.0
                {
                    if model.deleted
                    {
                        let _  = HealthKit.shared.delete(model: model.metadata.id)
                    }
                    else
                    {
                        let _ = HealthKit.shared.commit(model: model, withTimestamp: Date().timeIntervalSince1970 as NSNumber)
                    }
                }
                self.lastHealthKitToken = v.1
            }
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
    
    func showCheckInDrawer(withModel model: Model? = nil, orDate date: Date? = nil)
    {
        let storyboard = UIStoryboard.init(name: "Controllers", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "CheckIn") as! CheckInViewController
        
        if let model = model
        {
            self.modelForCheckIn = model
            controller.checkInDate = model.checkIn.time
            controller.name = model.checkIn.drink.name
            controller.abv = model.checkIn.drink.abv
            controller.volume = model.checkIn.drink.volume
            controller.style = model.checkIn.drink.style
            controller.cost = model.checkIn.drink.price
            
            if model.checkIn.untappdId != nil && !model.checkIn.untappdApproved
            {
                controller.type = .untappd
            }
            else
            {
                controller.type = .update
            }
        }
        else if let date = date
        {
            self.modelForCheckIn = nil
            controller.checkInDate = date
        }
        else
        {
            self.modelForCheckIn = nil
        }
        
        controller.delegate = self
        
        var configuration = controller.standardConfiguration
        
        // BUGFIX: KLUDGE: allows controller to resize on content changes, since we can't change the configuration after the fact
        configuration.fullExpansionBehaviour = .leavesCustomGap(gap: self.view.bounds.size.height - controller.heightOfPartiallyExpandedDrawer - 120)
        
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

extension RootViewController: UITabBarControllerDelegate
{
    public func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool
    {
        if viewController is StubViewController
        {
            showCheckInDrawer()
            return false
        }
        else
        {
            if
                viewController is UINavigationController,
                tabBarController.selectedViewController == viewController,
                let vc = ((viewController as? UINavigationController)?.topViewController as? FirstViewController)
            {
                vc.showPendingUntappd()
            }
            
            return true
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
            appError("could not get last added model (\(error))")
            return defaultDrink
        }
    }
    
    public func calendar(for: CheckInViewController) -> Calendar
    {
        return DataLayer.calendar
    }
    
    // TODO: check in for arbitrary date
    public func committed(drink: Model.Drink, onDate: Date?, for: CheckInViewController)
    {
        let updatedModel: Model
        
        if var existingModel = self.modelForCheckIn
        {
            existingModel.checkIn.drink = drink
            existingModel.approve()
            updatedModel = existingModel
        }
        else
        {
            let date = Date()
            let checkInDate = onDate ?? date
            
            updatedModel = Model.init(metadata: Model.Metadata.init(id: GlobalID.init(siteID: self.data.owner, operationIndex: DataLayer.wildcardIndex), creationTime: date), checkIn: Model.CheckIn.init(untappdId: nil, untappdApproved: false, time: checkInDate, drink: drink))
        }
        
        self.data.save(model: updatedModel)
        {
            switch $0
            {
            case .error(let e):
                appError("could not commit check-in (\(e))")
            case .value(_):
                break
            }
        }
        
        self.modelForCheckIn = nil
    }
    
    func updateDimensions(for vc: CheckInViewController)
    {
        if vc != self.presentedViewController
        {
            return
        }
        
        // KLUDGE: allows us to send signals to a private method in a private class
        vc.presentationController?.perform(Selector("refresh"))
    }
}

// KLUDGE: enables background color animation
extension RootViewController: DrawerAnimationParticipant
{
    var drawerAnimationActions: DrawerAnimationActions
    {
        let actions = DrawerAnimationActions.init(prepare:
        { [weak `self`] info in
        }, animateAlong:
        { [weak `self`] info in
            guard let container = self?.presentedViewController?.presentationController?.containerView else
            {
                return
            }
            
            if info.targetDrawerState == .collapsed
            {
                container.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            }
            else
            {
                container.backgroundColor = UIColor.black.withAlphaComponent(0.2)
            }
        })
        { [weak `self`] info in
            guard let container = self?.presentedViewController?.presentationController?.containerView else
            {
                return
            }
            
            if info.endDrawerState == .collapsed
            {
                container.backgroundColor = UIColor.black.withAlphaComponent(0.0)
            }
            else
            {
                container.backgroundColor = UIColor.black.withAlphaComponent(0.2)
            }
        }
        
        return actions
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
