//
//  AppFont.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 18/10/2026.
//

import Foundation
import SwiftUI

extension Font {
    static func customSystem(size: CGFloat) -> Font {
        return .custom("GoogleSans", size: size)
    }
}
