//
//  LibraryView.swift
//  ScriptureGo
//
//  Created by Alejandro Regalado on 11/18/25.
//

import SwiftUI

// MARK: - LibraryView

struct LibraryView: View {

    @AppStorage("selectedTranslation") var selectedTranslation = "Douay-Rheims"
    @AppStorage("libraryTileSize") private var tileSizeRaw = LibraryTileSize.medium.rawValue

    @StateObject var bible = BibleManager()
    @EnvironmentObject var themeManager: ThemeManager

    /// Horizontal inset on both edges of the grid.
    private let horizontalPadding: CGFloat = 16
    /// Spacing between tiles, both horizontally and vertically.
    private let spacing: CGFloat = 12

    private var tileSize: LibraryTileSize {
        LibraryTileSize(rawValue: tileSizeRaw) ?? .medium
    }

    private var books: [Book] { bible.books(for: selectedTranslation) }

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.current.background
                    .ignoresSafeArea()

                GeometryReader { geo in
                    // Fit as many tiles of the chosen size as the width allows.
                    let available = geo.size.width - horizontalPadding * 2
                    let columnCount = max(
                        1,
                        Int((available + spacing) / (tileSize.targetWidth + spacing))
                    )
                    let tileWidth = (available - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount)
                    let tileHeight = tileWidth * tileSize.aspectRatio

                    let columns = Array(
                        repeating: GridItem(.flexible(), spacing: spacing),
                        count: columnCount
                    )

                    ScrollView {
                        LazyVGrid(columns: columns, spacing: spacing) {
                            ForEach(books) { book in
                                NavigationLink {
                                    BookDetailView(book: book)
                                } label: {
                                    BookTile(
                                        book: book,
                                        size: tileSize,
                                        height: tileHeight,
                                        theme: themeManager.current
                                    )
                                }
                                .buttonStyle(PressableTileStyle())
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, 16)
                        .animation(.easeInOut(duration: 0.25), value: tileSizeRaw)
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Tile Size", selection: $tileSizeRaw) {
                            ForEach(LibraryTileSize.allCases) { size in
                                Label(size.label, systemImage: size.icon)
                                    .tag(size.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: tileSize.icon)
                            .foregroundColor(themeManager.current.primary)
                    }
                }
            }
        }
    }
}

// MARK: - BookTile

private struct BookTile: View {

    let book: Book
    let size: LibraryTileSize
    let height: CGFloat
    let theme: Theme

    var body: some View {
        VStack(spacing: size.innerSpacing) {

            Image(systemName: "book.closed.fill")
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(theme.primary)

            Text(book.name)
                .font(.system(size: size.nameFontSize, weight: .semibold, design: .rounded))
                .foregroundColor(theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.55)

            Text("\(book.chapters) \(book.chapters == 1 ? "chapter" : "chapters")")
                .font(.system(size: size.subtitleFontSize, weight: .medium))
                .foregroundColor(theme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.secondary.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.secondary.opacity(0.9), lineWidth: 1)
        )
        .overlay(alignment: .top) {
            // Slim accent cap for a touch of personality.
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.accent.opacity(0.8))
                .frame(width: 28, height: 4)
                .padding(.top, 8)
        }
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - PressableTileStyle

/// Gives the tiles a subtle, springy press animation so they read as tappable.
private struct PressableTileStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - LibraryTileSize

/// The three tile sizes the user can choose from. `targetWidth` is the minimum
/// width a tile wants; the grid fits as many of that width as possible per row,
/// so phones land on ~2 / ~3 / ~4 columns while iPads fit proportionally more.
enum LibraryTileSize: String, CaseIterable, Identifiable {
    case large
    case medium
    case small

    var id: String { rawValue }

    var label: String {
        switch self {
        case .large:  return "Large"
        case .medium: return "Medium"
        case .small:  return "Small"
        }
    }

    var icon: String {
        switch self {
        case .large:  return "square.grid.2x2"
        case .medium: return "square.grid.3x2"
        case .small:  return "square.grid.4x3.fill"
        }
    }

    var targetWidth: CGFloat {
        switch self {
        case .large:  return 165
        case .medium: return 108
        case .small:  return 78
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .large:  return 1.15
        case .medium: return 1.2
        case .small:  return 1.25
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .large:  return 30
        case .medium: return 23
        case .small:  return 17
        }
    }

    var nameFontSize: CGFloat {
        switch self {
        case .large:  return 18
        case .medium: return 15
        case .small:  return 12
        }
    }

    var subtitleFontSize: CGFloat {
        switch self {
        case .large:  return 12
        case .medium: return 10.5
        case .small:  return 9
        }
    }

    var innerSpacing: CGFloat {
        switch self {
        case .large:  return 8
        case .medium: return 6
        case .small:  return 4
        }
    }
}

// MARK: - Preview

#Preview {
    LibraryView()
        .environmentObject(ThemeManager())
}
