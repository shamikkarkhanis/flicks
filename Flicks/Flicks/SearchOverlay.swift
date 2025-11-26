import SwiftUI

/// Reusable search overlay with floating trigger, search bar, and selectable filters.
struct SearchOverlay: View {
    @Binding var isSearching: Bool
    @Binding var query: String
    @Binding var selectedVibes: Set<String>

    var vibes: [String]
    var onSubmit: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Tap-away layer only when searching
            if isSearching {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0.05)) {
                            isSearching = false
                        }
                    }
            }

            VStack(spacing: 0) {
                Spacer()

                // Vibes panel appears above the search bar when searching
                if isSearching {
                    vibesPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                }

                // Search bar that slides in from bottom
                if isSearching {
                    searchBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 0)
                }

                // Floating search button at bottom-right (only when not searching)
                if !isSearching {
                    HStack {
                        Spacer()
                        searchButton
                            .transition(.scale.combined(with: .opacity))
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, 0)
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .animation(.snappy(duration: 0.3, extraBounce: 0.05), value: isSearching)
    }

    private var searchButton: some View {
        Button {
            withAnimation(.snappy(duration: 0.3, extraBounce: 0.05)) {
                isSearching = true
            }
        } label: {
            Image(systemName: "magnifyingglass")
                .frame(width: 64, height: 64)
                .font(.system(size: 28, weight: .regular))
                .glassEffect()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Show search")
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 16, weight: .regular))

            TextField("Search movies", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .submitLabel(.search)
                .onSubmit {
                    onSubmit?()
                }

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }

            // Close button to hide the search bar
            Button {
                withAnimation(.snappy(duration: 0.3, extraBounce: 0.05)) {
                    isSearching = false
                }
            } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Hide search")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .keyboardType(.default)
        .glassEffect(.regular.tint(Color.white.opacity(0.1)), in: RoundedRectangle(cornerRadius: 24))
    }

    private var vibesPanel: some View {
        // A non-scrolling, wrapped grid panel with fixed height
        GeometryReader { proxy in
            let columns = [
                GridItem(.adaptive(minimum: 100, maximum: 180), spacing: 8, alignment: .leading)
            ]

            VStack(alignment: .leading, spacing: 8) {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(vibes, id: \.self) { vibe in
                        let isSelected = selectedVibes.contains(vibe)
                        Button {
                            if isSelected {
                                selectedVibes.remove(vibe)
                            } else {
                                selectedVibes.insert(vibe)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(vibe)
                                    .font(.system(size: 14, weight: .medium))
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isSelected ? .thinMaterial : .ultraThinMaterial)
                                    .glassEffect()
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(isSelected ? .secondary : .quaternary, lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isSelected ? "\(vibe) selected" : "Select \(vibe)")
                    }
                }
            }
            .padding(10)
            .frame(width: proxy.size.width, height: min(180, proxy.size.height), alignment: .topLeading)
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 24))
        }
        .frame(height: 180)
    }
}

#Preview {
    struct SearchOverlay_PreviewWrapper: View {
        @State private var isSearching = false
        @State private var query = ""
        @State private var selectedVibes: Set<String> = []
        private let vibes = ["Cozy", "Sci‑Fi", "Epic", "Feel‑good", "Dark", "Romantic", "Nostalgic"]

        var body: some View {
            ZStack {
                Color.black.opacity(0.05).ignoresSafeArea()
                SearchOverlay(
                    isSearching: $isSearching,
                    query: $query,
                    selectedVibes: $selectedVibes,
                    vibes: vibes
                )
            }
        }
    }

    return SearchOverlay_PreviewWrapper()
}
