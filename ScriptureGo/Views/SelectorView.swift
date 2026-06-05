//
//  SelectorView.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 11/20/25.
//

import SwiftUI
import SwiftData

struct SelectorView: View {

    
    @AppStorage("selectedTranslation") var selectedTranslation = "Douay-Rheims"
    @AppStorage("selectedGroupsData") private var selectedGroupsData: Data = Data("[]".utf8)
    @AppStorage("groupMode") var groupMode: String = "all"
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    
    @StateObject var bible = BibleManager()
    
    @State var translationAtLastSelected = "   "
    @State private var showSettings = false
    @State var lastSelected: ChapterPointer = .init(bookID: 0, bookName: "None Chosen", chapter: 0, canonicalKey: "None")
    @State private var markedAsRead = false
    @State private var showingGroupSelector = false
    @State var selectedGroupsBackup: [String] = []
    
    @State private var showingReveal = false
    @State private var revealedChapter: ChapterPointer?
    
    var selectedGroupsBinding: Binding<[String]> {
        Binding(
            get: {
                (try? JSONDecoder().decode([String].self, from: selectedGroupsData)) ?? []
            },
            set: { newValue in
                if let encoded = try? JSONEncoder().encode(newValue) {
                    selectedGroupsData = encoded
                }
            }
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.current.background
                    .ignoresSafeArea()

                /*Color(.sRGB, red: 250/255, green: 235/255, blue: 220/255)
                    .ignoresSafeArea()*/
                
                VStack {
                    
                    VStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Last Selected")
                                    .font(.body)
                                    .foregroundColor(themeManager.current.textSecondary)
                                    .padding()
                                Spacer()
                                
                                Text("\(translationAtLastSelected)")
                                    .font(.caption)
                                    .foregroundColor(themeManager.current.accent)
                                    .padding(.horizontal)
                            }
                            
                            Divider()
                                .padding(.horizontal)
                        }
                        
                        Text(
                            lastSelected.bookID != 0
                            ? "\(lastSelected.bookName) \(lastSelected.chapter)"
                            : "\(lastSelected.bookName)"
                        )
                        .font(.largeTitle)
                        .padding(.top, 22)
                        .padding(.horizontal)
                        .foregroundColor(themeManager.current.textPrimary)

                        if lastSelected.bookID != 0 {
                            Button {
                                let record = ReadingRecord(
                                    canonicalKey: lastSelected.canonicalKey,
                                    chapter: lastSelected.chapter
                                )
                                modelContext.insert(record)
                                markedAsRead = true
                            } label: {
                                Label(
                                    markedAsRead ? "Marked as Read" : "Mark as Read",
                                    systemImage: markedAsRead ? "checkmark.circle.fill" : "book.pages"
                                )
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(markedAsRead ? themeManager.current.accent.opacity(0.5) : themeManager.current.accent)
                            }
                            .disabled(markedAsRead)
                            .padding(.top, 6)
                            .animation(.easeInOut(duration: 0.2), value: markedAsRead)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(themeManager.current.secondary.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(themeManager.current.secondary.opacity(0.9), lineWidth: 1)
                    )
                    .padding()
                    
                    
                    
                    HStack(spacing: 12) {
                        // Main Button
                        Button {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                translationAtLastSelected = selectedTranslation
                            }
                            
                            if let result = bible.randomChapter(
                                for: selectedTranslation,
                                selectedGroups: selectedGroupsBinding.wrappedValue,
                                groupMode: groupMode
                            ) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    lastSelected = result
                                    markedAsRead = false
                                }
                                revealedChapter = result
                                showingReveal = true
                            }
                        } label: {
                            Label("Choose Chapter", systemImage: "book")
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                            
                        }
                        .buttonStyle(.glassProminent)
                        .tint(themeManager.current.primary)
                        
                        
                        // Customization Button
                        Button {
                            showingGroupSelector = true
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.title.bold())
                                .frame(width: 62, height: 62)
                        }
                        .glassEffect(in: Circle())
                        .sheet(isPresented: $showingGroupSelector) {
                            GroupSelectionView(
                                selectedGroups: selectedGroupsBinding,
                                groupMode: $groupMode,
                                selectedGroupsBackup: $selectedGroupsBackup,
                                allGroups: bible.groups(for: selectedTranslation)
                                
                            )
                        }
                        .tint(themeManager.current.primary)
                        
                        
                        
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                }
                .navigationTitle("ScriptureGo")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .font(.system(size: 18, weight: .semibold))
                                .padding(6)
                        }
                        
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
                .padding(.top, 50)
            }
        }
        .fullScreenCover(isPresented: $showingReveal) {
            if let chapter = revealedChapter {
                ChapterRevealView(
                    chapter: chapter,
                    translation: translationAtLastSelected
                )
                .environmentObject(themeManager)
            }
        }
        
    }
}

#Preview {
    SelectorView()
        .environmentObject(ThemeManager())
}

