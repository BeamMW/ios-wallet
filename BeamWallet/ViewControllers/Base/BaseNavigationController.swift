//
// BaseNavigationController.swift
// BeamWallet
//
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit

extension UINavigationController {
    func popViewControllers(viewsToPop: Int, animated: Bool = true) {
        if viewControllers.count > viewsToPop {
            let vc = viewControllers[viewControllers.count - viewsToPop - 1]
            popToViewController(vc, animated: animated)
        }
    }
}

class BaseNavigationController: UINavigationController {
    
    public var enableSwipeToDismiss = true
    
    private lazy var sloppySwiping: NavigationSwiper = {
        return NavigationSwiper(navigationController: self)
    }()
    
    
    public static func navigationController(rootViewController:UIViewController) -> BaseNavigationController {
        let navigation = BaseNavigationController(rootViewController: rootViewController)
        navigation.navigationBar.setBackgroundImage(UIImage.fromColor(color: UIColor.main.marine), for: .default)
        navigation.navigationBar.shadowImage = UIImage()
        navigation.navigationBar.backgroundColor = UIColor.main.marine
        navigation.navigationBar.isTranslucent = false
        navigation.navigationBar.tintColor = UIColor.white
        navigation.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white , NSAttributedString.Key.font: SemiboldFont(size: 17)]
        return navigation
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        delegate = sloppySwiping
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        delegate = sloppySwiping
    }
    
    public override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(navigationBarClass: navigationBarClass, toolbarClass: toolbarClass)
        delegate = sloppySwiping
    }
    
    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        delegate = sloppySwiping
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        if(!AppDelegate.newFeaturesEnabled) {
//            if responds(to: #selector(getter: interactivePopGestureRecognizer)) {
//                interactivePopGestureRecognizer?.delegate = self
//                delegate = self
//            }
//        }
//      
//    }
//
//    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
//        if(!AppDelegate.newFeaturesEnabled) {
//            if responds(to: #selector(getter: interactivePopGestureRecognizer)) {
//                interactivePopGestureRecognizer?.isEnabled = false
//            }
//        }
//        super.pushViewController(viewController, animated: animated)
//    }
}

extension BaseNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        interactivePopGestureRecognizer?.isEnabled = (responds(to: #selector(getter: interactivePopGestureRecognizer)) && viewControllers.count > 1)
    }
}

extension BaseNavigationController: UIGestureRecognizerDelegate {
 
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if self.viewControllers.last is SendViewController {
            let touchLocation = touch.location(in: touch.window)
            if let subviews = self.viewControllers.last?.view.subviews {
                for view in subviews {
                    if view is UITableView {
                        let table = view as! UITableView
                        let converted  = table.convert(touchLocation, from: touch.window)
                        if let path = table.indexPathForRow(at: converted) {
                            if let cell = table.cellForRow(at: path) {
                                if cell is FeeCell {
                                    return false
                                }
                            }
                        }
                    }
                }
            }
            
        }
        
        return enableSwipeToDismiss
    }
}

public final class NavigationSwiper: NSObject {
    
    fileprivate weak var navigationController: UINavigationController?
    fileprivate var isInteractivelyPopping: Bool = false
    fileprivate var interactivePopAnimator: InteractivePopAnimator
    fileprivate let popRecognizer: UIPanGestureRecognizer
    
    fileprivate var isAnimatingANonInteractiveTransition: Bool = false {
        didSet {
            popRecognizer.isEnabled = !isAnimatingANonInteractiveTransition
        }
    }
    
    public init(navigationController: UINavigationController) {
        self.interactivePopAnimator = InteractivePopAnimator()
        self.popRecognizer = UIPanGestureRecognizer()
        self.navigationController = navigationController
        super.init()
        self.popRecognizer.maximumNumberOfTouches = 1
        self.popRecognizer.delegate = self
        popRecognizer.addTarget(self, action: #selector(NavigationSwiper.popRecognizerPanned(_:)))
        navigationController.view.addGestureRecognizer(popRecognizer)
    }
    
    @objc private func popRecognizerPanned(_ recognizer: UIPanGestureRecognizer) {
        
        guard let navigationController = navigationController else {return}
        guard recognizer == popRecognizer else {return}
        
        let velocity = recognizer.velocity(in: self.navigationController?.view);
        
        if let base = navigationController as? BaseNavigationController {
            if !base.enableSwipeToDismiss {
                return
            }
        }
        
        switch (recognizer.state) {
            
        case .began:
            if velocity.x < 0 {
                return
            }
            if (navigationController.viewControllers.count > 1) {
                isInteractivelyPopping = true
                                
                _ = self.navigationController?.popViewController(animated: true)
            }
        case .changed:
            if (!isAnimatingANonInteractiveTransition
                && isInteractivelyPopping) {
                let view = navigationController.view
                let t = recognizer.translation(in: view)
                interactivePopAnimator.translation = t
            }
            
        case .ended, .cancelled:
            if (!isAnimatingANonInteractiveTransition
                && isInteractivelyPopping) {
                isAnimatingANonInteractiveTransition = true
                let animator = interactivePopAnimator
                let view = navigationController.view
                let t = recognizer.translation(in: view)
                let v = recognizer.velocity(in: view)
                if animator.shouldCancelForGestureEndingWithTranslation(t, velocity: v) {
                    animator.cancelWithTranslation(t, velocity: v) {
                        self.isInteractivelyPopping = false
                        self.isAnimatingANonInteractiveTransition = false
                    }
                } else {
                    animator.finishWithTranslation(t, velocity: v) {
                        self.isInteractivelyPopping = false
                        self.isAnimatingANonInteractiveTransition = false
                    }
                }
            }
            
        default: break
            
        }
    }
}

extension NavigationSwiper : UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if let navigation = self.navigationController {
            if navigation.viewControllers.last is SendViewController {
                let touchLocation = touch.location(in: touch.window)
                if let subviews = navigation.viewControllers.last?.view.subviews {
                    for view in subviews {
                        if view is UITableView {
                            let table = view as! UITableView
                            let converted  = table.convert(touchLocation, from: touch.window)
                            if let path = table.indexPathForRow(at: converted) {
                                if let cell = table.cellForRow(at: path) {
                                    if cell is FeeCell {
                                        return false
                                    }
                                }
                            }
                        }
                    }
                }
                
            }
        }
        
        return true
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return  (self.navigationController?.viewControllers.count ?? 0 > 1)
    }
}

extension NavigationSwiper: UINavigationControllerDelegate {
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if (isInteractivelyPopping && operation == .pop) {
            return interactivePopAnimator
        }
        return nil
    }
    
    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if (isInteractivelyPopping) {
            return interactivePopAnimator
        }
        return nil
    }
    
}

fileprivate let defaultCancelPopDuration: TimeInterval = 0.16
fileprivate let maxBackViewTranslationPercentage: CGFloat = 0.30
fileprivate let minimumDismissalPercentage: CGFloat = 0.5
fileprivate let minimumThresholdVelocity: CGFloat = 100.0

fileprivate class InteractivePopAnimator: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning {
    
    var translation: CGPoint = CGPoint.zero {
        didSet {
            updateViewsWithTranslation(translation)
        }
    }
    
    private var activeContext: UIViewControllerContextTransitioning? = nil
    private var activeDuration: TimeInterval? = nil
    
    private lazy var backOverlayView: UIView = {
        let backOverlayView = UIView(frame: CGRect.zero)
        backOverlayView.backgroundColor = UIColor(white: 0.0, alpha: 0.1)
        backOverlayView.alpha = 1.0
        return backOverlayView
    }()
    
    private lazy var frontContainerView: FrontContainerView = {
        return FrontContainerView(frame: CGRect.zero)
    }()
    
    @objc func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if let duration = activeDuration {
            return duration
        }
        return 0
    }
    
    @objc func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        fatalError("this class should not be used for non-interactive transitions")
    }
    
    @objc func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        activeContext = transitionContext
        prepForPop()
    }
    
    fileprivate func shouldCancelForGestureEndingWithTranslation(_ translation: CGPoint, velocity: CGPoint) -> Bool {
        
        guard let transitionContext = activeContext else {
            return false
        }
        
        let container = transitionContext.containerView
        let percent = percentDismissedForTranslation(translation, container: container)
        
        return ((percent < minimumDismissalPercentage && velocity.x < 100.0) || velocity.x < 0)
    }
    
    fileprivate func cancelWithTranslation(_ translation: CGPoint, velocity: CGPoint, completion: @escaping () -> Void) {
        
        guard let transitionContext = activeContext,
            let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from),
            let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else {
                return
        }
        
        let container = transitionContext.containerView
        
        let maxDistance = container.bounds.size.width
        let maxToViewOffset = maxDistance * maxBackViewTranslationPercentage
        let resolvedToViewOffset = min(0, -maxToViewOffset) // Damn you, AutoLayout!
        let duration: TimeInterval
        let options: UIView.AnimationOptions
        
        if abs(velocity.x) > minimumThresholdVelocity {
            options = .curveEaseOut
            let naiveDuration = durationForDistance(distance: maxDistance, velocity: abs(velocity.x))
            let isFlickingShutEarly = translation.x < maxDistance * minimumDismissalPercentage
            if (naiveDuration > defaultCancelPopDuration && isFlickingShutEarly) {
                duration = defaultCancelPopDuration
            } else {
                duration = naiveDuration
            }
        }
        else {
            options = UIView.AnimationOptions()
            duration = defaultCancelPopDuration
        }
        
        activeDuration = duration
        
        activeContext?.cancelInteractiveTransition()
        
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: { () -> Void in
            self.frontContainerView.transform = .identity
            let translationX = resolvedToViewOffset
            toView.transform = CGAffineTransform(translationX: translationX, y: 0)
            self.backOverlayView.alpha = 1.0
            self.frontContainerView.dropShadowAlpha = 1.0
        }, completion: { completed -> Void in
            toView.transform = .identity
            container.addSubview(fromView)
            self.backOverlayView.removeFromSuperview()
            self.frontContainerView.removeFromSuperview()
            self.activeContext?.completeTransition(false)
            completion()
        })
        
    }
    
    fileprivate func finishWithTranslation(_ translation: CGPoint, velocity: CGPoint, completion: @escaping () -> Void) {
        
        guard let transitionContext = activeContext,
            let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from),
            let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else {
                return
        }
        
        let container = transitionContext.containerView
        
        let maxDistance = container.bounds.size.width
        let duration: TimeInterval
        
        var comfortVelocity = velocity
        comfortVelocity.x *= 2.0
        
        let options: UIView.AnimationOptions
        if abs(comfortVelocity.x) > 0 {
            options = .curveEaseOut
            duration = durationForDistance(distance: maxDistance, velocity: abs(comfortVelocity.x))
        }
        else {
            options = UIView.AnimationOptions()
            duration = defaultCancelPopDuration
        }
        
        activeDuration = duration
        
        activeContext?.finishInteractiveTransition()
        
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: { () -> Void in
            let translationX = maxDistance
            self.frontContainerView.transform = CGAffineTransform(
                translationX: translationX, y: 0
            )
            toView.transform = .identity
            self.backOverlayView.alpha = 0.0
            self.frontContainerView.dropShadowAlpha = 0.0
        }, completion: { completed -> Void in
            fromView.removeFromSuperview()
            self.frontContainerView.transform = .identity
            self.frontContainerView.removeFromSuperview()
            self.backOverlayView.removeFromSuperview()
            self.activeContext?.completeTransition(true)
            completion()
        })
        
    }
    
    private func prepForPop() {
        
        guard let transitionContext = activeContext,
            let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from),
            let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else {
                return
        }
        
        let container = transitionContext.containerView
        let containerBounds = container.bounds
        
        frontContainerView.frame = containerBounds
        
        let maxOffset = containerBounds.size.width * maxBackViewTranslationPercentage
        
        fromView.frame = frontContainerView.bounds
        frontContainerView.addSubview(fromView)
        frontContainerView.transform = CGAffineTransform.identity
        
        toView.frame = containerBounds
        let translationX = -maxOffset
        toView.transform = CGAffineTransform(translationX: translationX, y: 0)
        
        backOverlayView.frame = containerBounds
        
        container.addSubview(toView)
        container.addSubview(backOverlayView)
        container.addSubview(frontContainerView)
    }
    
    private func updateViewsWithTranslation(_ translation: CGPoint) {
        
        guard let transitionContext = activeContext,
            let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else {
                return
        }
        
        let container = transitionContext.containerView
        let maxDistance = container.bounds.size.width
        let percent = percentDismissedForTranslation(translation, container: container)
        
        let maxFromViewOffset = maxDistance
        
        let maxToViewOffset = maxDistance * maxBackViewTranslationPercentage
        let frontTranslationX = maxFromViewOffset * percent
        let resolvedToViewOffset = -maxToViewOffset + (maxToViewOffset * percent)
        let backTranslationX =  resolvedToViewOffset
        
        frontContainerView.transform = CGAffineTransform(translationX: frontTranslationX, y: 0)
        frontContainerView.dropShadowAlpha = (1.0 - percent)
        toView.transform = CGAffineTransform(translationX: backTranslationX, y: 0)
        backOverlayView.alpha = (1.0 - percent)
        
        activeContext?.updateInteractiveTransition(percent)
    }
    
    private func percentDismissedForTranslation(_ translation: CGPoint, container: UIView) -> CGFloat {
        let maxDistance = container.bounds.size.width
        return (min(maxDistance, max(0, translation.x))) / maxDistance
    }
    
    private func durationForDistance(distance d: CGFloat, velocity v: CGFloat) -> TimeInterval {
        let minDuration: CGFloat = 0.08
        let maxDuration: CGFloat = 0.4
        return (TimeInterval)(max(min(maxDuration, d / v), minDuration))
    }
    
}

fileprivate class FrontContainerView: UIView {
    
    var dropShadowAlpha: CGFloat = 1 {
        didSet { dropShadowView.alpha = dropShadowAlpha }
    }
    
    private lazy var dropShadowView: UIView = {
        let w: CGFloat = 10.0
        
        let stretchableShadow = UIImageView(frame: CGRect(x: 0, y: 0, width: w, height: 1))
        stretchableShadow.backgroundColor = UIColor.clear
        stretchableShadow.alpha = 1.0
        stretchableShadow.contentMode = .scaleToFill
        stretchableShadow.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        
        let contextSize = CGSize(width: w, height: 1)
        UIGraphicsBeginImageContextWithOptions(contextSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colors: [CGColor] = [
            UIColor(white: 0.0, alpha: 0.000).cgColor,
            UIColor(white: 0.0, alpha: 0.045).cgColor,
            UIColor(white: 0.0, alpha: 0.090).cgColor,
            UIColor(white: 0.0, alpha: 0.135).cgColor,
            UIColor(white: 0.0, alpha: 0.180).cgColor,
        ]
        let locations: [CGFloat] = [0.0, 0.34, 0.60, 0.80, 1.0]
        let orientedLocations = locations
        let options = CGGradientDrawingOptions()
        if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: orientedLocations) {
            context?.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: w, y: 0), options: options)
            stretchableShadow.image = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        
        return stretchableShadow
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialization()
    }
    
    private func initialization() {
        var dropShadowFrame = dropShadowView.frame
        dropShadowFrame.origin.x = 0 - dropShadowFrame.size.width
        dropShadowFrame.origin.y = 0
        dropShadowFrame.size.height = bounds.size.height
        dropShadowView.frame = dropShadowFrame
        addSubview(dropShadowView)
        clipsToBounds = false
        backgroundColor = UIColor.clear
    }
}


