//
// AppController.swift
//
// Copyright (c) 2019 Christian Gossain
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

public protocol AppControllerInterfaceProviding {
    /// Return a configuration object describing the transition parameters.
    ///
    /// - Parameters:
    ///     - controller: The app controller instance requesting the configuration.
    ///     - traitCollection: The current trait collection of the root view controller.
    /// - Returns: A configuration model describing the transition parameters.
    func configuration(for controller: AppController, traitCollection: UITraitCollection) -> AppController.Configuration
    
    /// Return the view controller to be installed as the "logged out" interface.
    ///
    /// - Parameters:
    ///     - controller: The app controller instance requesting the configuration.
    /// - Returns: A view controller to install as the logged out interface.
    ///
    func loggedOutInterfaceViewController(for controller: AppController) -> UIViewController
    
    /// Return the view controller to be installed as the "logged in" interface.
    ///
    /// - Parameters:
    ///     - controller: The app controller instance requesting the configuration.
    /// - Returns: A view controller to install as the logged in interface.
    ///
    func loggedInInterfaceViewController(for controller: AppController) -> UIViewController
    
    /// Return true if the "logged in" interface should be initially loaded, or false if the "logged out" interface is initially loaded.
    ///
    /// - Parameters:
    ///     - controller: The app controller instance requesting the configuration.
    /// - Returns: `true` if the logged in interface should be initially presented, `false` otherwise.
    ///
    func isInitiallyLoggedIn(for controller: AppController) -> Bool
}

public class AppController {
    public struct Configuration {
        /// The animation duration when transitionning between logged in/out states. A duration of zero
        /// indicates no animation should occur.
        public var transitionDuration: TimeInterval = 0.6
        
        /// The animation delay when transitioning between logged in/out states. The default value of 0.0 generally
        /// works well, however they may be times when an additional delay is required. This is provided
        /// as an additional transition configuration point.
        public var transitionDelay: TimeInterval = 0.0
        
        /// Indicates if the any presented view controllers should first be dismissed before performing
        /// the interface transition. The default value of `true` should work well for most cases. This
        /// is provided as an additional transition configuration point.
        public var dismissesPresentedViewControllerOnTransition = true
        
        /// Initializes the configuration with the given options.
        public init(transitionDuration: TimeInterval = 0.6, dismissesPresentedViewControllerOnTransition: Bool = true) {
            self.transitionDuration = transitionDuration
            self.dismissesPresentedViewControllerOnTransition = dismissesPresentedViewControllerOnTransition
        }
    }
    
    /// The object that acts as the interface provider for the controller.
    let interfaceProvider: AppControllerInterfaceProviding
    
    /// A closure that is called just before the transition to the _logged in_ interface begins. The view
    /// controller that is about to be presented is passed to the block as the targetViewController.
    ///
    /// - Note: This handler is called just before the transition begins, this means that if configured accordingly
    ///         a presented view controller would first be dismissed before this handler is called.
    public var willLoginHandler: ((_ targetViewController: UIViewController) -> Void)?
    
    /// A closure that is called after the transition to the _logged in_ interface completes.
    public var didLoginHandler: (() -> Void)?
    
    /// A closure that is called just before the transition to the _logged out_ interface begins. The view
    /// controller that is about to be presented is passed to the block as the targetViewController.
    ///
    /// - Note: This handler is called just before the transition begins, this means that if configured accordingly
    ///         a presented view controller would first be dismissed before this handler is called.
    public var willLogoutHandler: ((_ targetViewController: UIViewController) -> Void)?
    
    /// A closure that is called after the transition to the _logged out_ interface completes.
    public var didLogoutHandler: (() -> Void)?
    
    /// The view controller that should be installed as your window's rootViewController.
    public lazy var rootViewController: AppViewController = {
        if let storyboard = self.storyboard {
            // get the rootViewController from the storyboard
            return storyboard.instantiateInitialViewController() as! AppViewController
        }
        
        // if there is no storyboard, just create an instance of the app view controller (using the custom class if provided)
        return self.appViewControllerClass.init()
    }()
    
    /// Returns the storyboard instance being used if the controller was initialized using the convenience storyboad initializer, otherwise retuns `nil`.
    public var storyboard: UIStoryboard? {
        return (interfaceProvider as? StoryboardInterfaceProvider)?.storyboard
    }
    
    
    // MARK: - Lifecycle
    /// Initializes the controller using the specified storyboard name, and uses the given `loggedOutInterfaceID`, and `loggedInInterfaceID` values to instantiate 
    /// the appropriate view controller from the storyboad.
    ///
    /// - Parameters:
    ///     - storyboardName: The name of the storyboard that contains the view controllers.
    ///     - loggedOutInterfaceID: The storyboard identifier of the view controller to use as the _logged out_ view controller.
    ///     - loggedInInterfaceID: The storyboard identifier of the view controller to use as the _logged in_ view controller.
    /// - Note: The controller automatically installs the _initial view controller_ from the storyboard as the root view
    ///         controller. Therfore, the _initial view controller_ in the specified storyboard MUST be an instance
    ///         of `AppViewController`, otherwise a crash will occur.
    public convenience init(storyboardName: String, loggedOutInterfaceID: String, loggedInInterfaceID: String, configuration: AppController.Configuration = Configuration()) {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let provider = StoryboardInterfaceProvider(storyboard: storyboard, loggedOutInterfaceID: loggedOutInterfaceID, loggedInInterfaceID: loggedInInterfaceID, configuration: configuration)
        self.init(interfaceProvider: provider)
    }
    
    /// Initializes the controller with closures that return the view controllers to install for the _logged out_ and _logged in_ states.
    ///
    /// - Parameters:
    ///     - interfaceProvider: The object that will act as the interface provider for the controller.
    ///     - appViewControllerClass: Specify a custom `AppViewController` subclass to use as the rootViewController, or `nil` to use the standard `AppViewController`.
    public init(interfaceProvider: AppControllerInterfaceProviding, appViewControllerClass: AppViewController.Type? = nil) {
        self.interfaceProvider = interfaceProvider
        
        // replace the default AppViewController class with the custom class, if provided
        if let customAppViewControllerClass =  appViewControllerClass {
            self.appViewControllerClass = customAppViewControllerClass
        }
        
        // observe login notifications
        loginNotificationObserver =
            NotificationCenter.default.addObserver(
                forName: AppController.shouldLoginNotification,
                object: nil,
                queue: .main,
                using: { [weak self] notification in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    strongSelf.transitionToLoggedInInterface()
            })
        
        // observe logout notifications
        logoutNotificationObserver =
            NotificationCenter.default.addObserver(
                forName: AppController.shouldLogoutNotification,
                object: nil,
                queue: .main,
                using: { [weak self] notification in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    strongSelf.transitionToLoggedOutInterface()
            })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(loginNotificationObserver!)
        NotificationCenter.default.removeObserver(logoutNotificationObserver!)
    }
    
    
    // MARK: - Internal Use
    fileprivate var appViewControllerClass = AppViewController.self
    fileprivate var loginNotificationObserver: AnyObject?
    fileprivate var logoutNotificationObserver: AnyObject?
    
}

extension AppController {
    /// Internal notification that is posted on `AppController.login()`.
    fileprivate static let shouldLoginNotification = Notification.Name(rawValue: "AppControllerShouldLoginNotification")
    
    /// Internal notification that is posted on `AppController.logout()`.
    fileprivate static let shouldLogoutNotification = Notification.Name(rawValue: "AppControllerShouldLogoutNotification")
    
    /// Installs the receivers' instance of `AppViewController` as the windows' `rootViewController`, then calls `makeKeyAndVisible()` on
    /// the window, and finally transtitions to the initial interface.
    public func installRootViewController(in window: UIWindow) {
        // setting the root view controller before transitioning allows the target interface to have access to a fully defined trait collection if needed
        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        
        // transtion to the initial interface; since handlers should already be aware of their desired initial interface, they shouldn't be notified here
        if interfaceProvider.isInitiallyLoggedIn(for: self) {
            transitionToLoggedInInterface(notify: false)
        }
        else {
            transitionToLoggedOutInterface(notify: false)
        }
    }
    
    /// Posts a notification that notifies any active AppController instance to switch to its _logged in_ interface.
    /// Note that any given app should only have a single active AppController instance. Therefore that single instance
    /// will be the one that receives and handles the notification.
    public static func login() {
        NotificationCenter.default.post(name: AppController.shouldLoginNotification, object: nil, userInfo: nil)
    }
    
    /// Posts a notification that notifies any active AppController instance to switch to its _logged out_ interface.
    /// Note that any given app should only have a single active AppController instance. Therefore that single instance
    /// will be the one that receives and handles the notification.
    public static func logout() {
        NotificationCenter.default.post(name: AppController.shouldLogoutNotification, object: nil, userInfo: nil)
    }
}

fileprivate extension AppController {
    func transitionToLoggedInInterface(notify: Bool = true) {
        let target = interfaceProvider.loggedInInterfaceViewController(for: self)
        let configuration = interfaceProvider.configuration(for: self, traitCollection: rootViewController.traitCollection)
        rootViewController.transition(to: target, configuration: configuration, willBeginTransition: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            if notify {
                strongSelf.willLoginHandler?(target)
            }
        }, completionHandler: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            if notify {
                strongSelf.didLoginHandler?()
            }
        })
    }
    
    func transitionToLoggedOutInterface(notify: Bool = true) {
        let target = interfaceProvider.loggedOutInterfaceViewController(for: self)
        let configuration = interfaceProvider.configuration(for: self, traitCollection: rootViewController.traitCollection)
        rootViewController.transition(to: target, configuration: configuration, willBeginTransition: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            if notify {
                strongSelf.willLogoutHandler?(target)
            }
        }, completionHandler: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            if notify {
                strongSelf.didLogoutHandler?()
            }
        })
    }
}
