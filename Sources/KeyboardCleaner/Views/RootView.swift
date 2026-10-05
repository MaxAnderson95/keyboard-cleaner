import SwiftUI

struct RootView: View {
    let session: CleaningSession

    private static let canvas = CGSize(width: 980, height: 860)

    var body: some View {
        ZStack {
            Backdrop(session: session)
            GeometryReader { geo in
                let scale = min(1, geo.size.width / Self.canvas.width, geo.size.height / Self.canvas.height)
                stage
                    .frame(width: Self.canvas.width, height: Self.canvas.height)
                    .scaleEffect(scale)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private var stage: some View {
        ZStack {
            switch session.phase {
            case .needsPermission:
                PermissionCard(session: session)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            case .ready, .cleaning:
                CleaningStage(session: session)
                    .transition(.opacity)
            case .finished:
                Farewell()
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.smooth(duration: 0.5), value: session.phase)
    }
}

private struct CleaningStage: View {
    let session: CleaningSession

    private var isCleaning: Bool { session.phase == .cleaning }

    var body: some View {
        VStack(spacing: 36) {
            VStack(spacing: 12) {
                Image(systemName: isCleaning ? "lock.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .contentTransition(.symbolEffect(.replace))
                Text(isCleaning ? "Keyboard locked" : "Couldn't lock the keyboard")
                    .font(.system(size: 40, weight: .semibold))
                    .contentTransition(.opacity)
                subtitle
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .frame(height: 44, alignment: .top)
            }
            VStack(spacing: 20) {
                KeyboardView(session: session)
                TrackpadView(session: session)
            }
            Group {
                if isCleaning {
                    ExitHoldBar(session: session)
                } else {
                    RetryControls(session: session)
                }
            }
            .frame(height: 96, alignment: .top)
            .transition(.opacity)
        }
        .animation(.smooth(duration: 0.4), value: isCleaning)
    }

    @ViewBuilder
    private var subtitle: some View {
        if isCleaning {
            let total = KeyboardLayout.allKeys.count
            let wiped = session.wipedKeys.intersection(KeyboardLayout.allKeys).count
            VStack(spacing: 10) {
                Text("\(wiped) of \(total) keys wiped\(session.trackpadWiped ? "  ·  trackpad wiped" : "")")
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(wiped)))
                    .animation(.snappy, value: wiped)
                ProgressView(value: Double(wiped), total: Double(total))
                    .progressViewStyle(MeterStyle())
                    .frame(width: 220)
            }
        } else {
            Text("Check Keyboard Cleaner's Accessibility access in System Settings, then try again.")
        }
    }
}

private struct RetryControls: View {
    let session: CleaningSession

    var body: some View {
        HStack(spacing: 12) {
            Button("Quit", action: session.quit)
                .keyboardShortcut(.cancelAction)
            Button("Try Again", action: session.startCleaning)
                .keyboardShortcut(.defaultAction)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
    }
}

/// The exit instruction, which turns into a filling bar and countdown while space is held.
private struct ExitHoldBar: View {
    let session: CleaningSession

    var body: some View {
        TimelineView(.animation(paused: session.exitHold.heldSince == nil)) { _ in
            let progress = session.exitHold.progress(at: .now)
            let secondsLeft = Int((5 * (1 - progress)).rounded(.up))
            let isHolding = progress > 0

            ZStack(alignment: .leading) {
                GeometryReader { geo in
                    Capsule()
                        .fill(.white.opacity(0.85))
                        .frame(width: max(geo.size.height, geo.size.width * progress))
                        .opacity(isHolding ? 1 : 0)
                }
                HStack(spacing: 8) {
                    if isHolding {
                        Text("Keep holding")
                        Text("\(secondsLeft)")
                            .monospacedDigit()
                            .contentTransition(.numericText(countsDown: true))
                            .animation(.snappy, value: secondsLeft)
                    } else {
                        Text("Hold")
                        KeyHint("space")
                        Text("for 5 seconds to finish")
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isHolding ? .black.opacity(0.8) : .white.opacity(0.7))
                .frame(maxWidth: .infinity)
            }
            .frame(width: 360, height: 46)
            .glassEffect(.regular, in: .capsule)
        }
    }
}

private struct KeyHint: View {
    let label: String
    init(_ label: String) { self.label = label }

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(.white.opacity(0.1)))
            .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(.white.opacity(0.2), lineWidth: 0.75))
    }
}

private struct MeterStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.12))
                Capsule()
                    .fill(.white.opacity(0.7))
                    .frame(width: geo.size.width * (configuration.fractionCompleted ?? 0))
                    .animation(.smooth, value: configuration.fractionCompleted)
            }
        }
        .frame(height: 4)
    }
}

private struct PermissionCard: View {
    let session: CleaningSession

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard")
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 68, height: 68)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            VStack(spacing: 8) {
                Text("Allow Accessibility access")
                    .font(.system(size: 24, weight: .semibold))
                Text("Keyboard Cleaner needs Accessibility access to pause your keyboard and trackpad while you clean. Nothing you type is recorded or sent anywhere.")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button("Open System Settings", action: session.requestPermission)
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Cleaning starts as soon as access is on.")
            }
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.45))

            Button("Quit", action: session.quit)
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.45))
                .keyboardShortcut(.cancelAction)
        }
        .padding(36)
        .frame(width: 480)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct Farewell: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.white.opacity(0.85))
                .symbolEffect(.bounce, value: appeared)
            Text("All clean")
                .font(.system(size: 40, weight: .semibold))
            Text("Let go of space to unlock.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.55))
        }
        .onAppear { appeared = true }
    }
}
