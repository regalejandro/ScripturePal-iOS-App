# ScripturePal

An iOS app for daily scripture reading, built end-to-end as a solo project — design, data modeling, and engineering all done by Alejandro Regalado.

ScripturePal helps users build a consistent reading habit by removing the friction of deciding what to read, while supporting multiple Christian traditions and their respective canons and translations.

[Dowload on the Appstore!](https://apps.apple.com/us/app/scripturepal/id6782519703)

## Features

### Reading
- **Random chapter selector** — presents a single chapter to read, optionally filtered by book groups (e.g. Gospels, Wisdom Books) or custom user-defined collections.
- **Currently Reading sessions** — mark a book as in-progress and track which chapters have been read during that specific session, with visual indicators in the chapter grid.
- **Completion detection** — automatically recognizes when every chapter in a session has been read, prompting the user to start over, keep going, or finish the book, and records a running count of how many times each book has been completed.
- **Flexible logging** — log a chapter as read for today or for a specific past date, with full edit/delete support in the reading log.

### Traditions, Canons & Translations
- **Three traditions** — Catholic, Orthodox, and Protestant, each with its own accurate book list, ordering, and chapter structure.
- **Seven translations** across those traditions (e.g. Douay-Rheims/Knox, NABRE/NRSV-CE, RSV-CE, Jerusalem Bible/RNJB, Orthodox Study Bible, NETS, and the Standard Protestant Canon), each independently modeled rather than treated as interchangeable.
- **Cross-translation continuity** — reading history, currently-reading status, and custom groups are tracked against a translation-independent book identity, so switching translations never loses progress.

### Progress & Stats
- Daily reading streaks with current and best-streak tracking.
- A 40-day activity heatmap and yearly/all-time reading statistics.
- Old Testament / New Testament progress breakdowns.
- A unified reading log that merges individual chapter reads and full book completions into one chronological history.

### Organization
- **Library** with search, testament/group filtering, and adjustable grid density.
- **Custom reading groups** — user-created collections of books for personalized reading plans, with drag-to-reorder support.

### Personalization
- A guided onboarding flow that introduces the app's features and walks new users through choosing a tradition, translation, and visual theme.
- Multiple built-in color themes, each with dedicated light and dark variants, previewed live against real app components before the user commits to one.
- Tactile feedback (haptics) tuned distinctly for different action types, so confirmations feel consistent throughout the app.

### Platform Support
- Adaptive layouts tuned separately for iPhone and iPad.
- Supports iOS 17 and later, with newer visual effects (Liquid Glass) applied on capable devices and a matching fallback appearance on earlier versions — full functionality either way.

## Tech Stack

- **SwiftUI** for the entire interface, including custom theming, adaptive layouts, and animated transitions.
- **SwiftData** for local persistence of reading history, reading sessions, completions, and custom groups.
- **Swift** throughout, with no third-party dependencies.

## Engineering Notes

A few design decisions that shaped the app:

- **Derived state over duplicated state** — rather than separately tracking "which chapters were read this session," session progress is computed live from the existing reading-history records. This means editing or deleting a logged read automatically and correctly updates session progress and completion counts, with no manual synchronization logic to maintain or get out of sync.
- **Data integrity for completions** — each book completion records exactly which logged reads earned it. If one of those reads is later deleted, the completion is automatically revoked rather than left in an inconsistent state.
- **Forward-compatible UI** — newer platform visual effects are adopted where available and gracefully degrade on older OS versions, so the app supports a wide range of devices without a fragmented codebase.

## Status

Actively developed. Built and maintained by **Alejandro Regalado**.
