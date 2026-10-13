import KeyboardShared
import SwiftUI

struct OnboardingView: View {
    @State private var draft = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                tryCard
                sectionHeader(L10n.App.enableHeading, en: L10n.App.enableHeadingEn)
                VStack(spacing: 12) {
                    ForEach(L10n.App.steps) { step in
                        StepCard(step: step)
                    }
                }
                InfoCard(
                    symbol: "lock.open",
                    title: L10n.App.fullAccessTitle,
                    titleEn: L10n.App.fullAccessTitleEn,
                    body: L10n.App.fullAccessBody,
                    bodyEn: L10n.App.fullAccessBodyEn
                )
                InfoCard(
                    symbol: "mic.slash",
                    title: L10n.App.micTitle,
                    titleEn: L10n.App.micTitleEn,
                    body: L10n.App.micBody,
                    bodyEn: L10n.App.micBodyEn
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
                    Text("\(L10n.App.versionPrefix) \(AppIdentity.skeletonVersion)")
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
        }
        .padding(16)
        .background(cardBackground)
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
            .labelStyle(.titleAndIcon)

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
            identityRow("主 App 占位", en: "App placeholder", value: AppIdentity.appBundleIdentifier)
            identityRow("键盘扩展占位", en: "Keyboard placeholder", value: AppIdentity.keyboardBundleIdentifier)
            identityRow("App Group", en: "App Group", value: AppIdentity.appGroupIdentifier)
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
    let body: String
    let bodyEn: String

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
            Text(body)
                .font(.subheadline)
                .foregroundStyle(Theme.cream.color)
            Text(bodyEn)
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
    OnboardingView()
        .preferredColorScheme(.dark)
}
