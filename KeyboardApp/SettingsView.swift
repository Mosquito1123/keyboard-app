import KeyboardShared
import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openURL) private var openURL
    @State private var availability = OnDeviceSpeechAccess.current(language: .simplifiedChinese)
    @State private var requestingPermission = false
    @State private var showLimits = false
    @State private var showIdentity = false

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
                    Text(SharedStore.usesAppGroup ? L10n.Settings.groupOn : L10n.Settings.groupOff)
                        .font(.subheadline)
                        .foregroundStyle(Theme.statusText.color)
                    Text(SharedStore.usesAppGroup ? L10n.Settings.groupOnEn : L10n.Settings.groupOffEn)
                        .font(.footnote)
                        .foregroundStyle(Theme.muted.color)
                }

                languageCard
                demoCard
                permissionCard
                bulletCard(
                    symbol: "lock.shield",
                    title: L10n.Settings.privacyHeading,
                    titleEn: L10n.Settings.privacyHeadingEn,
                    items: L10n.Settings.privacyItems
                )
                disclosureCard(title: L10n.Settings.limitsHeading, titleEn: L10n.Settings.limitsHeadingEn, symbol: "wrench.and.screwdriver", isExpanded: $showLimits) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(L10n.Settings.stubItems.enumerated()), id: \.offset) { _, item in
                            bilingualLine(item.0, en: item.1)
                        }
                        ForEach(Array(L10n.App.scopeItems.enumerated()), id: \.offset) { _, item in
                            bilingualLine(item.0, en: item.1)
                        }
                        Text(LanguageModelStub.scopeNote)
                            .font(.footnote.monospaced())
                            .foregroundStyle(Theme.statusText.color)
                    }
                    .padding(.top, 8)
                }
                disclosureCard(title: L10n.App.idTitle, titleEn: L10n.App.idTitleEn, symbol: "tag", isExpanded: $showIdentity) {
                    VStack(alignment: .leading, spacing: 10) {
                        identityRow(L10n.App.runningAs, en: L10n.App.runningAsEn, value: Bundle.main.bundleIdentifier ?? "—")
                        identityRow("主 App", en: "Containing app", value: AppIdentity.appBundleIdentifier)
                        identityRow("键盘扩展", en: "Keyboard extension", value: AppIdentity.keyboardBundleIdentifier)
                        identityRow("App Group", en: "App Group", value: AppIdentity.appGroupIdentifier)
                        identityRow(
                            "当前是否共享设置",
                            en: "Settings sharing now",
                            value: SharedStore.usesAppGroup ? "App Group" : "in-process"
                        )
                        identityRow("保留的 URL Scheme", en: "Reserved URL scheme", value: "\(AppIdentity.urlScheme)://")
                        Text(L10n.App.idFootnote)
                            .font(.footnote)
                            .foregroundStyle(Theme.cream.color)
                        Text(L10n.App.idFootnoteEn)
                            .font(.footnote)
                            .foregroundStyle(Theme.muted.color)
                    }
                    .padding(.top, 8)
                }
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
        .task(id: model.language) {
            availability = OnDeviceSpeechAccess.current(language: model.language)
        }
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

    private var permissionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(L10n.Settings.permissionHeading, en: L10n.Settings.permissionHeadingEn)
            Text(L10n.Settings.permissionIntro)
                .font(.subheadline)
                .foregroundStyle(Theme.cream.color)
            Text(L10n.Settings.permissionIntroEn)
                .font(.footnote)
                .foregroundStyle(Theme.muted.color)

            permissionRow(L10n.Settings.permissionSpeech, en: L10n.Settings.permissionSpeechEn, value: L10n.Settings.permissionState(availability.speech))
            permissionRow(L10n.Settings.permissionMic, en: L10n.Settings.permissionMicEn, value: L10n.Settings.microphoneState(availability.microphone))
            permissionRow(
                L10n.Settings.permissionModel,
                en: L10n.Settings.permissionModelEn,
                value: L10n.Settings.modelState(supported: availability.onDeviceSupported),
                extra: availability.localeIdentifier
            )

            Text(availability.canDictate ? L10n.Settings.permissionReady : L10n.Settings.permissionNotReady)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.statusText.color)
            Text(availability.canDictate ? L10n.Settings.permissionReadyEn : L10n.Settings.permissionNotReadyEn)
                .font(.footnote)
                .foregroundStyle(Theme.muted.color)

            Button {
                requestingPermission = true
                Task {
                    availability = await OnDeviceSpeechAccess.request(language: model.language)
                    requestingPermission = false
                }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Settings.permissionRequest)
                        .font(.headline)
                    Text(L10n.Settings.permissionRequestEn)
                        .font(.footnote)
                }
                .foregroundStyle(Theme.onMic.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Theme.mic.color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(requestingPermission)
            .opacity(requestingPermission ? 0.55 : 1)

            if availability.speech == .denied || availability.speech == .restricted || availability.microphone == .denied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.Settings.permissionSettings)
                            .font(.headline)
                        Text(L10n.Settings.permissionSettingsEn)
                            .font(.footnote)
                    }
                    .foregroundStyle(Theme.cream.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Theme.quietKey.color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func permissionRow(_ zh: String, en: String, value: (String, String), extra: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(zh)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.cream.color)
                Text(en)
                    .font(.caption)
                    .foregroundStyle(Theme.muted.color)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(extra == nil ? value.0 : "\(value.0) · \(extra ?? "")")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.statusText.color)
                    .multilineTextAlignment(.trailing)
                Text(value.1)
                    .font(.caption)
                    .foregroundStyle(Theme.muted.color)
            }
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
            NavigationLink {
                PlaygroundView()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Playground.open)
                        .font(.headline)
                    Text(L10n.Playground.openEn)
                        .font(.footnote)
                }
                .foregroundStyle(Theme.onRewrite.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Theme.rewriteFill.color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
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

    private func bilingualLine(_ zh: String, en: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(zh)
                .foregroundStyle(Theme.cream.color)
            Text(en)
                .font(.footnote)
                .foregroundStyle(Theme.muted.color)
        }
    }

    private func disclosureCard<Content: View>(
        title: String,
        titleEn: String,
        symbol: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        DisclosureGroup(isExpanded: isExpanded) {
            content()
        } label: {
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
        }
        .tint(Theme.cream.color)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func identityRow(_ zh: String, en: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(zh) · \(en)")
                .font(.caption)
                .foregroundStyle(Theme.muted.color)
            Text(value)
                .font(.body.monospaced())
                .foregroundStyle(Theme.statusText.color)
                .textSelection(.enabled)
        }
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
