# FirebaseIdentity

[![CI Status](https://img.shields.io/travis/cgossain/FirebaseIdentity.svg?style=flat)](https://travis-ci.org/cgossain/FirebaseIdentity)
[![Version](https://img.shields.io/cocoapods/v/FirebaseIdentity.svg?style=flat)](https://cocoapods.org/pods/FirebaseIdentity)
[![License](https://img.shields.io/cocoapods/l/FirebaseIdentity.svg?style=flat)](https://cocoapods.org/pods/FirebaseIdentity)
[![Platform](https://img.shields.io/cocoapods/p/FirebaseIdentity.svg?style=flat)](https://cocoapods.org/pods/FirebaseIdentity)

## Introduction

The primary goal of the FirebaseIdentity library is to streamline the handling of all the Firebase errors that may come up during the various user authentication lifecycle flows (i.e. sign up, sign in, account linking, account unlinking, email update, password update, reauthentication, account deletion, etc.) and to even provide automatic retry functionality in some cases. This is done by abstracting away a lot of the error handling logic into a singleton state machine ('AuthManager') cabable of handling most Firebase authentication use cases.

## Usage

### AuthManager Singleton

The primary class you need to work with is `AuthManager`.

The setup should be done early in the app lifecycle, but after initializing the Firebase library.

<pre>
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ...
    
    // firebase
    FirebaseApp.configure()

    // facebook
    ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    
    // configure other auth providers as needed
    ...

    // auth manager
    <b>AuthManager.configure()</b>

    // observer auth state
    // the auth manager state changes as the Firebase authentication state changes; by listening to this state change 
    // you can appropriately update your UI
    authenticationStateObserver =
        NotificationCenter.default.addObserver(forName: AuthManager.authenticationStateChangedNotification, object: nil, queue: .main, using: { (note) in
            guard let manager = note.object as? AuthManager else {
                return
            }

            switch manager.authenticationState {
            case .authenticated:
                AppController.login()
            case .notDetermined, .notAuthenticated:
                AppController.logout()
            }
        })
        
    ...
    
    return true
}
</pre>

### IdentityProvider

Sign-in providers are modelled by the `IdentityProvider` class. 

Currently only `EmailIdentityProvider` and `FacebookIdentityProvider` are implemented, but you could easily subclass `IdentityProvider` to implement any other provider. Feel free to submit a pull request if you implement other ones :)

To sign up a new user using email authentication:
```
let provider = EmailIdentityProvider(email: user.email, password: user.password)
AuthManager.shared.signUp(with: provider) { (result) in
    switch result {
    case .success(let value):
        print(value)

    case .failure(let error):
        self.showAuthenticationErrorAlert(for: error)
    }
}
```

To sign up/in a user with Facebook authentication:
```
let requestedPermissions: [String] = ["email"]
self.fbLoginManager.logIn(permissions: requestedPermissions, from: self) { (result, error) in
    guard let result = result, !result.isCancelled else {
        if let error = error {
            print(error.localizedDescription)
            self.showAlert(for: error)
        }
        return
    }

    let token = AccessToken.current!.tokenString
    let provider = FaceboookIdentityProvider(accessToken: token)
    AuthManager.shared.signUp(with: provider) { (result) in
        switch result {
        case .success(let value):
            print(value)

        case .failure(let error):
            self.showAuthenticationErrorAlert(for: error)
        }
    }
}
```

There are many other examples included in the sample application that you should check out.

### Reauthentication

There are some user profile changes in Firebase that require a recent login. In particular Firebase will trigger the `FIRAuthErrorCodeRequiresRecentLogin = 17014,` error in these situation.

This library handles this error via the `AuthManagerReauthenticating` protocol. 

However as an added bonus, this library also tracks the last user sign in time and will optimistically request reauthentication if more that 5 minutes have elapsed since the last sign in (5 minutes matches the currently documented Firebase recent sign in threshhold). The benifit of tracking this locally is that we can avoid an additional network request that we know will generate this error anyways.

Reauthentication only applies when a user is already signed in so a good place to implement this protocol would be on a view controller that provides the account profile change UI. For example,

```
extension AccountViewController: AuthManagerReauthenticating {
    func authManager(_ manager: AuthManager, reauthenticateUsing providers: [IdentityProviderUserInfo], challenge: ProfileChangeReauthenticationChallenge) {
        // ask for reauthentication from the highest priority auth provider
        guard let provider = providers.first else {
            return
        }
        
        switch provider.providerID {
        case .email:
            // an email provider will always have an email associated with it, therefore it should be safe to force unwrap this value here;
            // what if there is some kind of error that causes the email to be non-existant in this scenario? Force the user to log-out, then back in?
            // it seems like it would be impossible for the email to not exist on an email auth provider
            let email = provider.email!
            
            // present UI for user to provider their current password
            let alert = UIAlertController(title: "Confirm Password", message: "Your current password is required to change your email address.\n\nCurrent Email: \(email)\nTarget Email:\(challenge.context.profileChangeType.attemptedValue)", preferredStyle: .actionSheet)
            for password in Set(AuthManager.debugEmailProviderUsers.map({ $0.password })) {
                alert.addAction(UIAlertAction(title: password, style: .default, handler: { (action) in
                    let provider = EmailIdentityProvider(email: email, password: password)
                    manager.reauthenticate(with: provider, for: challenge) { (error) in
                        guard let error = error else {
                            return
                        }
                        self.showAuthenticationErrorAlert(for: error)
                    }
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        case .facebook:
            fetchFacebookAccessTokenForReauthentication { (token) in
                guard let token = token else {
                    return
                }
                let provider = FaceboookIdentityProvider(accessToken: token)
                manager.reauthenticate(with: provider, for: challenge) { (error) in
                    guard let error = error else {
                        return
                    }
                    self.showAuthenticationErrorAlert(for: error)
                }
            }
        default:
            print("undefined provider")
        }
    }
}
```

This is implemented in the `SignedInViewController` in the included example app.

## Example

The included Example project showcases the funtionality of this library.

### Prerequisites

To run the example project, clone the repo, and run `pod install` from the Example directory first.

To run the example project you'll also need a Firebase account. Once you're account has been created, follow the instructions to create a demo project. Once your demo project has been created in your Firebase account, you'll need to download the project's corresponding `GoogleService-Info.plist` and add it the demo project. The Firebase framework automatically detects this file when the app launches, and will configure the environment accordingly.

## Requirements

- iOS 11.4+
- Swift 5+
- A Firebase account

## Installation

FirebaseIdentity is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'FirebaseIdentity'
```

## Author

cgossain, cgossain@gmail.com

## License

FirebaseIdentity is available under the MIT license. See the LICENSE file for more info.
