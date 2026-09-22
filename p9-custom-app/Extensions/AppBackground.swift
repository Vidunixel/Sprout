//
//  AppBackground.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 22/9/2026.
//

import SwiftUI

struct SproutBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        let lightTop = Color(red: 215/255, green: 245/255, blue: 225/255)
        let darkTop = Color(red: 30/255, green: 70/255, blue: 45/255)
        
        let topColour = colorScheme == .dark ? darkTop : lightTop
        
        content.background(
            LinearGradient(
                colors: [topColour, .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

extension View {
    func appBackground() -> some View {
        self.modifier(SproutBackgroundModifier())
    }
}
