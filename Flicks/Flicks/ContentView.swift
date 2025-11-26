//
//  ContentView.swift
//  Flicks
//
//  Created by Shamik Karkhanis on 11/19/25.
//

import SwiftUI

struct ContentView: View {
    // Tracks whether the bottom-left menu is expanded
    @State private var isExpanded = false

    // Navbar selection (pages)
    enum Page: Int, CaseIterable, Identifiable {
        case personal
        case groups
        case profile

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .personal: return "Personal"
            case .groups: return "Groups"
            case .profile: return "Profile"
            }
        }

        var systemImage: String {
            switch self {
            case .personal: return "person.fill"
            case .groups: return "person.2.fill"
            case .profile: return "person.crop.circle"
            }
        }
    }

    @State private var selectedPage: Page = .personal

    // Panel auto-minimize delay when expanded and idle
    private let panelIdleCollapseDelay: TimeInterval = 3.0
    @State private var panelIdleTaskID = UUID()

    var body: some View {
        ZStack {
            // Your main content
            currentPageView

            // Bottom-left floating nav: single circle trigger that expands into a glass panel with page icons
            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: 0) {
                    expandingMenuControl
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 30)
                .padding(.bottom, 0)
            }
            .ignoresSafeArea(.keyboard)
        }
        // Tap anywhere to collapse (without blocking drags)
        .contentShape(Rectangle())
        .gesture(
            TapGesture().onEnded {
                if isExpanded {
                    withAnimation(.snappy(duration: 0.2, extraBounce: 0.05)) {
                        isExpanded = false
                    }
                }
            }
        )
        // If user starts dragging anywhere while expanded, collapse immediately and let the scroll continue
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { _ in
                    if isExpanded {
                        withAnimation(.snappy(duration: 0.2, extraBounce: 0.05)) {
                            isExpanded = false
                        }
                        // Cancel panel idle collapse
                        panelIdleTaskID = UUID()
                    }
                },
            including: isExpanded ? .gesture : .subviews
        )
        .onAppear {
            // Start in collapsed state
            isExpanded = false
        }
        // Reset the panel idle timer whenever expanded state changes
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                schedulePanelIdleCollapse()
            } else {
                panelIdleTaskID = UUID()
            }
        }
    }

    // MARK: - Single expanding control (circle + panel as one unit)

    private var expandingMenuControl: some View {
        HStack(spacing: 0) {
            // Menu button (rotating icon inside glass circle)
            Button {
                withAnimation(.snappy(duration: 0.25, extraBounce: 0.05)) {
                    isExpanded.toggle()
                }
                if isExpanded {
                    schedulePanelIdleCollapse()
                }
            } label: {
                ZStack {
                    Circle()
                        .frame(width: 64, height: 64)
                        .glassEffect(.regular, in: Circle())

                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.primary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.snappy(duration: 0.25, extraBounce: 0.05), value: isExpanded)
                }
                .frame(width: 64, height: 64)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Hide navigation" : "Show navigation")

            // Panel that feels attached to the button (no gap)
            if isExpanded {
                IconPanel(
                    pages: Page.allCases,
                    selected: $selectedPage,
                    onTap: { tapped in
                        // Reset panel idle timer on interaction
                        schedulePanelIdleCollapse()
                        // Update selection
                        if tapped != selectedPage {
                            withAnimation(.snappy(duration: 0.25, extraBounce: 0.05)) {
                                selectedPage = tapped
                            }
                        }
                        // Keep expanded or call collapse() here if you want it to close after selection
                    }
                )
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.9, anchor: .leading).combined(with: .opacity),
                        removal: .scale(scale: 0.98, anchor: .leading).combined(with: .opacity)
                    )
                )
            }
        }
        // Keep the HStack animation consistent
        .animation(.snappy(duration: 0.25, extraBounce: 0.05), value: isExpanded)
    }

    @ViewBuilder
    private var currentPageView: some View {
        switch selectedPage {
        case .personal:
            ForYouView()
        case .groups:
            GroupView()
        case .profile:
            ProfileView()
        }
    }

    // MARK: - Panel idle collapse (3 seconds)

    private func schedulePanelIdleCollapse() {
        panelIdleTaskID = UUID()
        let thisID = panelIdleTaskID
        DispatchQueue.main.asyncAfter(deadline: .now() + panelIdleCollapseDelay) {
            guard thisID == panelIdleTaskID else { return }
            withAnimation(.snappy(duration: 0.2, extraBounce: 0.05)) {
                isExpanded = false
            }
        }
    }

    private func collapse() {
        withAnimation(.snappy(duration: 0.25, extraBounce: 0.05)) {
            isExpanded = false
        }
        // Reset timers
        panelIdleTaskID = UUID()
    }
}

// MARK: - IconPanel specialized for ContentView.Page

private struct IconPanel: View {
    let pages: [ContentView.Page]
    @Binding var selected: ContentView.Page
    var onTap: (ContentView.Page) -> Void

    // Layout constants
    private let iconSize: CGFloat = 28
    private let itemSize: CGFloat = 64 // touch target per icon

    var body: some View {
        HStack(spacing: 8) {
            ForEach(pages, id: \.self) { page in
                Button {
                    onTap(page)
                } label: {
                    Image(systemName: page.systemImage)
                        .font(.system(size: iconSize, weight: .semibold))
                        .frame(width: itemSize, height: itemSize)
                        .contentShape(Rectangle())
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 0)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(page.title)
            }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 40))
    }
}

#Preview {
    ContentView()
}
