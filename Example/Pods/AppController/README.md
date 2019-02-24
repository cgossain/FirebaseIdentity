# AppController

[![CI Status](http://img.shields.io/travis/Christian Gossain/AppController.svg?style=flat)](https://travis-ci.org/Christian Gossain/AppController)
[![Version](https://img.shields.io/cocoapods/v/AppController.svg?style=flat)](http://cocoapods.org/pods/AppController)
[![License](https://img.shields.io/cocoapods/l/AppController.svg?style=flat)](http://cocoapods.org/pods/AppController)
[![Platform](https://img.shields.io/cocoapods/p/AppController.svg?style=flat)](http://cocoapods.org/pods/AppController)

## Introduction

This project was originaly inspired by the architecture described in [this blog post](http://dev.teeps.org/blog/2015/3/27/how-to-architect-your-ios-app).

The purpose of the AppController is to cleanup the code required to manage transitioning between `logged out` and `logged in` interfaces using proper iOS view controller containment. It supports programatically loading your view controllers, and also offers a convenience initializer to load your interfaces from a storyboard file.

The controller is easy to use. Just create an instance of the controller (typically in the AppDelegate), give it a reference to your application window, and the controller takes care of the rest. After the initial load you simply call `AppController.login()` or `AppController.logout()` to transition to the desired interface (i.e. on an auth state change notification).

## Requirements
* iOS 9.3+
* Swift 3.0+

## Installation

AppController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "AppController"
```

## Usage

Create an interface provider:
```
class MyAwesomeInterfaceProvider: AppControllerInterfaceProviding {

    func configuration(for appController: AppController, traitCollection: UITraitCollection) -> AppController.Configuration {
      // return a configuration model for the transition
      // note that the default configuration is being returned here, but it can be further configured
      return AppController.Configuration()
    }

    func loggedOutInterfaceViewController(for appController: AppController) -> UIViewController {
        // create and return your logged out interface view controller
        let welcomeViewController = WelcomeViewController()
        return welcomeViewController
    }

    func loggedInInterfaceViewController(for appController: AppController) -> UIViewController {
        // create and return your logged in interface view controller
        let tabBarController = UITabBarController()
        return tabBarController
    }

    func isInitiallyLoggedIn(for: AppController) -> Bool {
        // return `true` if the "logged in" interface should be initially loaded instead
        return false
    }

}

```

Create the AppController instance and install its `rootViewController` as the `rootViewController` of your main window:
```
import UIKit
import AppController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let myAwesomeInterfaceProvider = MyAwesomeInterfaceProvider()

    lazy var appController: AppController = {
        let controller = AppController(interfaceProvider: self.myAwesomeInterfaceProvider)

        // do stuff just before login transition...
        controller.willLoginHandler = { [unowned self] (targetViewController) in

        }

        // do stuff right after login transition...
        controller.didLoginHandler = { [unowned self] in

        }

        // do stuff just before logout transition...
        controller.willLogoutHandler = { [unowned self] (targetViewController) in

        }

        // do stuff right after logout transition...
        controller.didLogoutHandler = { [unowned self] in

        }

        return controller
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        let myWindow = UIWindow()
        window = myWindow

        // install the app controllers' root view controller as the root view controller of the window
        appController.installRootViewController(in: myWindow)

        return true
    }

}
```

Transition to "logged in" interface:
```
AppController.login()
```

Transition to "logged out" interface:
```
AppController.logout()
```

## Storyboard Support
If you use a storyboard file, you can easily configure the AppController to use it. Just ensure the `initialViewController` is an `AppViewController`, and add Storyboard IDs for you're "logged out" and "logged in" interfaces contained in storyboard file.

```
import UIKit
import AppController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    lazy var appController: AppController = {
        return AppController(storyboardName: "Main", loggedOutInterfaceID: "<Storyboad ID of "logged out" view controller>", loggedInInterfaceID: "<Storyboad ID of "logged in" view controller>")
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // install the app controllers' root view controller as the root view controller of the window
        appController.installRootViewController(in: window!)

        return true
    }

}
```

## Author

Christian Gossain, cgossain@gmail.com

## License

AppController is available under the MIT license. See the LICENSE file for more info.
