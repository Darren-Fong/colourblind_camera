//
//  ColorFilterView.swift
//  Colourblind Camera
//
//  Created by Alex Au on 3/1/2025.
//

import SwiftUI

struct GlobalColorFilter: View {
    let color: Color
    let opacity: Double

    var body: some View {
        color
            .opacity(opacity)
            .ignoresSafeArea()
    }
}
