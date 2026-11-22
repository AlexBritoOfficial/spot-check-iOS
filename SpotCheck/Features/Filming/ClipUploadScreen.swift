import SwiftUI

/// The canvas's `ClipUpload` artboard -- a filmer tagging and
/// delivering raw clips after a session. Make/bail tagging and the
/// resulting counts are local view state, as on the artboard; the
/// importers and delivery are intentionally unwired pending
/// per-feature planning.
struct ClipUploadScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var tags: [String: Bool] = [
        "C0041.MP4": false,
        "C0042.MP4": false,
        "C0043.MP4": true,
        "C0044.MP4": false,
        "C0045.MP4": true
    ]

    private var makeCount: Int { tags.values.filter { $0 }.count }
    private var bailCount: Int { tags.count - makeCount }

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Upload raw clips",
                subtitle: "Session with Rider Silva · Eggs · Today",
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    importButtons

                    Text("Full resolution, no compression. Tag each clip so the skater can skip straight to the makes.")
                        .font(.system(size: 12.5))
                        .lineSpacing(3)
                        .foregroundStyle(SCColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    SCSectionHeader("Clips") {
                        HStack(spacing: 0) {
                            Text("\(makeCount) makes")
                                .fontWeight(.bold)
                                .foregroundStyle(SCColor.success)
                            Text(" · \(bailCount) bails")
                                .foregroundStyle(SCColor.textSecondary)
                        }
                        .font(.system(size: 12.5))
                    }

                    VStack(spacing: 10) {
                        ForEach(ClipUploadScreen.clips) { clip in
                            clipRow(clip)
                        }
                    }
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }

            SCFooterBar {
                VStack(spacing: 10) {
                    Button("Deliver to Rider Silva") {}
                        .buttonStyle(.scPrimary)
                    Text("Delivering releases your payment from escrow.")
                        .font(.system(size: 12))
                        .foregroundStyle(SCColor.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var importButtons: some View {
        HStack(spacing: 10) {
            importButton(systemImage: "sdcard", title: "From SD card")
            importButton(systemImage: "folder", title: "From files")
        }
    }

    private func importButton(systemImage: String, title: String) -> some View {
        Button {} label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16))
                Text(title)
                    .font(SCFont.headingFixed(12.5))
            }
            .foregroundStyle(SCColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: SCRadius.control)
                    .stroke(SCColor.border, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func clipRow(_ clip: RawClip) -> some View {
        let isMake = tags[clip.name] ?? false

        return HStack(spacing: 12) {
            SCMediaPlaceholder(cornerRadius: 8)
                .frame(width: 64, height: 48)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(clip.name)
                    .font(SCFont.headingFixed(13))
                    .foregroundStyle(SCColor.textPrimary)
                Text(clip.meta)
                    .font(.system(size: 11.5))
                    .foregroundStyle(SCColor.textSecondary)
                Capsule()
                    .fill(SCColor.border)
                    .frame(height: 4)
                    .overlay(alignment: .leading) {
                        GeometryReader { proxy in
                            Capsule()
                                .fill(clip.progress == 1 ? SCColor.success : SCColor.accent)
                                .frame(width: proxy.size.width * clip.progress)
                        }
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 4) {
                tagButton(
                    "MAKE",
                    isActive: isMake,
                    activeBackground: SCColor.success,
                    activeForeground: SCColor.background
                ) {
                    tags[clip.name] = true
                }
                tagButton(
                    "BAIL",
                    isActive: !isMake,
                    activeBackground: SCColor.border,
                    activeForeground: SCColor.textPrimary
                ) {
                    tags[clip.name] = false
                }
            }
            .accessibilityLabel("Tag \(clip.name)")
        }
        .padding(10)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }

    private func tagButton(
        _ title: String,
        isActive: Bool,
        activeBackground: Color,
        activeForeground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(SCFont.headingFixed(10))
                .foregroundStyle(isActive ? activeForeground : SCColor.textSecondary)
                .frame(width: 58, height: 30)
                .background(isActive ? activeBackground : .clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isActive && activeBackground == SCColor.success ? SCColor.success : SCColor.border,
                            lineWidth: 1.5
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
    }
}

private struct RawClip: Identifiable {
    var id: String { name }
    let name: String
    let meta: String
    let progress: CGFloat
}

private extension ClipUploadScreen {
    static let clips: [RawClip] = [
        RawClip(name: "C0041.MP4", meta: "4K · 120fps · 0:18", progress: 1),
        RawClip(name: "C0042.MP4", meta: "4K · 120fps · 0:22", progress: 1),
        RawClip(name: "C0043.MP4", meta: "4K · 120fps · 0:16", progress: 1),
        RawClip(name: "C0044.MP4", meta: "4K · 60fps · 0:25", progress: 1),
        RawClip(name: "C0045.MP4", meta: "Uploading 64% · 4K · 120fps", progress: 0.64)
    ]
}

#Preview {
    ClipUploadScreen()
}
