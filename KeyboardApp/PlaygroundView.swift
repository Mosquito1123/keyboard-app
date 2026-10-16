import KeyboardShared
import SwiftUI

/// In-app surface for dictation and tone rewrite. It does not require the keyboard
/// extension, Full Access, or an App Group, so it still works on a Personal Team.
struct PlaygroundView: View {
    @EnvironmentObject private var model: AppModel
    @State private var draft = ""
    @State private var note = ""
    @State private var engineNote = ""
    @State private var busy = false
    @State private var intelligenceAvailable = false

    private let tones: [RewriteTone] = [.polish, .shorter, .formal, .casual]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                intro
                editor
                dictateButton
                toneGrid
                if !note.isEmpty {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(Theme.statusText.color)
                }
                if !engineNote.isEmpty {
                    Text(engineNote)
                        .font(.footnote.monospaced())
                        .foregroundStyle(Theme.muted.color)
                }
                statusCard
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.canvas.color)
        .navigationTitle(L10n.Playground.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.canvas.color, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            intelligenceAvailable = AppleIntelligenceRewrite.systemModelAvailable
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Playground.titleEn)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.muted.color)
            Text(L10n.Playground.intro)
                .font(.body)
                .foregroundStyle(Theme.cream.color)
            Text(L10n.Playground.introEn)
                .font(.footnote)
                .foregroundStyle(Theme.muted.color)
            Text(L10n.Playground.privacy)
                .font(.subheadline)
                .foregroundStyle(Theme.statusText.color)
            Text(L10n.Playground.privacyEn)
                .font(.footnote)
                .foregroundStyle(Theme.muted.color)
        }
    }

    private var editor: some View {
        TextField(L10n.Playground.placeholder, text: $draft, axis: .vertical)
            .lineLimit(5...10)
            .textFieldStyle(.plain)
            .padding(14)
            .background(Theme.card.color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.hairline.color, lineWidth: 1)
            }
            .foregroundStyle(Theme.cream.color)
    }

    private var dictateButton: some View {
        Button {
            Task { await dictate() }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.demoModeEnabled ? L10n.App.insertSample : L10n.Playground.dictate)
                    .font(.headline)
                Text(model.demoModeEnabled ? L10n.App.insertSampleEn : L10n.Playground.dictateEn)
                    .font(.footnote)
            }
            .foregroundStyle(Theme.onMic.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Theme.mic.color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(busy)
        .opacity(busy ? 0.55 : 1)
    }

    private var toneGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(tones) { tone in
                    Button {
                        Task { await rewrite(tone) }
                    } label: {
                        VStack(spacing: 2) {
                            Text(tone.title.zh)
                                .font(.subheadline.weight(.semibold))
                            Text(tone.title.en)
                                .font(.caption2)
                        }
                        .foregroundStyle(Theme.onRewrite.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.rewriteFill.color, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(busy || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .opacity(busy || draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.demoModeEnabled ? L10n.Playground.demoNote : L10n.Settings.demoOffDetail)
                .font(.footnote)
                .foregroundStyle(Theme.cream.color)
            Text(model.demoModeEnabled ? L10n.Playground.demoNoteEn : L10n.Settings.demoOffDetailEn)
                .font(.caption)
                .foregroundStyle(Theme.muted.color)
            Text(intelligenceAvailable ? L10n.Playground.intelligenceOn : L10n.Playground.intelligenceOff)
                .font(.footnote)
                .foregroundStyle(Theme.statusText.color)
            Text(intelligenceAvailable ? L10n.Playground.intelligenceOnEn : L10n.Playground.intelligenceOffEn)
                .font(.caption)
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

    @MainActor
    private func dictate() async {
        let demo = model.demoModeEnabled
        busy = true
        engineNote = ""
        note = demo
            ? "\(L10n.App.sampling)\n\(L10n.App.samplingEn)"
            : "\(L10n.App.listening)\n\(L10n.App.listeningEn)"
        defer { busy = false }
        do {
            let utterance = try await SpeechEngines.make(demoMode: demo).transcribe(language: model.language)
            let text = utterance.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                note = "\(L10n.Keyboard.voiceEmptyTitle)\n\(L10n.Keyboard.voiceEmptyDetail)"
                return
            }
            draft = draft.isEmpty ? text : draft + text
            note = ""
            engineNote = L10n.Playground.engineLine(utterance.engineName)
        } catch is CancellationError {
            note = ""
        } catch let failure as SpeechFailure {
            let copy = L10n.Keyboard.speechFailure(for: failure)
            note = "\(copy.title)\n\(copy.detail)"
        } catch {
            note = "\(L10n.App.demoFailedNote)\n\(L10n.App.demoFailedNoteEn)"
        }
    }

    @MainActor
    private func rewrite(_ tone: RewriteTone) async {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            note = "\(L10n.Playground.empty)\n\(L10n.Playground.emptyEn)"
            engineNote = ""
            return
        }
        busy = true
        note = "\(L10n.Keyboard.rewriteWorkingTitle(tone))\n\(L10n.Keyboard.rewriteWorkingDetail)"
        defer { busy = false }
        do {
            let passage = try await AppleIntelligenceRewrite.rewrite(draft, language: model.language, tone: tone)
            draft = passage.text
            note = L10n.Keyboard.rewriteDoneTitle(tone)
            engineNote = L10n.Playground.engineLine(passage.engineName)
        } catch is CancellationError {
            note = ""
        } catch is RewriteFailure {
            note = "\(L10n.Playground.empty)\n\(L10n.Playground.emptyEn)"
        } catch {
            note = "\(L10n.Playground.failed)\n\(L10n.Playground.failedEn)"
        }
    }
}

#Preview {
    NavigationStack {
        PlaygroundView()
    }
    .environmentObject(AppModel(writesToSharedStore: false))
    .preferredColorScheme(.dark)
}
