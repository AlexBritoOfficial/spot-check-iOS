import SwiftUI

/// The canvas's `Rating` artboard -- the two-way post-session rating.
/// The artboard has an editing state and a submitted confirmation; both
/// are local view state here, and nothing is persisted pending
/// per-feature planning.
struct RatingScreen: View {
    @Environment(\.dismiss) private var dismiss

    @State private var rating = 5
    @State private var highlights: Set<String> = ["On time", "Steady follow-lines"]
    @State private var comment = ""
    @State private var hasSubmitted = false

    private var ratingCaption: String {
        switch rating {
        case 1: "Rough session"
        case 2: "Not great"
        case 3: "Solid"
        case 4: "Great session"
        default: "Perfect session"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            SCNavHeader(
                title: "Rate your session",
                subtitle: "Rider Okafor · Eggs · Today",
                onBack: { dismiss() }
            )

            if hasSubmitted {
                confirmation
                SCFooterBar {
                    Button("Back to the map") { dismiss() }
                        .buttonStyle(.scSecondary(fontSize: 14.5))
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ratingBlock
                        highlightsSection

                        VStack(alignment: .leading, spacing: 8) {
                            Text("ANYTHING ELSE? (OPTIONAL)").scFieldLabel()
                            SCTextArea(
                                placeholder: "Shared with Rider Okafor once you've both rated",
                                text: $comment,
                                accessibilityTitle: "Anything else?"
                            )
                        }

                        SCNoteRow(
                            text: "Ratings stay hidden until you've both submitted. Neither of you sees the other's until then.",
                            systemImage: "eye"
                        )
                    }
                    .padding(.horizontal, SCMetric.screenPadding)
                    .padding(.top, 18)
                    .padding(.bottom, 24)
                }

                SCFooterBar {
                    Button("Submit rating") { hasSubmitted = true }
                        .buttonStyle(.scPrimary(fontSize: 14.5))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
    }

    private var ratingBlock: some View {
        VStack(spacing: 12) {
            Avatar(
                initial: "O",
                size: 72,
                backgroundColor: SCColor.border,
                foregroundColor: SCColor.textPrimary
            )

            Text("How was filming with Rider Okafor?")
                .font(SCFont.heading(20))
                .foregroundStyle(SCColor.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            SCStarPicker(
                rating: $rating,
                starSize: 36,
                spacing: 6,
                accessibilityTitle: "Session rating"
            )

            Text(ratingCaption)
                .font(.system(size: 13))
                .foregroundStyle(SCColor.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var highlightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT STOOD OUT").scSectionLabel()
            FlowChips(spacing: 8) {
                ForEach(RatingScreen.highlightOptions, id: \.self) { option in
                    let isActive = highlights.contains(option)
                    Button {
                        if isActive {
                            highlights.remove(option)
                        } else {
                            highlights.insert(option)
                        }
                    } label: {
                        Text(option.uppercased())
                            .font(SCFont.headingFixed(11.5))
                            .foregroundStyle(isActive ? SCColor.background : SCColor.textPrimary)
                            .padding(.horizontal, 14)
                            .frame(height: 40)
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

    private var confirmation: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(SCColor.success)
                .frame(width: 64, height: 64)
                .background(SCColor.success.opacity(0.15))
                .clipShape(Circle())

            Text("Rating saved")
                .font(SCFont.heading(22))
                .foregroundStyle(SCColor.textPrimary)

            Text("Waiting for Rider Okafor to rate you. Both ratings appear, and averages update, once you've both submitted.")
                .font(.system(size: 15))
                .lineSpacing(4)
                .foregroundStyle(SCColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension RatingScreen {
    static let highlightOptions = [
        "On time",
        "Steady follow-lines",
        "Knew the spot",
        "Fast delivery",
        "Good with security"
    ]
}

#Preview("Editing") {
    RatingScreen()
}
