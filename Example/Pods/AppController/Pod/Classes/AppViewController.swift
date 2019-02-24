//
// AppViewController.swift
//
// Copyright (c) 2017 Christian Gossain
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

fileprivate let transitionSnapshotTag = 1999

open class AppViewController: UIViewController {
    
    /// The view controller that is currently installed.
    open fileprivate(set) var installedViewController: UIViewController?
    
    
    // MARK: - Overrides
    
    open override var childForStatusBarStyle : UIViewController? {
        return installedViewController
    }
    
    open override var childForStatusBarHidden : UIViewController? {
        return installedViewController
    }
    
    open override var shouldAutorotate: Bool {
        return installedViewController?.shouldAutorotate ?? super.shouldAutorotate
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return installedViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return installedViewController?.preferredInterfaceOrientationForPresentation ?? super.preferredInterfaceOrientationForPresentation
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // force the window snapshot to stay on top; this is useful when other subviews are added during the transition (i.e. a presentation, split view master panel in portrait mode, etc.)
        if let snapshot = view.window?.viewWithTag(transitionSnapshotTag) {
            view.window?.bringSubviewToFront(snapshot)
        }
    }
}

extension AppViewController {
    /// Transitions from the currently installed view controller to the specified view controller. If no view controller is installed, then this method simply loads the specified view controller.
    ///
    /// - Parameter toViewController: The view controller to transition to.
    /// - Parameter configuration: The configuration model containing details on the transition.
    /// - Parameter willBeginTransition: A block that is called just before the transition actually begins (i.e. after internally dismissing a presented view controller, but before the transition)
    /// - Parameter completionHandler: A block to be executed after the transition completes.
    open func transition(to toViewController: UIViewController, configuration: AppController.Configuration, willBeginTransition: (() -> Void)? = nil, completionHandler: (() -> Void)?) {
        // prevent adding the view controller if it's already our child
        if toViewController.parent == self {
            return
        }
        
        // notify the transition will begin
        willBeginTransition?()
        
        // if there is an installed view controller, we'll need to transition from it; otherwise just contain the to view controller immediately
        if let fromViewController = installedViewController {
            guard let keyWindow = UIApplication.shared.keyWindow else {
                return
            }
            
            if configuration.dismissesPresentedViewControllerOnTransition {
                transitionBySnapshotting(from: fromViewController, to: toViewController, in: keyWindow, duration: configuration.transitionDuration, delay: configuration.transitionDelay, completionHandler: completionHandler)
            }
            else {
                transitionWithoutDismissingPresentedViewController(from: fromViewController, to: toViewController, in: keyWindow, duration: configuration.transitionDuration, delay: configuration.transitionDelay, completionHandler: completionHandler)
            }
        }
        else {
            transitionWithoutAnimation(toViewController: toViewController, completionHandler: completionHandler)
        }
    }
}

fileprivate extension AppViewController {
    
    /// Technique #1: Transition is performed by resigning first responder, then snapshotting the entire window. The snapshot is placed on top of all other window subviews while
    /// the underlying hierarchy is changed. Finally the snapshot is faded out, and removed to reveal the updated view hierarchy.
    func transitionBySnapshotting(from fromViewController: UIViewController, to toViewController: UIViewController, in window: UIWindow, duration: TimeInterval, delay: TimeInterval, completionHandler: (() -> Void)?) {
        // resign any active first responder before continuing
        window.resignCurrentFirstResponderIfNeeded {
            
            // take a snapshot of the window state
            let snapshot = window.snapshotView(afterScreenUpdates: false)
            snapshot?.tag = transitionSnapshotTag
            
            // cover the window with the snapshot
            if let snapshot = snapshot {
                window.addSubview(snapshot)
            }
            
            // hide all transition views immediately
            let presentedTransitionViews = window.subviewsWithClassName("UITransitionView")
            presentedTransitionViews.forEach { $0.isHidden = true }
            
            let performTransition = {
                // notify the `fromViewController` is about to be removed
                fromViewController.willMove(toParent: nil)
                
                // add the `toViewController` as a child
                self.addChild(toViewController)
                self.view.addSubview(toViewController.view)
                
                // fill the bounds
                toViewController.view.translatesAutoresizingMaskIntoConstraints = false
                toViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
                toViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
                toViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
                toViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
                
                // update the current reference (needs to be updated for the `setNeedsStatusBarAppearanceUpdate()` call in the animation block)
                self.installedViewController = toViewController
                
                // decontain the `fromViewController`
                fromViewController.view.removeFromSuperview()
                fromViewController.removeFromParent()
                
                // finish containing the `toViewController`
                toViewController.didMove(toParent: self)
                
                // fade out the snapshot to reveal the `toView`; note that the small animation delay allows dismissed presented views to be removed and the hieararchy ready to go before fading out the screenshot view
                UIView.animate(withDuration: duration, delay: delay, options: .transitionCrossDissolve, animations: {
                    // fade out the snapshot to reveal the update hierarchy
                    snapshot?.alpha = 0.0
                    
                    // updating the status bar appearance change within the animation block will animate the status bar color change, if there is one
                    self.setNeedsStatusBarAppearanceUpdate()
                    
                }, completion: { (finished) in
                    // remove the snapshot
                    snapshot?.removeFromSuperview()
                    
                    // completion handler
                    completionHandler?()
                })
            }
            
            if self.presentedViewController != nil {
                // dismiss the entire presented view controller hierarchy without animation, performing the transition upon completion
                // to ensure any presented controllers relationships are severed before transitioning
                self.dismiss(animated: false, completion: performTransition)
            }
            else {
                // no view controller has been presented, so the transition can be performed immediately
                performTransition()
            }
        }
    }
    
    /// Technique #2: Transition keeps the topmost UITransitionView visible, but hides all other ones (i.e. when there are multiple presentations overlayed). The topmost UITransitionView is faded out as the `toView` is faded in.
    func transitionByDismissing(from fromViewController: UIViewController, to toViewController: UIViewController, in window: UIWindow, duration: TimeInterval, delay: TimeInterval, completionHandler: (() -> Void)?) {
        // resign any active first responder before continuing
        window.resignCurrentFirstResponderIfNeeded {
            
            // notify the `fromViewController` is about to be removed
            fromViewController.willMove(toParent: nil)
            
            // add the `toViewController` as a child
            self.addChild(toViewController)
            toViewController.view.alpha = 0.0
            self.view.addSubview(toViewController.view)
            
            // fill the bounds
            toViewController.view.translatesAutoresizingMaskIntoConstraints = false
            toViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
            toViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
            toViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
            toViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
            
            // get all transition views (the container views of all presentations)
            let presentedTransitionViews = window.subviewsWithClassName("UITransitionView")
            
            // get the topmost presented view
            let topmostPresentedView = presentedTransitionViews.last
            
            // hide intermediate presented views immediately
            let intermediatePresentedViews = presentedTransitionViews.filter { $0 != topmostPresentedView }
            intermediatePresentedViews.forEach { $0.isHidden = true }
            
            // update the current reference (needs to be updated for the `setNeedsStatusBarAppearanceUpdate()` call in the animation block)
            self.installedViewController = toViewController
            
            // fade out the snapshot to reveal the `toView`; note that the small animation delay allows dismissed presented views to be removed and the hieararchy ready to go before fading out the screenshot view
            UIView.animate(withDuration: duration, delay: delay, options: .curveEaseIn, animations: {
                // fade out the topmost presented view
                topmostPresentedView?.alpha = 0.0
                
                // fade in the `toView`
                toViewController.view.alpha = 1.0
                
                // updating the status bar appearance change within the animation block will animate the status bar color change, if there is one
                self.setNeedsStatusBarAppearanceUpdate()
                
            }, completion: { (finished) in
                // dismiss the entire presented view controller hierarchy without animation
                self.dismiss(animated: false, completion: nil)
                
                // remove all presented views if they haven't alerady been removed
                presentedTransitionViews.forEach { $0.removeFromSuperview() }
                
                // decontain the `fromViewController`
                fromViewController.view.removeFromSuperview()
                fromViewController.removeFromParent()
                
                // finish containing the `toViewController`
                toViewController.didMove(toParent: self)
                
                // completion handler
                completionHandler?()
            })
            
        }
    }
    
    /// Immediately contains the specified view controller. This method will not perform a transition and does not decontain other child view controllers.
    func transitionWithoutAnimation(toViewController: UIViewController, completionHandler: (() -> Void)?) {
        // add the new controller as a child
        addChild(toViewController)
        view.addSubview(toViewController.view)
        
        // fill the bounds
        toViewController.view.translatesAutoresizingMaskIntoConstraints = false
        toViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        toViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        toViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        toViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        
        // set the current view controller
        installedViewController = toViewController
        
        // update status bar appearance
        setNeedsStatusBarAppearanceUpdate()
        
        // simply finish containing the view controller
        toViewController.didMove(toParent: self)
        
        // completion handler
        completionHandler?()
    }
    
    /// Transitions between the specified view controllers without dismissing presented view controllers.
    func transitionWithoutDismissingPresentedViewController(from fromViewController: UIViewController, to toViewController: UIViewController, in window: UIWindow, duration: TimeInterval, delay: TimeInterval, completionHandler: (() -> Void)?) {
        // notify the `fromViewController` is about to be removed
        fromViewController.willMove(toParent: nil)
        
        // add the `toViewController` as a child
        self.addChild(toViewController)
        toViewController.view.alpha = 0.0
        self.view.addSubview(toViewController.view)
        
        // fill the bounds
        toViewController.view.translatesAutoresizingMaskIntoConstraints = false
        toViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        toViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        toViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        toViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        
        // update the current reference (needs to be updated for the `setNeedsStatusBarAppearanceUpdate()` call in the animation block)
        self.installedViewController = toViewController
        
        // fade out the snapshot to reveal the `toView`; note that the small animation delay allows dismissed presented views to be removed and the hieararchy ready to go before fading out the screenshot view
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseIn, animations: {
            // fade in the `toView`
            toViewController.view.alpha = 1.0
            
            // updating the status bar appearance change within the animation block will animate the status bar color change, if there is one
            self.setNeedsStatusBarAppearanceUpdate()
            
        }, completion: { (finished) in
            // decontain the `fromViewController`
            fromViewController.view.removeFromSuperview()
            fromViewController.removeFromParent()
            
            // finish containing the `toViewController`
            toViewController.didMove(toParent: self)
            
            // completion handler
            completionHandler?()
        })
    }
}

fileprivate extension UIView {
    var currentFirstResponder: UIView? {
        if isFirstResponder {
            return self
        }
        else {
            for subview in subviews {
                if let firstResponder = subview.currentFirstResponder {
                    return firstResponder
                }
            }
        }
        
        return nil
    }
    
    func resignCurrentFirstResponderIfNeeded(completionHandler: @escaping () -> Void) {
        if let firstResponder = currentFirstResponder {
            firstResponder.resignFirstResponder()
            
            // allow keyboard to be fully dismissed before continuing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                completionHandler()
            }
        }
        else {
            completionHandler()
        }
    }
    
    func subviewsWithClassName(_ aClassName: String) -> [UIView] {
        return subviews.filter { $0.classForCoder == NSClassFromString(aClassName) }
    }
}
