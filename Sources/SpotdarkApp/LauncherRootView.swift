import AppKit
import SwiftUI
import SpotdarkCore

struct LauncherRootView: View {
    @Bindable var store: LauncherStore
    @ObservedObject private var settingsStore = SettingsStore.shared

    private var theme: LauncherThemePalette {
        settingsStore.selectedThemePreset.theme
    }

    var body: some View {
        ZStack {
            panelBackground

            VStack(spacing: 0) {
                searchBar
                Rectangle()
                    .fill(theme.dividerColor)
                    .frame(height: 1)

                bodyContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                LauncherStatusFooterView(isIndexing: store.isInitialIndexing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: LauncherPanelMetrics.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: LauncherPanelMetrics.cornerRadius, style: .continuous))
        .tint(theme.accentColor)
        // Global keyboard behavior:
        // - Up/Down: navigate results
        // - Return: open selected item
        // - Esc: close
        .onMoveCommand { direction in
            switch direction {
            case .down:
                store.moveSelection(delta: 1)
            case .up:
                store.moveSelection(delta: -1)
            default:
                break
            }
        }
        .background(defaultActionButton)
        .onExitCommand {
            store.hide()
        }
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: LauncherPanelMetrics.cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [theme.panelBackgroundTop, theme.panelBackgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: LauncherPanelMetrics.cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.panelTintTop, theme.panelTintBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: LauncherPanelMetrics.cornerRadius, style: .continuous)
                    .strokeBorder(theme.panelStrokeColor, lineWidth: 0.75)
            )
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(theme.searchPlaceholderColor)

            LauncherSearchField(
                text: $store.query,
                placeholder: LauncherStrings.searchPlaceholder,
                textColor: NSColor(theme.searchTextColor),
                placeholderColor: NSColor(theme.searchPlaceholderColor),
                focusRequestID: store.focusRequestID,
                onMoveSelection: { delta in
                    store.moveSelection(delta: delta)
                },
                onSubmit: {
                    store.performSelectedAction()
                },
                onExit: {
                    store.hide()
                }
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 30)

            LauncherShortcutHintView(settingsStore: SettingsStore.shared)
        }
        .padding(.horizontal, LauncherPanelMetrics.searchBarHorizontalPadding)
        .padding(.top, LauncherPanelMetrics.searchBarTopPadding)
        .padding(.bottom, LauncherPanelMetrics.searchBarBottomPadding)
        .frame(height: LauncherPanelMetrics.searchFieldHeight)
    }

    private var defaultActionButton: some View {
        Button(action: {
            store.performSelectedAction()
        }) {
            EmptyView()
        }
        .keyboardShortcut(.defaultAction)
        .opacity(0)
        .frame(width: 0, height: 0)
        .accessibilityHidden(true)
    }

    private var resultsList: some View {
        Group {
            if store.isShowingRecentItems {
                LauncherItemListView(
                    sections: store.displayedSections,
                    query: store.trimmedQuery,
                    selectedIndex: store.selectedIndex,
                    onSelect: { index in
                        store.select(index: index)
                    },
                    onActivate: { _ in
                        store.performSelectedAction()
                    }
                )
                .transition(.opacity)
            } else if store.isInitialIndexing {
                LauncherLoadingStateView()
                    .transition(.opacity)
            } else if store.isShowingResults {
                LauncherItemListView(
                    sections: store.displayedSections,
                    query: store.trimmedQuery,
                    selectedIndex: store.selectedIndex,
                    onSelect: { index in
                        store.select(index: index)
                    },
                    onActivate: { _ in
                        store.performSelectedAction()
                    }
                )
                .transition(.opacity)
            } else if store.isShowingNoResultsState {
                LauncherEmptyStateView(
                    systemImage: "exclamationmark.magnifyingglass",
                    title: LauncherStrings.noResultsTitle,
                    message: String(
                        format: LauncherStrings.noResultsMessageTemplate,
                        store.query.trimmingCharacters(in: .whitespacesAndNewlines)
                    ),
                    hint: LauncherStrings.noResultsHint
                )
                .transition(.opacity)
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.snappy(duration: LauncherPanelMetrics.expandedContentAnimationDuration, extraBounce: 0), value: store.isInitialIndexing)
        .animation(.snappy(duration: LauncherPanelMetrics.contentSwapAnimationDuration, extraBounce: 0), value: store.isShowingResults)
        .animation(.snappy(duration: LauncherPanelMetrics.contentSwapAnimationDuration, extraBounce: 0), value: store.isShowingRecentItems)
        .animation(.snappy(duration: LauncherPanelMetrics.contentSwapAnimationDuration, extraBounce: 0), value: store.isShowingNoResultsState)
    }

    @ViewBuilder
    private var bodyContent: some View {
        if store.isShowingExpandedContent {
            resultsList
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.985, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.995, anchor: .top))
                    )
                )
        } else {
            Color.clear
                .frame(height: LauncherPanelMetrics.collapsedBodyHeight)
                .allowsHitTesting(false)
        }
    }
}
