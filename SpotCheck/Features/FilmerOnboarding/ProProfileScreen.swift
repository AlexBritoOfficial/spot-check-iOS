import SwiftUI

/// The canvas's `ProProfile` artboard -- a filmer's public profile, as
/// a skater sees it before requesting a session. Rates stay the
/// artboard's `$[RATE]` placeholder.
///
/// "Request a session" opens booking with the request named for this filmer.
/// It needs to know who the filmer is, so it stays disabled until whatever
/// opens this screen passes one -- nothing does yet, since the screen still
/// shows the artboard's sample profile.
struct ProProfileScreen: View {
    var filmer: FilmBookingScreen.RequestedFilmer?

    @Environment(\.dismiss) private var dismiss
    @State private var showsFilmBooking = false

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    identity
                    serviceSection
                    worksAtSection
                    portfolioSection
                }
                .padding(.horizontal, SCMetric.screenPadding)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SCColor.background)
        .sheet(isPresented: $showsFilmBooking) {
            if let filmer {
                FilmBookingScreen(requestedFilmer: filmer)
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(SCColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Spacer()

            Button {} label: {
                Image(systemName: "bubble.left")
                    .font(.system(size: 19))
                    .foregroundStyle(SCColor.textPrimary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Message Rider Okafor")
        }
        .padding(.horizontal, 10)
        .padding(.top, SCMetric.headerTop(52))
    }

    private var identity: some View {
        HStack(spacing: 16) {
            Avatar(
                initial: "O",
                size: 80,
                ringColor: SCColor.accent,
                backgroundColor: SCColor.border,
                foregroundColor: SCColor.textPrimary
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Rider Okafor")
                        .font(SCFont.heading(22))
                        .foregroundStyle(SCColor.textPrimary)
                    SCTag(text: "Filmer")
                }
                Text("@rider.okafor · Boston")
                    .font(.system(size: 13.5))
                    .foregroundStyle(SCColor.textSecondary)

                HStack(spacing: 5) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Background checked")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(SCColor.success)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(SCColor.success.opacity(0.12))
                .clipShape(Capsule())
            }
        }
    }

    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FILMING & PHOTOS").scSectionLabel()

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Filming & photos")
                            .font(SCFont.headingFixed(16))
                            .foregroundStyle(SCColor.textPrimary)
                        Text("Street sessions, park drop-ins and full edits")
                            .font(.system(size: 13))
                            .foregroundStyle(SCColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                            Text("Pro gear & portfolio verified")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(SCColor.success)
                        .padding(.top, 4)

                        FlowChips(spacing: 6) {
                            ForEach(ProProfileScreen.styleTags, id: \.self) { tag in
                                outlinedTag(tag, color: SCColor.accent)
                            }
                        }
                        .padding(.top, 6)

                        FlowChips(spacing: 6) {
                            ForEach(ProProfileScreen.gearTags, id: \.self) { tag in
                                outlinedTag(tag, color: SCColor.textPrimary)
                            }
                        }
                    }

                    Text("from $[RATE]")
                        .font(SCFont.headingFixed(14))
                        .foregroundStyle(SCColor.accent)
                        .fixedSize()
                }

                Button("Request a session") { showsFilmBooking = true }
                    .buttonStyle(.scPrimary(fontSize: 14))
                    .frame(height: 46)
                    .disabled(filmer == nil)
            }
            .padding(16)
            .scCard()
        }
    }

    private var worksAtSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WORKS AT").scSectionLabel()
            FlowChips(spacing: 8) {
                ForEach(ProProfileScreen.spots, id: \.self) { spot in
                    Button {} label: {
                        HStack(spacing: 6) {
                            SCPinGlyph(height: 14)
                            Text(spot)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(SCColor.textPrimary)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .overlay(Capsule().stroke(SCColor.border, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var portfolioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PORTFOLIO").scSectionLabel()
            HStack(alignment: .top, spacing: 10) {
                ForEach(ProProfileScreen.portfolio, id: \.self) { title in
                    VStack(alignment: .leading, spacing: 6) {
                        SCMediaPlaceholder(showsPlayBadge: true)
                            .aspectRatio(16.0 / 10.0, contentMode: .fit)
                        Text(title)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(SCColor.textPrimary)
                    }
                }
            }
        }
    }

    private func outlinedTag(_ text: String, color: Color) -> some View {
        Text(text.uppercased())
            .font(SCFont.headingFixed(9.5))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .frame(height: 26)
            .overlay(Capsule().stroke(color == SCColor.accent ? SCColor.accent : SCColor.border, lineWidth: 1.5))
    }
}

private extension ProProfileScreen {
    static let styleTags = ["Street follow-lines", "Night / lighting"]
    static let gearTags = ["VX1000", "Fisheye", "Shotgun mic", "Cruiser"]
    static let spots = ["Lynch Family Skatepark", "Copley Library"]
    static let portfolio = ["Highlight reel", "Raw follow-line"]
}

#Preview {
    ProProfileScreen()
}
