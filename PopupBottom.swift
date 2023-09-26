//
//  PopupBottom.swift
//  PopupBottom
//
//  Created by AlwaysLuckyMa on 2023/01/03.
//

import UIKit

public class PopupBottom: UIPresentationController {
    private let inSCREEN_WIDTH = UIScreen.main.bounds.size.width
    private let inSCREEN_HEIGHT = UIScreen.main.bounds.size.height
    private var tempVC: UIViewController?

    private lazy var blackView: UIButton = {
        let backgroundBtn = UIButton()
        backgroundBtn.frame = CGRect(x: 0, y: 0, width: inSCREEN_WIDTH, height: inSCREEN_HEIGHT)
        backgroundBtn.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        backgroundBtn.alpha = 0
        backgroundBtn.addTarget(self, action: #selector(sendDismissController), for: .touchUpInside)
        return backgroundBtn
    }()

    public var currentViewHeight: CGFloat
    public var isAddGestures: Bool
    public var isShowBlackView: Bool

    override public init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        if let vc = presentedViewController as? PopupBottomVC {
            tempVC = vc
            currentViewHeight = vc.currentViewHeight
            isAddGestures = vc.isAddGestures
            isShowBlackView = vc.isShowBlackView
        } else {
            tempVC = presentedViewController
            currentViewHeight = UIScreen.main.bounds.width
            isAddGestures = true
            isShowBlackView = true
        }

        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
    }

    override public func presentationTransitionWillBegin() {
        if isShowBlackView {
            blackView.alpha = 0
            containerView?.addSubview(blackView)
            UIView.animate(withDuration: 0.25) { [weak self] in
                self?.blackView.alpha = 1
            }
        }
    }

    override public func presentationTransitionDidEnd(_ completed: Bool) {
        if isAddGestures {
            let tap = UIPanGestureRecognizer(target: self, action: #selector(onTap(recognizer:)))
            presentedViewController.view.addGestureRecognizer(tap)
        }
    }

    override public func dismissalTransitionWillBegin() {
        if isShowBlackView {
            UIView.animate(withDuration: 0.5) { [weak self] in
                self?.blackView.alpha = 0
            }
        }
    }

    override public func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            if isShowBlackView {
                blackView.removeFromSuperview()
            }
        }
    }

    @objc func onTap(recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: tempVC?.view)
        var newCenter = CGPoint(x: (recognizer.view?.center.x)!, y: (recognizer.view?.center.y)! + translation.y)
        switch recognizer.state {
        case .changed:
            newCenter.y = max(inSCREEN_HEIGHT - currentViewHeight + recognizer.view!.frame.size.height / 2, newCenter.y)
            tempVC?.view?.frame = CGRect(x: 0, y: newCenter.y - currentViewHeight, width: inSCREEN_WIDTH, height: currentViewHeight)
            recognizer.view!.center = newCenter
            recognizer.setTranslation(.zero, in: tempVC?.view)
            break
        case .ended:
            if newCenter.y < (inSCREEN_HEIGHT - currentViewHeight + recognizer.view!.frame.size.height / 2 + 100) {
                UIView.animate(withDuration: 0.25) { [self] in
                    tempVC?.view.frame = CGRect(x: 0, y: inSCREEN_HEIGHT - currentViewHeight, width: inSCREEN_WIDTH, height: currentViewHeight)
                }
            } else {
                UIView.animate(withDuration: 0.25) { [self] in
                    tempVC?.view.frame = CGRect(x: 0, y: inSCREEN_HEIGHT, width: inSCREEN_WIDTH, height: currentViewHeight)
                } completion: { [self] _ in
                    tempVC?.view.removeFromSuperview()
                    blackView.removeFromSuperview()
                    sendDismissController()
                }
            }
            break
        default:
            break
        }
    }

    override public var frameOfPresentedViewInContainerView: CGRect {
        return CGRect(x: 0, y: UIScreen.main.bounds.height - currentViewHeight, width: UIScreen.main.bounds.width, height: currentViewHeight)
    }

    @objc public func sendDismissController() {
        presentedViewController.dismiss(animated: true, completion: nil)
    }
}

extension UIViewController: UIViewControllerTransitioningDelegate {
    public func popupBottomVC(_ vc: PopupBottomVC) {
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self
        present(vc, animated: true) { [weak vc] in
            vc?.transitioningDelegate = nil
        }
    }

    public func popupBottomVC(_ vc: PopupBottomVC, completion: (() -> Void)?) {
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self
        present(vc, animated: true) { [weak vc] in
            vc?.transitioningDelegate = nil
            completion?()
        }
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PopupBottom(presentedViewController: presented, presenting: presenting)
    }
}

public protocol PopupBottomVCProtocol {
    var currentViewHeight: CGFloat { get }
    var isAddGestures: Bool { get }
    var isShowBlackView: Bool { get }
}

public class PopupBottomVC: UIViewController, PopupBottomVCProtocol {
    public var currentViewHeight: CGFloat { UIScreen.main.bounds.height }
    public var isAddGestures: Bool { true }
    public var isShowBlackView: Bool { true }
    func hiddenPopupBottomVC() {
        dismiss(animated: true, completion: nil)
    }
}
