//
//  ChapterRevealView.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 3/4/26.
//

import SwiftUI

struct ChapterRevealView: View {
    
    let chapter: ChapterPointer
    let translation: String
    
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var stage: Int = 0
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            themeManager.current.background
                .ignoresSafeArea()
            
            Color.black.opacity(0.001)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {

                
                if stage >= 1 {
                    Text(chapter.bookName)
                        .font(.largeTitle.weight(.semibold))
                        .foregroundColor(themeManager.current.textPrimary)
                        .opacity(stage >= 1 ? 1 : 0)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                if stage >= 2 {
                    Text("Chapter \(chapter.chapter)")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(themeManager.current.primary)
                        .scaleEffect(stage >= 2 ? 1 : 0.6)
                        .opacity(stage >= 2 ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: stage)
                }
                
                if stage >= 3 {
                    Text(translation)
                        .font(.caption)
                        .foregroundColor(themeManager.current.textSecondary)
                        .transition(.opacity)
                }
                
                if stage >= 4 {
                    Button {
                        dismiss()
                    } label: {
                        Text("Begin Reading")
                            .font(.title2.bold())
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(themeManager.current.primary)
                    .padding(.top, 30)
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
            }
            .padding()
        }
        .presentationBackground(.clear)
        .onAppear {
            runRevealSequence()
        }
    }
    
    private func runRevealSequence() {
        
        let light = UIImpactFeedbackGenerator(style: .light)
        let medium = UIImpactFeedbackGenerator(style: .medium)
        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        
        light.prepare()
        medium.prepare()
        heavy.prepare()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.5)) {
                stage = 1
            }
            light.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                stage = 2
            }
            medium.impactOccurred()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation {
                stage = 3
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                stage = 4
            }
            heavy.impactOccurred()
        }
    }
}

/*#Preview {
    ChapterRevealView()
}*/
