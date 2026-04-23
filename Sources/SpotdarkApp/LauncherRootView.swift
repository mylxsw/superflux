import AppKit
import SwiftUI
import SpotdarkCore

struct LauncherRootView: View {
    @Bindable var store: LauncherStore

    var body: some View {
        ZStack {
            panelBackground

            panelContent
        }
        .frame(width: LauncherPanelMetrics.width)
        .frame(maxHeight: .infinity, alignment: .top)
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: LauncherPanelMetrics.cornerRadius, style: .continuous))
        .tint(LauncherGlassStyle.accent)
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
        LauncherGlassBackground(cornerRadius: LauncherPanelMetrics.cornerRadius)
    }

    @ViewBuilder
    private var panelContent: some View {
        if store.isShowingExpandedContent {
            VStack(spacing: 0) {
                searchBar

                Rectangle()
                    .fill(LauncherGlassStyle.divider)
                    .frame(height: 1)

                bodyContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            searchBar
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity, alignment: .center)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(LauncherGlassStyle.searchPlaceholder)

            LauncherSearchField(
                text: $store.query,
                placeholder: LauncherStrings.searchPlaceholder,
                textColor: NSColor(LauncherGlassStyle.searchText),
                placeholderColor: NSColor(LauncherGlassStyle.searchPlaceholder),
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
            .frame(height: 26)

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
            if store.isInitialIndexing {
                expandedFallback(content: AnyView(LauncherLoadingStateView()))
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
                expandedFallback(
                    content: AnyView(
                        LauncherEmptyStateView(
                            systemImage: "exclamationmark.magnifyingglass",
                            title: LauncherStrings.noResultsTitle,
                            message: String(
                                format: LauncherStrings.noResultsMessageTemplate,
                                store.query.trimmingCharacters(in: .whitespacesAndNewlines)
                            ),
                            hint: LauncherStrings.noResultsHint
                        )
                    )
                )
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.snappy(duration: LauncherPanelMetrics.expandedContentAnimationDuration, extraBounce: 0), value: store.isInitialIndexing)
        .animation(.snappy(duration: LauncherPanelMetrics.contentSwapAnimationDuration, extraBounce: 0), value: store.isShowingResults)
        .animation(.snappy(duration: LauncherPanelMetrics.contentSwapAnimationDuration, extraBounce: 0), value: store.isShowingNoResultsState)
    }

    private func expandedFallback(content: AnyView) -> some View {
        VStack {
            Spacer(minLength: 0)
            content
            Spacer(minLength: 0)
        }
        .padding(18)
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
                .allowsHitTesting(false)
        }
    }
}
