import KeyboardShared
import SwiftUI
import UIKit

struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openURL) private var openURL
    @State private var draft = ""
    @State private var isSampling = false
    @State private var sampleNote = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                sectionHeader(L10n.App.enableHeading, en: L10n.App.enableHeadingEn)
                VStack(spacing: 12) {
                    ForEach(L10n.App.steps) { step in
                        StepCard(step: step)
                    }
                }
                fullAccessCard
                settingsEntry
                tryCard
                playgroundEntry
                InfoCard(
                    symbol: "mic",
                    title: L10n.App.micTitle,
                    titleEn: L10n.App.micTitleEn,
                    message: L10n.App.micBody,
                    messageEn: L10n.App.micBodyEn
                )
                scopeCard
                identityCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.canvas.color)
        .navigationTitle(AppIdentity.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Text(L10n.App.settingsButton)
                }
            }
        }
        .toolbarBackground(Theme.canvas.color, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.mic.color)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "keyboard")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.onMic.color)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    Text(AppIdentity.englishName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.muted.color)
                    Text("\(L10n.App.versionPrefix) \(AppIdentity.releaseVersion)")
                        .font(.caption)
                        .foregroundStyle(Theme.muted.color)
                }
            }
            Text(AppIdentity.displayName)
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Theme.cream.color)
            Text(L10n.App.eyebrow)
                .font(.headline)
                .foregroundStyle(Theme.statusText.color)
            Text(L10n.App.eyebrowEn)
                .font(.subheadline)
                .foregroundStyle(Theme.muted.color)
            Text(L10n.App.lead)
                .font(.body)
                .foregroundStyle(Theme.cream.color)
                .padding(.top, 4)
            Text(L10n.App.leadEn)
                .font(.subheadline)
                .foregroundStyle(Theme.muted.color)
        }
    }

    private var fullAccessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.App.fullAccessTitle)
                        .font(.headline)
                    Text(L10n.App.fullAccessTitleEn)
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted.color)
                }
            } icon: {
                Image(systemName: "lock.open")
            }
            .foregroundStyle(Theme.cream.color)

            Text(L10n.App.fullAccessIntro)
                .font(.subheadline)
                .foregroundStyle(Theme.cream.color)
            Text(L10n.App.fullAccessIntroEn)
                .font(.footnote)
                .foregroundStyle(Theme.muted.color)

            compareColumn(L10n.App.willHeading, en: L10n.App.willHeadingEn, items: L10n.App.fullAccessWill, symbol: "checkmark")
            compareColumn(L10n.App.wontHeading, en: L10n.App.wontHeadingEn, items: L10n.App.fullAccessWont, symbol: "xmark")

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.App.systemSettings)
                        .font(.headline)
                    Text(L10n.App.systemSettingsEn)
                        .font(.footnote)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Theme.quietKey.color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.cream.color)

            Text(L10n.App.systemSettingsNote)
                .font(.footnote)
                .foregroundStyle(Theme.cream.color)
            Text(L10n.App.systemSettingsNoteEn)
                .font(.footnote)
                .foregroundStyle(Theme.muted.color)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private func compareColumn(_ title: String, en: String, items: [(String, String)], symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.statusText.color)
            Text(en)
                .font(.caption)
                .foregroundStyle(Theme.muted.color)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Theme.statusText.color)
                        .padding(.top, 3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.0)
                            .font(.subheadline)
                            .foregroundStyle(Theme.cream.color)
                        Text(item.1)
                            .font(.footnote)
                            .foregroundStyle(Theme.muted.color)
                    }
                }
            }
        }
    }

    private var settingsEntry: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(L10n.App.openSettingsTitle, en: L10n.App.openSettingsTitleEn)
            Text(L10n.App.openSettingsBody)
                .font(.subheadline)
                .foregroundStyle(Theme.cream.color)
            Text(L10n.App.openSettingsBodyEn)
                .font(.footnote)
                .foregroundStyle(Theme.muted.color)
            NavigationLink {
                SettingsView()
            } label: {
                Text(L10n.App.settingsButton)
                    .font(.headline)
                    .foregroundStyle(Theme.onMic.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.mic.color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var tryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(L10n.App.tryTitle, en: L10n.App.tryTitleEn)
            Text(L10n.App.tryBody)
                .font(.subheadline)
                .foregroundStyle(Theme.cream.color)
            Text(L10n.App.tryBodyEn)
                .font(.footnote)
                .foregroundStyle(Theme.muted.color)
            TextField(L10n.App.tryPlaceholder, text: $draft, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Theme.canvas.color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Theme.hairline.color, lineWidth: 1)
                }
                .foregroundStyle(Theme.cream.color)

            HStack(spacing: 8) {
                sampleButton(
                    model.demoModeEnabled ? L10n.App.insertSample : L10n.App.dictateNow,
                    en: model.demoModeEnabled ? L10n.App.insertSampleEn : L10n.App.dictateNowEn,
                    fill: Theme.mic.color,
                    foreground: Theme.onMic.color
                ) {
                    await insertSample()
                }
                sampleButton(L10n.App.rewriteSample, en: L10n.App.rewriteSampleEn, fill: Theme.rewriteFill.color, foreground: Theme.onRewrite.color) {
                    await rewriteDraft()
                }
            }
            .disabled(isSampling)
            .opacity(isSampling ? 0.55 : 1)

            if !sampleNote.isEmpty {
                Text(sampleNote)
                    .font(.footnote)
                    .foregroundStyle(Theme.statusText.color)
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private var playgroundEntry: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(L10n.Playground.title, en: L10n.Playground.titleEn)
            Text(L10n.Playground.intro)
                .font(.subheadline)
                .foregroundStyle(Theme.cream.color)
            Text(L10n.Playground.privacy)
                .font(.footnote)
                .foregroundStyle(Theme.statusText.color)
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

    private func sampleButton(
        _ title: String,
        en: String,
        fill: Color,
        foreground: Color,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(en)
                    .font(.caption2)
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var scopeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.App.scopeTitle)
                        .font(.headline)
                    Text(L10n.App.scopeTitleEn)
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted.color)
                }
            } icon: {
                Image(systemName: "shippingbox")
            }
            .foregroundStyle(Theme.cream.color)

            ForEach(Array(L10n.App.scopeItems.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.0)
                        .foregroundStyle(Theme.cream.color)
                    Text(item.1)
                        .font(.footnote)
                        .foregroundStyle(Theme.muted.color)
                }
            }

            Text(LanguageModelStub.scopeNote)
                .font(.footnote.monospaced())
                .foregroundStyle(Theme.statusText.color)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.App.idTitle)
                    .font(.headline)
                    .foregroundStyle(Theme.cream.color)
                Text(L10n.App.idTitleEn)
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted.color)
            }
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    @MainActor
    private func insertSample() async {
        let demo = model.demoModeEnabled
        isSampling = true
        sampleNote = demo
            ? "\(L10n.App.sampling)\n\(L10n.App.samplingEn)"
            : "\(L10n.App.listening)\n\(L10n.App.listeningEn)"
        defer { isSampling = false }
        do {
            let utterance = try await SpeechEngines.make(demoMode: demo).transcribe(language: model.language)
            let text = utterance.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                sampleNote = "\(L10n.Keyboard.voiceEmptyTitle)\n\(L10n.Keyboard.voiceEmptyDetail)"
                return
            }
            draft = draft.isEmpty ? text : draft + text
            sampleNote = ""
        } catch is CancellationError {
            sampleNote = ""
        } catch let failure as SpeechFailure {
            let copy = L10n.Keyboard.speechFailure(for: failure)
            sampleNote = "\(copy.title)\n\(copy.detail)"
        } catch {
            sampleNote = "\(L10n.App.demoFailedNote)\n\(L10n.App.demoFailedNoteEn)"
        }
    }

    @MainActor
    private func rewriteDraft() async {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            sampleNote = "\(L10n.App.emptyRewrite)\n\(L10n.App.emptyRewriteEn)"
            return
        }
        isSampling = true
        sampleNote = "\(L10n.Keyboard.rewriteWorkingTitle(.polish))\n\(L10n.Keyboard.rewriteWorkingDetail)"
        defer { isSampling = false }
        do {
            let passage = try await AppleIntelligenceRewrite.rewrite(draft, language: model.language, tone: .polish)
            draft = passage.text
            sampleNote = ""
        } catch is CancellationError {
            sampleNote = ""
        } catch is RewriteFailure {
            sampleNote = "\(L10n.App.emptyRewrite)\n\(L10n.App.emptyRewriteEn)"
        } catch {
            sampleNote = "\(L10n.App.demoFailedNote)\n\(L10n.App.demoFailedNoteEn)"
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

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Theme.card.color)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.hairline.color, lineWidth: 1)
            }
    }
}

private struct StepCard: View {
    let step: SetupStep

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(step.id)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(Theme.onMic.color)
                .frame(width: 32, height: 32)
                .background(Theme.mic.color, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.headline)
                    .foregroundStyle(Theme.cream.color)
                Text(step.titleEn)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.statusText.color)
                Text(step.detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.cream.color)
                Text(step.detailEn)
                    .font(.footnote)
                    .foregroundStyle(Theme.muted.color)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.card.color)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.hairline.color, lineWidth: 1)
                }
        )
    }
}

private struct InfoCard: View {
    let symbol: String
    let title: String
    let titleEn: String
    let message: String
    let messageEn: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.cream.color)
            Text(messageEn)
                .font(.footnote)
                .foregroundStyle(Theme.muted.color)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.card.color)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.hairline.color, lineWidth: 1)
                }
        )
    }
}

#Preview {
    NavigationStack {
        OnboardingView()
    }
    .environmentObject(AppModel(writesToSharedStore: false))
    .preferredColorScheme(.dark)
}
