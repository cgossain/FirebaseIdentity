//
//  AppDelegate.swift
//
//  Copyright (c) 2024 Christian Gossain
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import AppController
import FBSDKCoreKit
import Firebase
import FirebaseIdentity
import UIKit

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
        // facebook
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // firebase
        FirebaseApp.configure()
        
        // access default instance just to initialize the subscriptions
        // this wouldn't be an issue if using dependency injection
        print(AuthManager.default.authState)
        
        // observer auth state
        authenticationStateObserver =
        NotificationCenter
            .default
            .addObserver(
                forName: .authenticationStateChanged, object: nil, queue: .main, using: { (note) in
                    guard let manager = note.object as? AuthManager else {
                        return
                    }
                    
                    switch manager.authState {
                    case .notDetermined:
                        break
                    case .notAuthenticated:
                        AppController.logout()
                    case .authenticated:
                        AppController.login()
                    }
                }
            )
        
        let aWindow = UIWindow()
        self.window = aWindow
        appController.installRootViewController(in: aWindow)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // check if Facebook SDK can handle
        if ApplicationDelegate.shared.application(app, open: url, options: options) {
            return true
        }
        
        // we did not handle the url
        return false
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
        AppController.Configuration()
    }
    
    func loggedOutInterfaceViewController(for appController: AppController) -> UIViewController {
        SignedOutViewController()
    }
    
    func loggedInInterfaceViewController(for appController: AppController) -> UIViewController {
        SignedInViewController()
    }
    
    func isInitiallyLoggedIn(for appController: AppController) -> Bool {
        false
    }
}
