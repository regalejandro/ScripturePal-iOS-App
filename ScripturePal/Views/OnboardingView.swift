//
//  OnboardingView.swift
//  ScripturePal
//
//  First-launch welcome flow: a couple of feature highlight pages, then
//  tradition → translation (skipped when there's only one, e.g. Protestant)
//  → theme selection. Writes straight into the same AppStorage keys Settings
//  uses, so choices made here are the real app settings, not a staged copy.
//

import SwiftUI

struct OnboardingView: View {

    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("selectedTradition") private var selectedTradition = "Catholic"
    @AppStorage("selectedTranslation") private var selectedTranslation = "Douay-Rheims"

    @StateObject private var bible = BibleManager()
    @State private var pageIndex = 0

    private var theme: Theme { themeManager.current }

    private enum Step {
        case welcome, features, tradition, translation, theme
    }

    private var categorizedTranslations: [String: [String]] {
        let all = bible.data?.translations.keys.sorted() ?? []
        return Dictionary(grouping: all, by: { bible.tradition(of: $0) })
    }

    /// Only worth a separate page when there's more than one option to pick
    /// from — Protestant currently has just the one translation.
    private var needsTranslationStep: Bool {
        (categorizedTranslations[selectedTradition]?.count ?? 0) > 1
    }

    private var steps: [Step] {
        var s: [Step] = [.welcome, .features, .tradition]
        if needsTranslationStep { s.append(.translation) }
        s.append(.theme)
        return s
    }

    private var clampedIndex: Int {
        min(pageIndex, steps.count - 1)
    }

    private var isLastStep: Bool {
        clampedIndex == steps.count - 1
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            // Capped width + centered, same margin convention as the rest
            // of the app's iPad layouts (Stats, Library, BookDetail).
            VStack(spacing: 0) {
                Group {
                    switch steps[clampedIndex] {
                    case .welcome:
                        WelcomePage(theme: theme)
                    case .features:
                        FeaturesPage(theme: theme)
                    case .tradition:
                        TraditionPage(selectedTradition: $selectedTradition, theme: theme)
                    case .translation:
                        TranslationPage(
                            selectedTranslation: $selectedTranslation,
                            options: categorizedTranslations[selectedTradition] ?? [],
                            theme: theme
                        )
                    case .theme:
                        ThemePage(themeManager: themeManager, colorScheme: colorScheme)
                    }
                }
                .padding(.horizontal, 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
                .id(clampedIndex)

                // Page dots.
                HStack(spacing: 6) {
                    ForEach(steps.indices, id: \.self) { i in
                        Capsule()
                            .fill(i == clampedIndex ? theme.primary : theme.secondary.opacity(0.5))
                            .frame(width: i == clampedIndex ? 18 : 6, height: 6)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: clampedIndex)
                .padding(.bottom, 18)

                // Navigation.
                HStack {
                    if clampedIndex > 0 {
                        Button("Back") { goBack() }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    Spacer()
                    Button(isLastStep ? "Get Started" : "Next") { goNext() }
                        .font(.subheadline.weight(.semibold))
                        .frame(minWidth: 100)
                        .padding(.vertical, 10)
                        .buttonStyle(.glassProminent)
                        .tint(theme.primary)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.easeInOut(duration: 0.25), value: clampedIndex)
        // Keep the translation in sync with whichever tradition is active,
        // same snap-to-first behavior as Settings.
        .onChange(of: selectedTradition) { _, newTradition in
            if let first = categorizedTranslations[newTradition]?.first,
               !(categorizedTranslations[newTradition]?.contains(selectedTranslation) ?? false) {
                selectedTranslation = first
            }
        }
    }

    private func goNext() {
        if isLastStep {
            hasCompletedOnboarding = true
        } else {
            pageIndex = clampedIndex + 1
        }
    }

    private func goBack() {
        pageIndex = max(clampedIndex - 1, 0)
    }
}

// MARK: - WelcomePage

private struct WelcomePage: View {
    let theme: Theme

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "book.closed.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundColor(theme.primary)
            Text("Welcome to ScripturePal")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("Your reading and study companion that helps you read scripture daily, track progess, and build a lasting relationship with The Word.")
                .font(.body)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
            Spacer()
        }
    }
}

// MARK: - FeaturesPage

private struct FeaturesPage: View {
    let theme: Theme

    private let features: [(icon: String, title: String, description: String)] = [
        ("rays", "Pick a Chapter", "Get a single chapter chosen for you, so you always know where to start."),
        ("book.closed.fill", "Track Your Reading", "Mark a book as Currently Reading and watch its chapters fill in as you go."),
        ("flame.fill", "Build a Streak", "See your daily activity and progress add up over time."),
        ("paintpalette.fill", "Make It Yours", "Pick a theme that feels like home — change it anytime.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer()
            Text("A Few Highlights")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundColor(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 20) {
                ForEach(features, id: \.title) { feature in
                    HStack(spacing: 14) {
                        Image(systemName: feature.icon)
                            .font(.title2)
                            .foregroundColor(theme.primary)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(theme.textPrimary)
                            Text(feature.description)
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                }
            }
            Spacer()
            Spacer()
        }
    }
}

// MARK: - TraditionPage

private struct TraditionPage: View {
    @Binding var selectedTradition: String
    let theme: Theme

    private let traditions: [(name: String, description: String)] = [
        ("Catholic", "Includes the Deuterocanonical books."),
        ("Orthodox", "Includes the broader Eastern Orthodox canon."),
        ("Protestant", "The 66-book Protestant canon.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Text("Choose Your Tradition")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundColor(theme.textPrimary)
            Text("This determines which translations and canon are shown to you. You can change this anytime in Settings.")
                .font(.caption)
                .foregroundColor(theme.textSecondary)

            VStack(spacing: 12) {
                ForEach(traditions, id: \.name) { tradition in
                    SelectableRow(
                        title: tradition.name,
                        subtitle: tradition.description,
                        isSelected: selectedTradition == tradition.name,
                        theme: theme
                    ) {
                        selectedTradition = tradition.name
                    }
                }
            }
            Spacer()
            Spacer()
        }
    }
}

// MARK: - TranslationPage

private struct TranslationPage: View {
    @Binding var selectedTranslation: String
    let options: [String]
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Text("Choose a Translation")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundColor(theme.textPrimary)
            Text("You can switch translations anytime in Settings.")
                .font(.caption)
                .foregroundColor(theme.textSecondary)

            VStack(spacing: 10) {
                ForEach(options, id: \.self) { translation in
                    SelectableRow(
                        title: translation,
                        subtitle: nil,
                        isSelected: selectedTranslation == translation,
                        theme: theme
                    ) {
                        selectedTranslation = translation
                    }
                }
            }
            Spacer()
            Spacer()
        }
    }
}

// MARK: - SelectableRow

/// Shared tappable card used by the tradition and translation pages.
private struct SelectableRow: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(theme.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.primary)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? theme.primary.opacity(0.12) : theme.secondary.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? theme.primary : theme.secondary.opacity(0.9), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ThemePage

private struct ThemePage: View {
    @ObservedObject var themeManager: ThemeManager
    let colorScheme: ColorScheme

    @AppStorage("selectedTheme") private var selectedThemeRaw = AppTheme.parchment.rawValue

    private var theme: Theme { themeManager.current }

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 4)
            Text("Pick a Theme")
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundColor(theme.textPrimary)
            Text("Your selected theme will apply across the entire app and may be changed at any time")
                .font(.caption)
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)

            ThemeMockupPreview(theme: theme)
                .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AppTheme.allCases, id: \.self) { appTheme in
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                themeManager.setBaseTheme(appTheme, systemScheme: colorScheme)
                            }
                        } label: {
                            VStack(spacing: 6) {
                                MiniSwatch(appTheme: appTheme, colorScheme: colorScheme)
                                Text(appTheme.displayName)
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(theme.textSecondary)
                                    .lineLimit(1)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(appTheme.rawValue == selectedThemeRaw ? theme.primary.opacity(0.15) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        appTheme.rawValue == selectedThemeRaw ? theme.primary : theme.secondary.opacity(0.5),
                                        lineWidth: appTheme.rawValue == selectedThemeRaw ? 1.5 : 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            Spacer()
        }
    }
}

// MARK: - MiniSwatch

private struct MiniSwatch: View {
    let appTheme: AppTheme
    let colorScheme: ColorScheme

    private var colors: [Color] {
        let t = (colorScheme == .dark ? appTheme.dark : appTheme.light).theme
        return [t.primary, t.secondary, t.background, t.accent]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(colors.enumerated()), id: \.offset) { _, color in
                Rectangle().fill(color).frame(width: 12, height: 28)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - ThemeMockupPreview

/// A small, representative slice of the app's real screens — a library book
/// card, a streak card, and a last-40-days activity grid — so switching
/// themes here shows exactly how they'll look in context.
private struct ThemeMockupPreview: View {
    let theme: Theme

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MockBookCard(theme: theme)
                MockStreakCard(theme: theme)
            }
            MockActivityGrid(theme: theme)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(theme.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.secondary.opacity(0.9), lineWidth: 1)
        )
    }
}

/// Mirrors LibraryView's BookTile, including its accent notch.
private struct MockBookCard: View {
    let theme: Theme

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "book.closed.fill")
                .font(.title3)
                .foregroundColor(theme.primary)
            Text("Genesis")
                .font(.caption.weight(.semibold))
                .foregroundColor(theme.textPrimary)
            Text("50 chapters")
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(theme.secondary.opacity(0.18)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.secondary.opacity(0.9), lineWidth: 1))
        .overlay(alignment: .top) {
            // Slim accent cap, same as the real BookTile.
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.accent.opacity(0.8))
                .frame(width: 24, height: 4)
                .padding(.top, 7)
        }
    }
}

/// Mirrors StatsComponents' StreakCard: flame to the left of the number.
private struct MockStreakCard: View {
    let theme: Theme

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.title3)
                    .foregroundColor(theme.primary)
                Text("12")
                    .font(.title2.weight(.bold))
                    .foregroundColor(theme.textPrimary)
            }
            Text("day streak")
                .font(.caption2)
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(theme.secondary.opacity(0.18)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.secondary.opacity(0.9), lineWidth: 1))
    }
}

/// Mirrors StatsComponents' RecentActivityCard grid: 8 columns, accent
/// intensity scaled by count.
private struct MockActivityGrid: View {
    let theme: Theme

    // A fixed, representative spread of 40 fake daily counts (oldest first).
    private let dailyCounts: [Int] = [
        0, 0, 1, 0, 2, 1, 0, 0,
        1, 3, 2, 0, 1, 0, 0, 2,
        0, 1, 1, 4, 2, 0, 1, 0,
        3, 2, 1, 0, 0, 1, 2, 3,
        1, 0, 2, 4, 3, 2, 1, 3
    ]

    private let columns = 8
    private let squareSize: CGFloat = 12
    private let gap: CGFloat = 3

    private var maxCount: Int { dailyCounts.max() ?? 1 }

    private func color(for count: Int) -> Color {
        guard count > 0, maxCount > 0 else { return theme.secondary.opacity(0.2) }
        let intensity = 0.25 + 0.75 * (CGFloat(count) / CGFloat(maxCount))
        return theme.accent.opacity(intensity)
    }

    private var rows: [[Int]] {
        stride(from: 0, to: dailyCounts.count, by: columns).map {
            Array(dailyCounts[$0 ..< min($0 + columns, dailyCounts.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: gap) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: gap) {
                    ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color(for: rows[rowIndex][colIndex]))
                            .frame(width: squareSize, height: squareSize)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environmentObject(ThemeManager())
}
