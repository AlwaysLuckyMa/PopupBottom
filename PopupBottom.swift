//
//  PopupBottom.swift
//  PopupBottom
//
//  Created by Matsonga on 2024/10/16.
//

import UIKit

public protocol PopupBottomVCProtocol {
    var isCurrentViewHeight: CGFloat { get }
    var isAddGestures: Bool { get }
    var isShowBlackView: Bool { get }
}

public class PopupBottomVC: UIViewController, PopupBottomVCProtocol, PopupDismissDelegate {
    public var isCurrentViewHeight: CGFloat { UIScreen.main.bounds.height }
    public var isAddGestures: Bool { true }
    public var isShowBlackView: Bool { true }

    /// present 结束后执行
    public func popPresentedEnd() {}
    /// 回调里 end 结束 立刻执行
    public func popPanEnd() { }
    /// 回调里 change 立刻执行
    /// - Parameter point: 添加视图后转换的 point
    public func popPanChange(_ point: CGPoint) { }

    /// 隐藏弹出视图
    func popupBottomHiddenVC() {
        dismiss(animated: true, completion: nil)
    }

    /// 隐藏弹出视图
    /// - Parameter completion: 回调
    func popupBottomHiddenVC(completion: (() -> Void)?) {
        dismiss(animated: true) {
            completion?()
        }
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

public protocol PopupDismissDelegate: AnyObject {
    func popPresentedEnd()
    func popPanChange(_ point: CGPoint)
    func popPanEnd()
}

public class PopupBottom: UIPresentationController {
    weak var dismissDelegate: PopupDismissDelegate?
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

    public var isCurrentViewHeight: CGFloat
    public var isAddGestures: Bool
    public var isShowBlackView: Bool

    override public init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        if let vc = presentedViewController as? PopupBottomVC {
            tempVC = vc
            isCurrentViewHeight = vc.isCurrentViewHeight
            isAddGestures = vc.isAddGestures
            isShowBlackView = vc.isShowBlackView
            dismissDelegate = vc
        } else {
            tempVC = presentedViewController
            isCurrentViewHeight = UIScreen.main.bounds.width
            isAddGestures = true
            isShowBlackView = true
            dismissDelegate = presentedViewController as? PopupBottomVC
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
        var newCenter = CGPoint(x: recognizer.view!.center.x, y: recognizer.view!.center.y + translation.y)
        switch recognizer.state {
        case .changed:
            newCenter.y = max(inSCREEN_HEIGHT - isCurrentViewHeight + recognizer.view!.frame.size.height / 2,
                              newCenter.y)

            tempVC?.view?.frame = CGRect(x: 0,
                                         y: newCenter.y - isCurrentViewHeight,
                                         width: inSCREEN_WIDTH,
                                         height: isCurrentViewHeight)
            recognizer.view!.center = newCenter
            recognizer.setTranslation(.zero, in: tempVC?.view)
            popPanChange(newCenter)
            break
        case .ended:
            popPanEnd()
            if newCenter.y < (inSCREEN_HEIGHT - isCurrentViewHeight + recognizer.view!.frame.size.height / 2 + 100) {
                UIView.animate(withDuration: 0.25) { [weak self] in
                    self?.tempVC?.view.frame = CGRect(x: 0,
                                                      y: (self?.inSCREEN_HEIGHT ?? 0) - (self?.isCurrentViewHeight ?? 0),
                                                      width: self?.inSCREEN_WIDTH ?? 0,
                                                      height: self?.isCurrentViewHeight ?? 0)
                }
            } else {
                UIView.animate(withDuration: 0.25) { [weak self] in
                    self?.tempVC?.view.frame = CGRect(x: 0,
                                                      y: self?.inSCREEN_HEIGHT ?? 0,
                                                      width: self?.inSCREEN_WIDTH ?? 0,
                                                      height: self?.isCurrentViewHeight ?? 0)
                } completion: { [weak self] _ in
                    self?.tempVC?.view.removeFromSuperview()
                    self?.blackView.removeFromSuperview()
                    self?.sendDismissController()
                }
            }
            break
        default:
            break
        }
    }

    override public var frameOfPresentedViewInContainerView: CGRect {
        return CGRect(x: 0, y: UIScreen.main.bounds.height - isCurrentViewHeight, width: UIScreen.main.bounds.width, height: isCurrentViewHeight)
    }

    @objc public func sendDismissController() {
        presentedViewController.dismiss(animated: true) { [weak self] in
            self?.dismissDelegate?.popPresentedEnd()
        }
    }

    public func popPanChange(_ point: CGPoint) {
        dismissDelegate?.popPanChange(point)
    }

    public func popPanEnd() {
        dismissDelegate?.popPanEnd()
    }
}
