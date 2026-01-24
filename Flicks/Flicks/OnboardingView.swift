//
//  OnboardingView.swift
//  Flicks
//
//  Created by Shamik Karkhanis on 12/28/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userState: UserState
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Selection state
    @State private var selectedPersonas: Set<UUID> = []
    
    // Scroll state
    @State private var currentIndex: Int = 0
    
    struct Persona: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let color: Color // Kept for text/accent fallback
        let icon: String
        let image: String
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Image Layer with Crossfade
                ZStack {
                    ForEach(Array(userState.personas.enumerated()), id: \.offset) { index, persona in
                        Image(persona.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .opacity(index == currentIndex ? 1 : 0)
                            .animation(.easeInOut(duration: 0.8), value: currentIndex)
                    }
                }
                .background(Color.black) // Fallback
                .ignoresSafeArea() // Ensure the background extends to edges
                
                // Dark overlay for general readability
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Carousel
                    TabView(selection: $currentIndex) {
                        ForEach(Array(userState.personas.enumerated()), id: \.element.id) { index, persona in
                            PersonaCard(
                                persona: persona,
                                isSelected: selectedPersonas.contains(persona.id),
                                // Increased height relative to screen, almost full height minus padding
                                size: CGSize(width: geometry.size.width - 40, height: geometry.size.height * 0.75)
                            ) {
                                toggleSelection(for: persona)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: geometry.size.height * 0.85) // Container size
                    
                    
                    // Footer Controls
                    HStack {
                        // Custom Pagination Dots (Bottom Left) in a bubble panel
                        HStack(spacing: 8) {
                            ForEach(0..<userState.personas.count, id: \.self) { index in
                                Circle()
                                    .fill(Color.white.opacity(currentIndex == index ? 1.0 : 0.4))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(currentIndex == index ? 1.2 : 1.0)
                                    .animation(.spring(), value: currentIndex)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .glassEffect(.regular, in: Capsule())
                        
                        Spacer()
                        
                        // Circular Continue Button (Bottom Right)
                        Button(action: completeOnboarding) {
                            ZStack {
                                Circle()
                                    .fill(selectedPersonas.isEmpty ? Color.white.opacity(0.2) : Color.white)
                                    .frame(width: 60, height: 60)
                                    .shadow(radius: 10)
                                    .glassEffect(.clear)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(selectedPersonas.isEmpty ? .white.opacity(0.5) : .black)
                            }
                        }
                        .disabled(selectedPersonas.isEmpty)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .ignoresSafeArea() // Ensure GeometryReader fills the screen
    }
    
    private func toggleSelection(for persona: Persona) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if selectedPersonas.contains(persona.id) {
                selectedPersonas.remove(persona.id)
            } else {
                selectedPersonas.insert(persona.id)
            }
        }
    }
    
    private func completeOnboarding() {
        Task {
            let selectedTitles = selectedPersonas.compactMap { id in
                userState.personas.first(where: { $0.id == id })?.title
            }
            await userState.syncUserProfile(personas: selectedTitles)
            
            withAnimation {
                hasCompletedOnboarding = true
            }
        }
    }
}

struct PersonaCard: View {
    let persona: OnboardingView.Persona
    let isSelected: Bool
    let size: CGSize
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                
                // Glass Panel Background
                Rectangle()
                    .fill(Color.white.opacity(0.0000001))
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 32))

                
                // Content
                VStack(alignment: .leading, spacing: 16) {
                    
                    Text(persona.title)
                        .font(.system(size: 40, weight: .bold)) // Larger Title
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(persona.description)
                        .font(.title3) // Larger Description
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(4)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
                .padding(32)
                .padding(.bottom, 20)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: size.width, height: size.height)
        .contentShape(RoundedRectangle(cornerRadius: 32))
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .shadow(color: isSelected ? Color.white.opacity(0.3) : Color.black.opacity(0.2), radius: 20)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserState())
}
