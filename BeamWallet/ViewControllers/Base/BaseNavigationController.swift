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

extension UINavigationController {
    func popViewControllers(viewsToPop: Int, animated: Bool = true) {
        if viewControllers.count > viewsToPop {
            let vc = viewControllers[viewControllers.count - viewsToPop - 1]
            popToViewController(vc, animated: animated)
        }
    }
}

class NavigationPopTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to) else {
            return
        }
        
        let containerView = transitionContext.containerView
        containerView.insertSubview(toViewController.view, belowSubview: fromViewController.view)
        
        toViewController.view.frame = CGRect(x: -100, y: toViewController.view.frame.origin.y, width: fromViewController.view.frame.size.width , height: fromViewController.view.frame.size.height)
        
        let dimmingView = UIView(frame: CGRect(x: 0, y: 0, width: toViewController.view.frame.width, height: toViewController.view.frame.height))
        dimmingView.backgroundColor = .black
        dimmingView.alpha = 0.7
        
        toViewController.view.addSubview(dimmingView)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: .curveLinear,
                       animations: {
                        
                        dimmingView.alpha = 0
                        toViewController.view.frame = transitionContext.finalFrame(for: toViewController)
                        fromViewController.view.frame = CGRect(x: toViewController.view.frame.size.width, y: fromViewController.view.frame.origin.y, width: fromViewController.view.frame.size.width, height: fromViewController.view.frame.size.height)
                        
                       }) { finished in
            
            dimmingView.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            
        }
    }
    
}

class BaseNavigationController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
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
    
    
    public var enableSwipeToDismiss = true {
        didSet{
            if !enableSwipeToDismiss {
                self.delegate = nil
            }
            else {
                self.delegate = self
            }
        }
    }
    
    var gesture:UIPanGestureRecognizer? = nil
    var interactivePopTransition: UIPercentDrivenInteractiveTransition!
    
    override func viewDidLoad() {
        self.delegate = self
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        addPanGesture(viewController)
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if operation == .pop {
            return NavigationPopTransition()
        }else{
            return nil
        }
        
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if animationController.isKind(of: NavigationPopTransition.self) {
            return interactivePopTransition
        }else{
            return nil
        }
    }
    
    private func addPanGesture(_ viewController: UIViewController){
        gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanRecognizer(recognizer:)))
//        gesture?.delegate = self
//        viewController.view.addGestureRecognizer(gesture!)
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let top = UIApplication.getTopMostViewController() {
            if top is WalletViewController {
                return false
            }
            else if top is SettingsViewController {
                return false
            }
            else if top is AddressesViewController {
                return false
            }
            else if top is DAOAppsViewController {
                return false
            }
            else if top is NotificationsViewController {
                return false
            }
            else if top is DAOViewController {
                if let dao = top as? DAOViewController {
                    if dao.app.name.uppercased() == "BEAMX DAO" {
                        return false
                    }
                }
            }
        }
        return true
    }
    
    @objc func handlePanRecognizer(recognizer: UIPanGestureRecognizer){
        if enableSwipeToDismiss {
            var progress = recognizer.translation(in: self.view).x / self.view.bounds.size.width
            progress = min(1, max(0, progress))
            if recognizer.state == .began {
                self.interactivePopTransition = UIPercentDrivenInteractiveTransition()
                self.popViewController(animated: true)
            }else if recognizer.state == .changed {
                interactivePopTransition.update(progress)
            }else if recognizer.state == .ended || recognizer.state == .cancelled {
                if progress > 0.2 {
                    interactivePopTransition.finish()
                }else{
                    interactivePopTransition.cancel()
                }
                interactivePopTransition = nil
            }
        }
    }
}
