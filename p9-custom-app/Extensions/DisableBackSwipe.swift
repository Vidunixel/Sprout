//
//  DisableBackSwipe.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 18/10/2026.
//

import SwiftUI
import UIKit

extension View {
    @ViewBuilder
    func disableBackSwipe(_ disable: Bool = true) -> some View {
        if disable {
            self.background(
                DisableBackSwipeRepresentable()
                    .frame(width: 0, height: 0)
            )
        } else {
            self
        }
    }
}

private struct DisableBackSwipeRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> DisableBackSwipeViewController {
        DisableBackSwipeViewController()
    }

    func updateUIViewController(_ uiViewController: DisableBackSwipeViewController, context: Context) {}
}

private final class DisableBackSwipeViewController: UIViewController {
    private struct LockedGesture {
        let gesture: UIGestureRecognizer
        let observation: NSKeyValueObservation
    }

    private var locked: [ObjectIdentifier: LockedGesture] = [:]
    private var isActive = false

    override func loadView() {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        self.view = view
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        isActive = true
        lockGestures()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lockGestures()
        // Catch gestures added after the transition ends.
        DispatchQueue.main.async { [weak self] in self?.lockGestures() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isActive { lockGestures() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Restore first so zoom out works.
        isActive = false
        unlockGestures()
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil {
            isActive = false
            unlockGestures()
        }
    }

    private func lock(_ gesture: UIGestureRecognizer?) {
        guard let gesture,
              gesture.isEnabled,
              locked[ObjectIdentifier(gesture)] == nil else { return }

        gesture.isEnabled = false

        // Force it off again if UIKit re-enables it.
        let observation = gesture.observe(\.isEnabled, options: [.new]) { gesture, change in
            if change.newValue == true { gesture.isEnabled = false }
        }
        locked[ObjectIdentifier(gesture)] = LockedGesture(gesture: gesture, observation: observation)
    }

    private func lockGestures() {
        guard let navigationController else { return }

        // Edge swipe and full content swipe.
        lock(navigationController.interactivePopGestureRecognizer)
        lock(navigationController.interactiveContentPopGestureRecognizer)

        // Nav controller pan and zoom gestures.
        navigationController.view.gestureRecognizers?.forEach(lock)

        // Hosting zoom gestures, leaves SwiftUI and SceneKit alone.
        let containers = [parent?.view, parent?.view.superview].compactMap { $0 }
        let keywords = ["Zoom", "Dismiss", "Parallax"]
        for gesture in containers.flatMap({ $0.gestureRecognizers ?? [] }) {
            let name = String(describing: type(of: gesture))
            if keywords.contains(where: name.contains) { lock(gesture) }
        }
    }

    private func unlockGestures() {
        for item in locked.values {
            item.observation.invalidate()
            item.gesture.isEnabled = true
        }
        locked.removeAll()
    }
}
