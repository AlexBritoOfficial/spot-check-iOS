import SwiftUI

/// The canvas's `Feed` artboard -- a main tab destination. The artboard
/// also draws the bottom nav; that belongs to `SCBottomNavBar` in the
/// tab shell, so the scroll content only reserves
/// `SCMetric.bottomNavClearance` for it.
///
/// Content is the artboard's own sample data and actions are
/// intentionally unwired pending per-feature planning.
struct FeedScreen: View {
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 14) {
                    challengePromo

                    ForEach(FeedScreen.samplePosts) { post in
                        ClipCard(post: post)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, SCMetric.bottomNavClearance)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Feed")
                    .font(SCFont.heading(26))
                    .foregroundStyle(SCColor.textPrimary)
                Spacer()
                Button {} label: {
                    Image(systemName: "briefcase")
                        .font(.system(size: 19))
                        .foregroundStyle(SCColor.textPrimary)
                        .frame(width: 44, height: 44)
                        .overlay(alignment: .topTrailing) {
                            Circle()
                                .fill(SCColor.accent)
                                .frame(width: 9, height: 9)
                                .offset(x: -8, y: 9)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Opportunities, 2 new")
            }

            SCPillTabs(titles: ["For you", "Challenge", "Following"], selection: $selectedTab)
        }
        .padding(.horizontal, SCMetric.screenPadding)
        .padding(.top, SCMetric.headerTop(56))
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) { SCColor.border.frame(height: 1) }
    }

    private var challengePromo: some View {
        Button {} label: {
            HStack(spacing: 12) {
                Image(systemName: "trophy")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SCColor.background)
                    .frame(width: 44, height: 44)
                    .background(SCColor.accent)
                    .clipShape(RoundedRectangle(cornerRadius: SCRadius.control))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Flip In, Flip Out")
                        .font(SCFont.headingFixed(14))
                        .foregroundStyle(SCColor.textPrimary)
                    Text("November challenge · 9 days left · enter a clip")
                        .font(.system(size: 12.5))
                        .foregroundStyle(SCColor.textBody)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SCColor.accent)
            }
            .padding(14)
            .scCard(
                fill: SCColor.accent.opacity(0.1),
                borderColor: SCColor.accent,
                borderWidth: 1.5
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ClipCard: View {
    let post: FeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Avatar(
                    initial: post.skater,
                    size: 36,
                    backgroundColor: SCColor.border,
                    foregroundColor: SCColor.textPrimary
                )

                Button {} label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(post.skater)
                            .font(SCFont.headingFixed(13.5))
                            .foregroundStyle(SCColor.textPrimary)
                        HStack(spacing: 4) {
                            SCPinGlyph(height: 13)
                            Text(post.spot)
                                .font(.system(size: 12))
                                .foregroundStyle(SCColor.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                SCTag(
                    text: post.tag,
                    foreground: SCColor.background,
                    background: post.isFreshPick ? SCColor.success : SCColor.accent
                )
            }

            SCMediaPlaceholder(showsPlayBadge: true)
                .aspectRatio(4.0 / 5.0, contentMode: .fit)
                .accessibilityHidden(true)

            Text(post.caption)
                .font(.system(size: 14))
                .lineSpacing(3)
                .foregroundStyle(SCColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 4) {
                actionButton("heart", label: "Like")
                actionButton("bubble.left", label: "Comment")
                actionButton("arrow.up", label: "Share")
            }

            if let filmer = post.filmer {
                VStack(spacing: 0) {
                    SCColor.border.frame(height: 1)
                    HStack(spacing: 8) {
                        Group {
                            Text("Filmed by ")
                                .foregroundStyle(SCColor.textSecondary)
                                + Text(filmer).foregroundStyle(SCColor.textPrimary).bold()
                        }
                        .font(.system(size: 12.5))
                        .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 8)

                        Button {} label: {
                            Text("BOOK THIS FILMER")
                                .font(SCFont.headingFixed(11))
                                .foregroundStyle(SCColor.accent)
                                .padding(.horizontal, 12)
                                .frame(height: 32)
                                .overlay(Capsule().stroke(SCColor.accent, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 10)
                }
            }
        }
        .padding(12)
        .scCard()
    }

    private func actionButton(_ systemImage: String, label: String) -> some View {
        Button {} label: {
            Image(systemName: systemImage)
                .font(.system(size: 19))
                .foregroundStyle(SCColor.textPrimary)
                .frame(width: 44, height: 40)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct FeedPost: Identifiable {
    let id = UUID()
    let skater: String
    let spot: String
    let tag: String
    let isFreshPick: Bool
    let caption: String
    let filmer: String?
}

private extension FeedScreen {
    static let samplePosts: [FeedPost] = [
        FeedPost(
            skater: "Rider Silva",
            spot: "Eggs",
            tag: "Flip in, flip out",
            isFreshPick: false,
            caption: "Kickflip in, crooked grind, flip out. Took 40 tries.",
            filmer: "Rider Okafor"
        ),
        FeedPost(
            skater: "Rider Chen",
            spot: "Lynch Family Skatepark",
            tag: "Fresh pick",
            isFreshPick: true,
            caption: "Late-night line at the park before close.",
            filmer: nil
        )
    ]
}

#Preview {
    FeedScreen()
}
