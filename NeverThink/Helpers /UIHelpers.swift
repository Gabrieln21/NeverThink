//
//  UIHelpers.swift
//  NeverThink
//
//  Created by Gabriel Fernandez on 4/28/25.
//
import SwiftUI

// to apply blur effects in SwiftUI views.
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

