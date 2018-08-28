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
        
        //let path: String? = (NSTemporaryDirectory() as NSString).appendingPathComponent("\(UUID()).db")
        guard let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else
        {
            appError("could not open documents directory")
            return DataLayer.init(withStore: Data_Null.init())
        }
        
        let path: String? = (dir as NSString).appendingPathComponent("data.db")
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
        
        return data
    }()
    
    var notificationObserver: Any?
    var defaultsObserver: Any?
    
    // TODO: this is sort of a memory leak until the next controller shows up
    public var drawerDisplayController: DrawerDisplayController?
    
    var checkInButton: UIButton!
    
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
        if let observer = defaultsObserver
        {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        if (UIApplication.shared.delegate as? AppDelegate)?.rootController == nil
        {
            (UIApplication.shared.delegate as? AppDelegate)?.rootController = self
        }
        self.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        if (UIApplication.shared.delegate as? AppDelegate)?.rootController == nil
        {
            (UIApplication.shared.delegate as? AppDelegate)?.rootController = self
        }
        self.delegate = self
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        addCheckInButton: do
        {
            let button = UIButton()
            button.setBackgroundImage(UIImage.init(named: "check-in"), for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.tintColor = Appearance.themeColor.darkened(by: 0.1)
            
            tabBar.addSubview(button)
            tabBar.centerXAnchor.constraint(equalTo: button.centerXAnchor).isActive = true
            tabBar.topAnchor.constraint(equalTo: button.centerYAnchor, constant: -15).isActive = true
            button.heightAnchor.constraint(equalToConstant: 55).isActive = true
            button.widthAnchor.constraint(equalToConstant: 55).isActive = true
            
            tabBar.tintColor = Appearance.themeColor.mixed(with: .white, by: 0.0)
            
            button.addTarget(self, action: #selector(showCheckInDrawer), for: .touchUpInside)
            
            self.checkInButton = button
        }
        
        
        syncUntappd(withCallback: { _ in })
        syncHealthKit()
        
        untappdTimer: do
        {
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true)
            { [weak `self`] _ in
                appDebug("firing sync with Untappd")
                self?.syncUntappd(withCallback: { _ in })
            }
        }
        
        popupSetup: do
        {
            let appearance = PopupDialogOverlayView.appearance()
            appearance.blurEnabled = false
            appearance.opacity = 0.4
            
            let containerAppearance = PopupDialogContainerView.appearance()
            containerAppearance.cornerRadius = 16
            containerAppearance.shadowOffset = CGSize(width: 0, height: 4)
        }
        
        self.notificationObserver = NotificationCenter.default.addObserver(forName: DataLayer.DataDidChangeNotification, object: nil, queue: OperationQueue.main)
        { [weak `self`] _ in
            self?.syncHealthKit()
        }
        self.defaultsObserver = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: OperationQueue.main)
        { [weak `self`] _ in
            healthKit: do
            {
                if Defaults.healthKitEnabled && Defaults.healthKitBaseline == nil
                {
                    appDebug("refreshing HK baseline...")
                    self?.data.getModels(fromIncludingDate: Date.distantFuture, toExcludingDate: Date.distantFuture)
                    {
                        switch $0
                        {
                        case .error(let e):
                            appError("error fetching token -- \(e.localizedDescription)")
                        case .value(let v):
                            Defaults.healthKitBaseline = v.1
                        }
                    }
                }
                else if !Defaults.healthKitEnabled && Defaults.healthKitBaseline != nil
                {
                    appDebug("clearing HK baseline...")
                    Defaults.healthKitBaseline = nil
                }
            }
            
            untappd: do
            {
                if Defaults.untappdToken != nil && Defaults.untappdBaseline == nil
                {
                    // AB: this sets the baseline
                    // TODO: this creates a ton of duplicate calls and eats up our rate limit, figure out why
                    //self?.syncUntappd(withCallback: { _ in })
                }
                else if Defaults.untappdToken == nil && Defaults.untappdBaseline != nil
                {
                    Defaults.untappdBaseline = nil
                }
            }
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
    
    public func syncUntappd(withCallback block: @escaping (Error?)->Void)
    {
        switch Untappd.shared.loginStatus
        {
        case .unreachable:
            block(Untappd.UntappdError.notReachable)
            return
        case .disabled:
            block(Untappd.UntappdError.notEnabled)
            return
        case .enabledAndAuthorized:
            break
        }
        
        if Defaults.untappdBaseline != nil
        {
            appDebug("syncing with Untappd using baseline \(Defaults.untappdBaseline!)")
        }
        
        Untappd.shared.userCheckIns(withBaseline: Defaults.untappdBaseline)
        { [weak `self`] in
            switch $0
            {
            case .error(let e):
                appWarning("Untappd refresh error -- \(e.localizedDescription)")
                block(e)
            case .value(let checkIns):
                updateBaseline: do
                {
                    let hadBaseline = Defaults.untappdBaseline != nil
                    
                    let highestCheckIn = checkIns.max { $0.checkin_id < $1.checkin_id }
                    if let highestBaseline = highestCheckIn?.checkin_id
                    {
                        appDebug("set baseline to \(highestBaseline)")
                        Defaults.untappdBaseline = highestBaseline
                    }
                    
                    if !hadBaseline
                    {
                        block(nil)
                        return
                    }
                }
                
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
                    self?.data.save(model: model, syncing: true)
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
                
                onMain
                {
                    // TODO: technically, does not take database calls into consideration; might have errors
                    block(nil)
                }
            }
        }
    }
    
    private func syncHealthKit()
    {
        if HealthKit.shared.loginStatus != .enabledAndAuthorized
        {
            appDebug("HK not enabled, skipping sync")
            return
        }
        
        guard let lastHealthKitToken = Defaults.healthKitBaseline else
        {
            appWarning("HK token not found, can't sync")
            return
        }
        
        self.data.getModels(fromIncludingDate: Date.distantPast, toExcludingDate: Date.distantFuture, withToken: lastHealthKitToken, includingDeleted: true, includingUntappdPending: false)
        {
            switch $0
            {
            case .error(let e):
                appError("could not get models from database -- \(e.localizedDescription)")
            case .value(let data):
                self.data.primaryStore.readTransaction
                { db in
                    // TODO: since we're out of the transaction, this could be invalid at this point
                    db.lamportTimestamp
                    { err in
                        onMain
                        {
                            switch err
                            {
                            case .error(let e):
                                appError("could not get lamport from database -- \(e.localizedDescription)")
                            case .value(let v):
                                for model in data.0
                                {
                                    if model.deleted
                                    {
                                        if let err  = HealthKit.shared.delete(model: model.metadata.id)
                                        {
                                            appWarning("could not complete HK delete -- \(err.localizedDescription)")
                                        }
                                    }
                                    else
                                    {
                                        if let err = HealthKit.shared.commit(model: model, withTimestamp: v as NSNumber)
                                        {
                                            appWarning("could not complete HK sync -- \(err.localizedDescription)")
                                        }
                                    }
                                    
                                    Defaults.healthKitBaseline = data.1
                                }
                            }
                        }
                    }
                }
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
    
    @objc func showCheckInDrawer()
    {
        showCheckInDrawer(withModel: nil, orDate: nil)
    }
    
    func showCheckInDrawer(withModel model: Model? = nil, orDate date: Date? = nil)
    {
        let storyboard = UIStoryboard.init(name: "Controllers", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "CheckIn") as! CheckInViewController
        
        var defaultDrink: Model.Drink? = nil
        do
        {
            defaultDrink = try self.data.getLastAddedModel()?.checkIn.drink
        }
        catch
        {
            appError("could not get last added model -- \(error.localizedDescription)")
        }
        
        if let model = model
        {
            self.modelForCheckIn = model
            
            controller.name = model.checkIn.drink.name
            controller.checkInDate = model.checkIn.time
            controller.defaultData = model.checkIn.drink
            
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
            
            controller.defaultData = defaultDrink
            controller.checkInDate = date
        }
        else
        {
            self.modelForCheckIn = nil
            
            controller.defaultData = defaultDrink
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
    public func calendar(for: CheckInViewController) -> Calendar
    {
        return DataLayer.calendar
    }
    
    public func committed(drink: Model.Drink, onDate: Date?, for vc: CheckInViewController)
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
                appError("could not commit check-in -- \(e.localizedDescription)")
            case .value(_):
                break
            }
        }
        
        self.modelForCheckIn = nil
        
        self.checkInButton.tintColor = Appearance.greenProgressColor
        UIView.animate(withDuration: 1, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            self.checkInButton.tintColor = Appearance.themeColor.darkened(by: 0.1)
        }, completion: nil)
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
