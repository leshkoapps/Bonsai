//
//  CustomSizeController.swift
//  CustomSizeController
//
//  Created by Warif Akhand Rishi on 22/5/18.
//  Copyright © 2018 Warif Akhand Rishi. All rights reserved.
//

import UIKit

public enum Direction {
    case left, right, up, down
}

public protocol CustomSizeControllerDelegate: UIViewControllerTransitioningDelegate {
    
    /// Returns a frame for presented viewController on containerView
    ///
    /// - Parameter: containerViewFrame
    
    func frameOfPresentedView(in containerViewFrame: CGRect) -> CGRect
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController?
}

public class CustomSizeController: UIPresentationController {
    
    public var blurEffectView: UIVisualEffectView!
    public var duration: TimeInterval = 0.3
    public var springWithDamping: CGFloat = 0.8
    public var dismissDirection: Direction?
    
    var originFrame: CGRect?
    var fromDirection: Direction!
    
    weak public var sizeDelegate: CustomSizeControllerDelegate?
    
    convenience public init(presentedViewController: UIViewController, fromDirection: Direction, isDisabledTapOutside: Bool = false) {
        self.init(presentedViewController: presentedViewController, presenting: nil)
        
        self.fromDirection = fromDirection
        
        setup(presentedViewController: presentedViewController, isDisabledTapOutside: isDisabledTapOutside)
    }
    
    convenience public init(presentedViewController: UIViewController, fromOrigin: CGRect, isDisabledTapOutside: Bool = false) {
        self.init(presentedViewController: presentedViewController, presenting: nil)
        
        self.originFrame = fromOrigin
        
        setup(presentedViewController: presentedViewController, isDisabledTapOutside: isDisabledTapOutside)
    }
    
    override private init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }
    
    @objc public func dismiss() {
        presentedViewController.dismiss(animated: true, completion: nil)
    }
    
    private func setup(presentedViewController: UIViewController, isDisabledTapOutside: Bool) {
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.isUserInteractionEnabled = true
        
        if !isDisabledTapOutside {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismiss))
            blurEffectView.addGestureRecognizer(tapGestureRecognizer)
        }
        
        presentedView!.layer.masksToBounds = true
        presentedView!.layer.cornerRadius = 10
        
        presentedViewController.modalPresentationStyle = .custom
        presentedViewController.transitioningDelegate = self
    }
    
    override public var frameOfPresentedViewInContainerView: CGRect {
        return (sizeDelegate ?? self).frameOfPresentedView(in: containerView!.frame)
    }
    
    override public func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] (UIViewControllerTransitionCoordinatorContext) in
            self?.blurEffectView.alpha = 0
        }, completion: { [weak self] (UIViewControllerTransitionCoordinatorContext) in
            self?.blurEffectView.removeFromSuperview()
        })
    }
    
    override public func presentationTransitionWillBegin() {
        
        blurEffectView.alpha = 0
        blurEffectView.frame = containerView!.bounds
        containerView?.addSubview(blurEffectView)
        presentedView?.frame = frameOfPresentedViewInContainerView
        
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] (UIViewControllerTransitionCoordinatorContext) in
            self?.blurEffectView.alpha = 1
        }, completion: { (UIViewControllerTransitionCoordinatorContext) in
            
        })
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [weak self] (contx) in
            guard let `self` = self else { return }
            self.presentedView?.frame = self.frameOfPresentedViewInContainerView
            self.presentedView?.layoutIfNeeded()
        })
    }
}

extension CustomSizeController: CustomSizeControllerDelegate {
    
    public func frameOfPresentedView(in containerViewFrame: CGRect) -> CGRect {
        return CGRect(origin: CGPoint(x: 0, y: containerViewFrame.height/2), size: CGSize(width: containerViewFrame.width, height: containerViewFrame.height/2))
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return self
    }
}

extension CustomSizeController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if let sizeDelegate = sizeDelegate,  sizeDelegate.responds(to:#selector(animationController(forPresented:presenting:source:))) {
            return sizeDelegate.animationController!(forPresented: presented, presenting: presenting, source: source)
        }
        
        if let originFrame = originFrame {
            let transitioning = PopTransition(originFrame: originFrame)
            transitioning.duration = duration
            transitioning.springWithDamping = springWithDamping
            return transitioning
        } else {
            let transitioning = SlideInTransition(fromDirection: fromDirection)
            transitioning.duration = duration
            transitioning.springWithDamping = springWithDamping
            return transitioning
        }
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if let sizeDelegate = sizeDelegate,  sizeDelegate.responds(to:#selector(animationController(forDismissed:))) {
            return sizeDelegate.animationController!(forDismissed:dismissed)
        }
        
        if let originFrame = originFrame {
            let transitioning = PopTransition(originFrame: originFrame, reverse: true)
            transitioning.duration = duration
            transitioning.springWithDamping = springWithDamping
            return transitioning
        } else {
            let transitioning = SlideInTransition(fromDirection: dismissDirection ?? fromDirection, reverse: true)
            transitioning.duration = duration
            transitioning.springWithDamping = springWithDamping
            return transitioning
        }
    }
}
