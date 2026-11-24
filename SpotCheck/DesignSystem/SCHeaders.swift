import SwiftUI

/// The canvas's screen header: an optional 44pt back chevron, a title
/// (plus optional subtitle), an optional trailing control, and the 1px
/// divider underneath. Replaces the system navigation bar on the newer
/// screens, which the canvas draws entirely itself.
struct SCNavHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    var titleSize: CGFloat = 18
    var showsDivider: Bool = true
    var canvasTopOffset: CGFloat = 52
    var onBack: (() -> Void)?
    @ViewBuilder var trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        titleSize: CGFloat = 18,
        showsDivider: Bool = true,
        canvasTopOffset: CGFloat = 52,
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.titleSize = titleSize
        self.showsDivider = showsDivider
        self.canvasTopOffset = canvasTopOffset
        self.onBack = onBack
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 6) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(SCColor.textPrimary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SCFont.heading(titleSize))
                    .foregroundStyle(SCColor.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12.5))
                        .foregroundStyle(SCColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing()
        }
        .padding(.leading, onBack == nil ? SCMetric.screenPadding : 10)
        .padding(.trailing, 10)
        .padding(.top, SCMetric.headerTop(canvasTopOffset))
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            if showsDivider {
                SCColor.border.frame(height: 1)
            }
        }
    }
}

/// The uppercase tracked label above each section of a screen
/// ("SPONSORSHIP LADDER", "WHO CAN SEE IT"), with an optional trailing
/// text action on the same baseline.
struct SCSectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .scSectionLabel()
            Spacer()
            trailing()
        }
    }
}

private struct SectionLabelStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(SCFont.headingFixed(12))
            .tracking(1)
            .foregroundStyle(SCColor.textSecondary)
    }
}

extension View {
    func scSectionLabel() -> some View {
        modifier(SectionLabelStyle())
    }
}

/// Small icon-plus-muted-copy footnote (PostClip's privacy and audio
/// notes, FilmBooking's cancellation terms).
struct SCNoteRow: View {
    let text: String
    var systemImage: String = "info.circle"
    var iconColor: Color = SCColor.textSecondary

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(iconColor)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 12.5))
                .lineSpacing(3)
                .foregroundStyle(SCColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// The sticky action tray the canvas docks at the bottom of form and
/// detail screens: a top divider, then one or more controls.
struct SCFooterBar<Content: View>: View {
    var spacing: CGFloat = 10
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            SCColor.border.frame(height: 1)
            HStack(spacing: spacing) {
                content()
            }
            .padding(.horizontal, SCMetric.screenPadding)
            .padding(.top, 14)
            .padding(.bottom, 10)
        }
        .background(SCColor.background)
    }
}

#Preview {
    VStack(spacing: 0) {
        SCNavHeader(title: "Post a clip", subtitle: "Ready in a few taps", onBack: {})
        SCNavHeader(title: "Feed", titleSize: 26, canvasTopOffset: 56) {
            SCCircleIconButton(
                systemImage: "tray.full",
                accessibilityTitle: "Opportunities",
                background: .clear
            ) {}
        }
        VStack(alignment: .leading, spacing: 14) {
            SCSectionHeader("Sponsorship ladder") {
                Button("Add a step") {}
                    .font(.system(size: 13))
                    .foregroundStyle(SCColor.accent)
            }
            SCNoteRow(
                text: "Only verified members see spot tags. We strip GPS and location data from every upload.",
                systemImage: "lock.fill",
                iconColor: SCColor.success
            )
        }
        .padding(20)
        Spacer()
        SCFooterBar {
            Button("Post") {}.buttonStyle(.scPrimary(fontSize: 14.5))
        }
    }
    .background(SCColor.background)
}
