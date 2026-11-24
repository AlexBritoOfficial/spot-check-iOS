import SwiftUI

/// The 34pt pill tab row the canvas uses above a list (Feed's FOR YOU /
/// CHALLENGE / FOLLOWING, Opportunities, ClipVault). Shorter and
/// tighter than `Chip`, which is the map's 36pt filter pill.
struct SCPillTabs: View {
    let titles: [String]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                let isActive = index == selection
                Button {
                    selection = index
                } label: {
                    Text(title.uppercased())
                        .font(SCFont.headingFixed(11))
                        .foregroundStyle(isActive ? SCColor.background : SCColor.textPrimary)
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(isActive ? SCColor.accent : .clear)
                        .overlay(
                            Capsule().stroke(isActive ? SCColor.accent : SCColor.border, lineWidth: 1.5)
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
            }
        }
    }
}

/// The inset two-up tray used for mutually exclusive choices with a
/// caption each (PostClip's public/private, FilmBooking's session
/// type): a bordered container holding 52pt options.
struct SCSegmentedTray: View {
    struct Option: Identifiable {
        let id = UUID()
        let label: String
        let caption: String?

        init(label: String, caption: String? = nil) {
            self.label = label
            self.caption = caption
        }
    }

    let options: [Option]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                let isActive = index == selection
                Button {
                    selection = index
                } label: {
                    VStack(spacing: 2) {
                        Text(option.label)
                            .font(SCFont.headingFixed(13))
                        if let caption = option.caption {
                            Text(caption)
                                .font(.system(size: 11.5))
                                .opacity(0.85)
                        }
                    }
                    .foregroundStyle(isActive ? SCColor.background : SCColor.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(isActive ? SCColor.accent : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(4)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }
}

/// A numbered progress list (ProApply's four onboarding steps,
/// SkaterPortfolio's sponsorship ladder): filled gold circles for the
/// reached steps, outlined for the ones still ahead.
struct SCStepList: View {
    struct Step: Identifiable {
        let id = UUID()
        let title: String
        var detail: String?
        var isReached: Bool
        var trailingNote: String?
        var trailingNoteColor: Color = SCColor.textSecondary
        var trailingNoteSystemImage: String?

        init(
            title: String,
            detail: String? = nil,
            isReached: Bool = false,
            trailingNote: String? = nil,
            trailingNoteColor: Color = SCColor.textSecondary,
            trailingNoteSystemImage: String? = nil
        ) {
            self.title = title
            self.detail = detail
            self.isReached = isReached
            self.trailingNote = trailingNote
            self.trailingNoteColor = trailingNoteColor
            self.trailingNoteSystemImage = trailingNoteSystemImage
        }
    }

    let steps: [Step]
    /// The canvas has two forms of this list: a plain gap-separated run
    /// of steps (ProApply) and one divided by hairlines (the
    /// sponsorship ladder).
    var showsDividers: Bool = false
    var markerSize: CGFloat = 26

    var body: some View {
        VStack(alignment: .leading, spacing: showsDividers ? 0 : 12) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(spacing: 12) {
                    marker(number: index + 1, isReached: step.isReached)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(.system(size: 14, weight: showsDividers ? .semibold : .regular))
                            .foregroundStyle(step.isReached ? SCColor.textPrimary : SCColor.textBody)
                        if let detail = step.detail {
                            Text(detail)
                                .font(.system(size: 12))
                                .foregroundStyle(SCColor.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if let note = step.trailingNote {
                        HStack(spacing: 4) {
                            if let image = step.trailingNoteSystemImage {
                                Image(systemName: image)
                                    .font(.system(size: 11, weight: .bold))
                            }
                            Text(note)
                                .font(.system(size: 11.5, weight: .bold))
                        }
                        .foregroundStyle(step.trailingNoteColor)
                    }
                }
                .padding(.vertical, showsDividers ? 10 : 0)
                .overlay(alignment: .top) {
                    if showsDividers {
                        SCColor.border.frame(height: 1)
                    }
                }
            }
        }
    }

    private func marker(number: Int, isReached: Bool) -> some View {
        Text("\(number)")
            .font(SCFont.headingFixed(12))
            .foregroundStyle(isReached ? SCColor.background : SCColor.textSecondary)
            .frame(width: markerSize, height: markerSize)
            .background(isReached ? SCColor.accent : .clear)
            .overlay(
                Circle().stroke(isReached ? .clear : SCColor.border, lineWidth: 1.5)
            )
            .clipShape(Circle())
    }
}

/// The canvas's status timeline: a vertical run of steps whose markers
/// carry state, optionally joined by a connecting rule.
///
/// Distinct from `SCStepList`, whose markers are always numbers and which
/// never draws a connector. This is what Checkout's "WHEN YOU'RE CHARGED",
/// TransactionDetail's "STATUS" and Verification's checklist all draw.
struct SCTimeline: View {
    enum Marker {
        /// Finished: filled green with a check.
        case done
        /// The step the user is waiting on: a thick accent ring.
        case current
        /// Not started: a hairline ring.
        case pending
        /// Under review: a three-quarter accent arc.
        case inProgress
        /// Gated behind an earlier step.
        case locked
        case numbered(Int)
    }

    /// The canvas uses Archivo Black titles on Verification's checklist and
    /// semibold body titles on the payment timelines.
    enum TitleStyle {
        case body, heading
    }

    struct Step: Identifiable {
        let id = UUID()
        let title: String
        var detail: String?
        var detailColor: Color = SCColor.textSecondary
        var marker: Marker

        init(
            title: String,
            detail: String? = nil,
            detailColor: Color = SCColor.textSecondary,
            marker: Marker
        ) {
            self.title = title
            self.detail = detail
            self.detailColor = detailColor
            self.marker = marker
        }
    }

    let steps: [Step]
    var showsConnector: Bool = true
    var titleStyle: TitleStyle = .body
    var markerSize: CGFloat = 24
    var spacing: CGFloat = 14

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                let isLast = index == steps.count - 1

                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        markerView(step.marker)
                        if showsConnector && !isLast {
                            Rectangle()
                                .fill(SCColor.border)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: markerSize)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title)
                            .font(titleFont)
                            .foregroundStyle(SCColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        if let detail = step.detail {
                            Text(detail)
                                .font(.system(size: detailSize))
                                .foregroundStyle(step.detailColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, isLast ? 0 : spacing)

                    Spacer(minLength: 0)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var titleFont: Font {
        switch titleStyle {
        case .body: .system(size: 14, weight: .semibold)
        case .heading: SCFont.headingFixed(14)
        }
    }

    private var detailSize: CGFloat {
        titleStyle == .heading ? 13 : 12.5
    }

    @ViewBuilder
    private func markerView(_ marker: Marker) -> some View {
        switch marker {
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: markerSize * 0.46, weight: .black))
                .foregroundStyle(SCColor.background)
                .frame(width: markerSize, height: markerSize)
                .background(SCColor.success)
                .clipShape(Circle())
        case .current:
            Circle()
                .stroke(SCColor.accent, lineWidth: 2.5)
                .frame(width: markerSize, height: markerSize)
        case .pending:
            Circle()
                .stroke(SCColor.border, lineWidth: 1.5)
                .frame(width: markerSize, height: markerSize)
        case .inProgress:
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(SCColor.accent, lineWidth: 2.5)
                .rotationEffect(.degrees(-90))
                .frame(width: markerSize, height: markerSize)
        case .locked:
            Image(systemName: "lock.fill")
                .font(.system(size: markerSize * 0.42, weight: .bold))
                .foregroundStyle(SCColor.textSecondary)
                .frame(width: markerSize, height: markerSize)
                .overlay(Circle().stroke(SCColor.border, lineWidth: 1.5))
        case .numbered(let number):
            Text("\(number)")
                .font(SCFont.headingFixed(markerSize * 0.46))
                .foregroundStyle(SCColor.background)
                .frame(width: markerSize, height: markerSize)
                .background(SCColor.accent)
                .clipShape(Circle())
        }
    }
}

/// A labeled switch row inside a card (PostClip's challenge entry,
/// FilmerRates' availability toggles).
struct SCToggleRow: View {
    let title: String
    var caption: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                if let caption {
                    Text(caption)
                        .font(.system(size: 12.5))
                        .foregroundStyle(SCColor.textSecondary)
                }
            }
        }
        .tint(SCColor.accent)
    }
}

#Preview {
    @Previewable @State var tab = 0
    @Previewable @State var visibility = 0
    @Previewable @State var entered = true

    return VStack(alignment: .leading, spacing: 20) {
        SCPillTabs(titles: ["For you", "Challenge", "Following"], selection: $tab)

        SCSegmentedTray(
            options: [
                .init(label: "Public", caption: "Members can watch"),
                .init(label: "Private", caption: "Only people you invite")
            ],
            selection: $visibility
        )

        SCStepList(steps: [
            .init(title: "Show your gear and portfolio", isReached: true),
            .init(title: "Verify your ID"),
            .init(title: "Pass a background check"),
            .init(title: "Set your rates and go live")
        ])

        SCStepList(
            steps: [
                .init(
                    title: "Shop Sponsor",
                    detail: "Bricktown Skate Shop",
                    isReached: true,
                    trailingNote: "Verified",
                    trailingNoteColor: SCColor.success,
                    trailingNoteSystemImage: "checkmark"
                ),
                .init(title: "Flow", detail: "Low Tide Wheels", isReached: true, trailingNote: "Self-reported"),
                .init(title: "Am", detail: "Official team rider")
            ],
            showsDividers: true,
            markerSize: 28
        )

        SCToggleRow(
            title: "Enter Flip In, Flip Out",
            caption: "November challenge · free entry",
            isOn: $entered
        )
        .padding(16)
        .scCard(cornerRadius: SCRadius.cardSmall)
    }
    .padding(20)
    .background(SCColor.background)
}
