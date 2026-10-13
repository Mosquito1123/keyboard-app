import KeyboardShared
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.Settings.intro)
                        .font(.subheadline)
                        .foregroundStyle(Theme.cream.color)
                    Text(L10n.Settings.introEn)
                        .font(.footnote)
                        .foregroundStyle(Theme.muted.color)
                }

                languageCard
                demoCard
                bulletCard(
                    symbol: "lock.shield",
                    title: L10n.Settings.privacyHeading,
                    titleEn: L10n.Settings.privacyHeadingEn,
                    items: L10n.Settings.privacyItems
                )
                bulletCard(
                    symbol: "wrench.and.screwdriver",
                    title: L10n.Settings.stubHeading,
                    titleEn: L10n.Settings.stubHeadingEn,
                    items: L10n.Settings.stubItems
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.canvas.color)
        .navigationTitle(L10n.Settings.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.canvas.color, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(L10n.Settings.languageHeading, en: L10n.Settings.languageHeadingEn)
            ForEach(TypingLanguage.allCases) { language in
                Button {
                    model.setLanguage(language)
                } label: {
                    languageRow(language)
                }
                .buttonStyle(.plain)
            }
            Text(L10n.Settings.languageFootnote)
                .font(.footnote)
                .foregroundStyle(Theme.cream.color)
            Text(L10n.Settings.languageFootnoteEn)
                .font(.footnote)
                .foregroundStyle(Theme.muted.color)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func languageRow(_ language: TypingLanguage) -> some View {
        let names = L10n.Settings.languageName(language)
        let selected = model.language == language
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(names.0)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.cream.color)
                Text(names.1)
                    .font(.footnote)
                    .foregroundStyle(Theme.muted.color)
            }
            Spacer(minLength: 8)
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(selected ? Theme.mic.color : Theme.muted.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(selected ? Theme.statusFill.color : Theme.canvas.color)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(selected ? Theme.mic.color.opacity(0.7) : Theme.hairline.color, lineWidth: 1)
        }
    }

    private var demoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(L10n.Settings.demoHeading, en: L10n.Settings.demoHeadingEn)
            Toggle(
                isOn: Binding(
                    get: { model.demoModeEnabled },
                    set: { model.setDemoMode($0) }
                )
            ) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Settings.demoToggle)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.cream.color)
                    Text(L10n.Settings.demoToggleEn)
                        .font(.footnote)
                        .foregroundStyle(Theme.muted.color)
                }
            }
            .tint(Theme.mic.color)

            Text(model.demoModeEnabled ? L10n.Settings.demoOnDetail : L10n.Settings.demoOffDetail)
                .font(.subheadline)
                .foregroundStyle(Theme.cream.color)
            Text(model.demoModeEnabled ? L10n.Settings.demoOnDetailEn : L10n.Settings.demoOffDetailEn)
                .font(.footnote)
                .foregroundStyle(Theme.muted.color)
            Text(L10n.Settings.syncNote)
                .font(.footnote)
                .foregroundStyle(Theme.statusText.color)
            Text(L10n.Settings.syncNoteEn)
                .font(.footnote)
                .foregroundStyle(Theme.muted.color)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func bulletCard(
        symbol: String,
        title: String,
        titleEn: String,
        items: [(String, String)]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(titleEn)
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted.color)
                }
            } icon: {
                Image(systemName: symbol)
            }
            .foregroundStyle(Theme.cream.color)

            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.0)
                        .foregroundStyle(Theme.cream.color)
                    Text(item.1)
                        .font(.footnote)
                        .foregroundStyle(Theme.muted.color)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func sectionHeader(_ zh: String, en: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(zh)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.cream.color)
            Text(en)
                .font(.subheadline)
                .foregroundStyle(Theme.muted.color)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Theme.card.color)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.hairline.color, lineWidth: 1)
            }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(
        AppModel(
            preferences: KeyboardPreferences(language: .english, demoModeEnabled: true),
            writesToSharedStore: false
        )
    )
    .preferredColorScheme(.dark)
}
