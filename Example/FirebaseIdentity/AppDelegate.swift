//
//  AppDelegate.swift
//  FirebaseIdentity
//
//  Created by cgossain on 02/24/2019.
//  Copyright (c) 2019 cgossain. All rights reserved.
//

import UIKit
import AppController
import FBSDKCoreKit
import Firebase
import FirebaseIdentity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private lazy var appController: AppController = {
        let controller = AppController(interfaceProvider: self)
        return controller
    }()
    
    private var authenticationStateObserver: Any?
    
    
    // MARK: - UIApplicationDelegate
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let aWindow = UIWindow()
        self.window = aWindow
        
        appController.installRootViewController(in: aWindow)
        
        // firebase
        FirebaseApp.configure()
        
        // facebook
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // author
        AuthManager.configure()
        
        // observer auth state
        authenticationStateObserver =
            NotificationCenter.default.addObserver(forName: AuthManager.authenticationStateChangedNotification, object: nil, queue: .main, using: { (note) in
                guard let manager = note.object as? AuthManager else {
                    return
                }
                
                switch manager.state {
                case .authenticated:
                    AppController.login()
                case .notDetermined, .notAuthenticated:
                    AppController.logout()
                }
            })
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
}

extension AppDelegate: AppControllerInterfaceProviding {
    func configuration(for appController: AppController, traitCollection: UITraitCollection) -> AppController.Configuration {
        return AppController.Configuration()
    }
    
    func loggedOutInterfaceViewController(for appController: AppController) -> UIViewController {
        return SignedOutViewController()
    }
    
    func loggedInInterfaceViewController(for appController: AppController) -> UIViewController {
        return SignedInViewController()
    }
    
    func isInitiallyLoggedIn(for appController: AppController) -> Bool {
        return false
    }
}
