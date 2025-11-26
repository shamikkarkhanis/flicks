//
//  SwiftUIView.swift
//  Flicks
//
//  Created by Shamik Karkhanis on 11/22/25.
//

import SwiftUI

struct SwiftUIView: View {
    var body: some View {
        GlassEffectContainer(spacing: 40.0) {
            HStack(spacing: 40.0) {
                Image(systemName: "scribble.variable")
                    .frame(width: 80.0, height: 80.0)
                    .font(.system(size: 36))
                    .glassEffect()

                Image(systemName: "eraser.fill")
                    .frame(width: 80.0, height: 80.0)
                    .font(.system(size: 36))
                    .glassEffect()
                    // An `offset` shows how Liquid Glass effects react to each other in a container.
                    // Use animations and components appearing and disappearing to obtain effects that look purposeful.
                    .offset(x: -40.0, y: 0.0)
            }
        }
    }
}

#Preview {
    SwiftUIView()
}
