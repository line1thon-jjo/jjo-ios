//
//  InteractivePopGesture.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI
import UIKit

extension View {
    func interactivePopGestureEnabled() -> some View {
        background(InteractivePopGestureEnabler().frame(width: 0, height: 0))
    }
}

private struct InteractivePopGestureEnabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> InteractivePopGestureViewController {
        InteractivePopGestureViewController()
    }

    func updateUIViewController(_ uiViewController: InteractivePopGestureViewController, context: Context) {}
}

// 시스템 내비게이션 바를 숨기면 뒤로 쓸기 제스처가 꺼지므로 대리자를 비워 다시 켠다
private final class InteractivePopGestureViewController: UIViewController {
    private var previousDelegate: UIGestureRecognizerDelegate?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard let gesture = navigationController?.interactivePopGestureRecognizer else { return }
        previousDelegate = gesture.delegate
        gesture.delegate = nil
        gesture.isEnabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let gesture = navigationController?.interactivePopGestureRecognizer else { return }
        if gesture.delegate == nil {
            gesture.delegate = previousDelegate
        }
        previousDelegate = nil
    }
}
