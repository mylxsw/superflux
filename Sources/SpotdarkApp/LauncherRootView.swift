import AppKit
import SwiftUI
import SpotdarkCore

struct LauncherRootView: View {
    @Bindable var store: LauncherStore

    var body: some View {
        ZStack(alignment: .top) {
            // Base glass material.
            RoundedRectangle(cornerRadius: LauncherPanelMetrics.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: LauncherPanelMetrics.cornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                )

            VStack(spacing: store.isShowingExpandedContent ? LauncherPanelMetrics.contentSpacing : 0) {
                searchBar
                if store.isShowingExpandedContent {
                    resultsList
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.985, anchor: .top)),
                                removal: .opacity.combined(with: .scale(scale: 0.995, anchor: .top))
                            )
                        )
                }
            }
            .padding(LauncherPanelMetrics.contentPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: LauncherPanelMetrics.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .clipShape(RoundedRectangle(cornerRadius: LauncherPanelMetrics.cornerRadius, style: .continuous))
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

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            LauncherSearchField(
                text: $store.query,
                placeholder: LauncherStrings.searchPlaceholder,
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

            LauncherShortcutHintView(settingsStore: SettingsStore.shared)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(height: LauncherPanelMetrics.searchFieldHeight)
        .background(
            RoundedRectangle(cornerRadius: LauncherPanelMetrics.searchFieldCornerRadius, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: LauncherPanelMetrics.searchFieldCornerRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                )
        )
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
                    items: store.displayedItems,
                    query: store.trimmedQuery,
                    selectedIndex: store.selectedIndex,
                    sectionTitle: LauncherStrings.recentSectionTitle,
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
                    items: store.displayedItems,
                    query: store.trimmedQuery,
                    selectedIndex: store.selectedIndex,
                    sectionTitle: nil,
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
}
