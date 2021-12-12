# FirebaseIdentity

The primary motivation of this library is to make building custom UI around the Firebase Authentication
service easier on iOS for those of us that do not want to use the FirebaseUI library. 

It does this by implementing standard authentication workflows and error handling (i.e. account linking, profile 
updates, set/update password, reauthentication, enable/disable thrid-party identity providers, account deletion,
auto-retry, etc.). This is done by abstracting away a lot of the error handling logic into a singleton
state machine (called AuthManager) capable of handling most Firebase authentication use cases.

[![CI Status](https://img.shields.io/travis/cgossain/FirebaseIdentity.svg?style=flat)](https://travis-ci.org/cgossain/FirebaseIdentity)
[![Version](https://img.shields.io/cocoapods/v/FirebaseIdentity.svg?style=flat)](https://cocoapods.org/pods/FirebaseIdentity)
[![License](https://img.shields.io/cocoapods/l/FirebaseIdentity.svg?style=flat)](https://cocoapods.org/pods/FirebaseIdentity)
[![Platform](https://img.shields.io/cocoapods/p/FirebaseIdentity.svg?style=flat)](https://cocoapods.org/pods/FirebaseIdentity)

## Usage

### AuthManager

The main class you'll work with is `AuthManager`, and is intended to be used as a singleton.

The setup should be done as early as possible in the app lifecycle after initializing the Firebase library.

<pre>
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    ...
    
    // firebase
    <b>FirebaseApp.configure()</b>

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

Currently the only providers that have been implemented are `EmailIdentityProvider` and `FacebookIdentityProvider`, but you could easily subclass `IdentityProvider` to implement any other identity provider you. Feel free to submit a pull request if you implement other ones :)

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
fbLoginManager.logIn(permissions: requestedPermissions, from: self) { (result, error) in
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
 
There are many other examples included in the demo project that you should check out.

### AuthManagerReauthenticating

There are some user profile changes in Firebase that require a recent login. In particular, Firebase will trigger the `FIRAuthErrorCodeRequiresRecentLogin = 17014,` error in these situations.

This library handles this error via the `AuthManagerReauthenticating` protocol. 

Given that a user may have multiple identity providers linked to their account, this protocol is used to offload the decision of which one to use for reauthentication. One way to implement this could be by simply presenting UI to the user asking them to reauthenticate using one of the given identity providers (further offloading the decision to the user). Alternatively, you could implement by simply asking for reauthentication from the highest priority identify provider.

As an added bonus, this library also locally caches the last user sign in date and will optimistically request reauthentication if more that 5 minutes (the currently documented Firebase recent sign in threshhold) have elapsed since the last sign in. The benefit of caching this locally is that we can avoid an additional network request that we know will generate the `17014` error anyways (slightly speeds things up from the users perspective).

Keep in mind that reauthentication only applies when a user is already signed in, so a good place to implement this protocol would be on a view controller that provides UI related to account management. For example,

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

This is implemented in the `SignedInViewController` in the included demo project.

### Account Deletion

You may want to provide your users the ability to delete their own account.

This library facilitates this by providing the `DeleteAccountOperation`.

To delete a users' account:

```
...

// optionally provide database refs to delete (i.e. user scoped refs); these will be deleted before the account is deleted
let userRefs: [DatabaseReference]? = [userRef1, userRef2, ...]

// create a new op instance
let deleteAccountOp = DeleteAccountOperation(refs: userRefs)
deleteAccountOp.deleteAccountCompletionBlock = { [unowned self] (result) in
    DispatchQueue.main.async {
        switch result {
        case .success(let user):
            // post account deletion (i.e. show login screen, track event, etc.)

        case .failure(let error):
            switch error {
            case .cancelledByUser:
                break
            case .other(let msg):
                // show alert
            }
        }
    }
}

// pass the op to the AuthManager
AuthManager.shared.deleteAccount(with: deleteAccountOp)

...

```


## Example

The included demo project showcases the full functionality of this library.

### Prerequisites

To run the demo project, clone the repo, and run `pod install` from the Example directory first.

You'll also need a Firebase account. From your Firebase account, follow the instructions to create a demo project and add an iOS app to it. You'll then need to download its corresponding `GoogleService-Info.plist` file and add it the demo project in Xcode. The Firebase framework automatically detects this file when the app launches and will configure the environment accordingly.

## Requirements

- iOS 12.4+
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
