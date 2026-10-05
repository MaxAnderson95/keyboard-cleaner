import SwiftUI

/// A top-down MacBook keyboard. Keys light up while pressed and stay brighter once wiped.
struct KeyboardView: View {
    let session: CleaningSession

    private let pitch: CGFloat = 46
    private let gap: CGFloat = 6
    private var keyHeight: CGFloat { pitch - gap }

    var body: some View {
        VStack(spacing: gap) {
            HStack(spacing: gap) {
                ForEach(KeyboardLayout.functionRow) { key(for: $0, height: 26) }
            }
            ForEach(KeyboardLayout.rows.indices, id: \.self) { row in
                HStack(spacing: gap) {
                    ForEach(KeyboardLayout.rows[row]) { key(for: $0) }
                }
            }
            HStack(alignment: .bottom, spacing: gap) {
                ForEach(KeyboardLayout.bottomRow) { key(for: $0) }
                arrowCluster
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.white.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.25), radius: 30, y: 14)
        }
    }

    private var arrowCluster: some View {
        let half = (keyHeight - gap) / 2
        return HStack(alignment: .bottom, spacing: gap) {
            key(for: KeyboardLayout.arrowLeft, height: half)
            VStack(spacing: gap) {
                key(for: KeyboardLayout.arrowUp, height: half)
                key(for: KeyboardLayout.arrowDown, height: half)
            }
            key(for: KeyboardLayout.arrowRight, height: half)
        }
    }

    @ViewBuilder
    private func key(for cap: Keycap, height: CGFloat? = nil) -> some View {
        let width = cap.width * pitch - gap
        let size = CGSize(width: width, height: height ?? keyHeight)
        if let code = cap.code {
            KeycapView(
                cap: cap,
                size: size,
                isPressed: session.pressedKeys.contains(code),
                isWiped: session.wipedKeys.contains(code)
            )
            .overlay {
                if code == ExitHold.spaceBar, session.phase == .cleaning { SpaceHoldFill(session: session) }
            }
        } else {
            TouchIDKey(size: size)
        }
    }
}

private struct KeycapView: View {
    let cap: Keycap
    let size: CGSize
    let isPressed: Bool
    let isWiped: Bool

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
        shape
            .fill(fill)
            .overlay { shape.strokeBorder(.white.opacity(isWiped ? 0.2 : 0.1), lineWidth: 0.75) }
            .overlay { label }
            .frame(width: size.width, height: size.height)
            .scaleEffect(isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isPressed)
            .animation(.easeOut(duration: 0.8), value: isWiped)
    }

    private var fill: Color {
        if isPressed { return .white.opacity(0.85) }
        if isWiped { return .white.opacity(0.16) }
        return .white.opacity(0.05)
    }

    @ViewBuilder
    private var label: some View {
        Group {
            if let symbol = cap.symbol {
                Image(systemName: symbol).font(.system(size: size.height < 30 ? 10 : 12, weight: .medium))
            } else if cap.label.count == 1 {
                Text(cap.label).font(.system(size: 15, weight: .medium))
            } else {
                Text(cap.label).font(.system(size: 10, weight: .medium))
            }
        }
        .foregroundStyle(isPressed ? .black.opacity(0.8) : .white.opacity(isWiped ? 0.9 : 0.45))
    }
}

private struct TouchIDKey: View {
    let size: CGSize

    var body: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(.black.opacity(0.25))
            .overlay {
                Circle()
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                    .padding(5)
            }
            .frame(width: size.width, height: size.height)
    }
}

/// Fills the space bar left to right while the exit hold is in progress.
private struct SpaceHoldFill: View {
    let session: CleaningSession

    var body: some View {
        TimelineView(.animation(paused: session.exitHold.heldSince == nil)) { _ in
            let progress = session.exitHold.progress(at: .now)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(.white.opacity(0.85))
                    .frame(width: geo.size.width * progress)
            }
        }
        .allowsHitTesting(false)
    }
}

struct TrackpadView: View {
    let session: CleaningSession
    @State private var isTouched = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        shape
            .fill(.white.opacity(isTouched ? 0.22 : session.trackpadWiped ? 0.12 : 0.05))
            .overlay { shape.strokeBorder(.white.opacity(session.trackpadWiped ? 0.2 : 0.1), lineWidth: 1) }
            .overlay {
                Label("trackpad", systemImage: session.trackpadWiped ? "checkmark" : "hand.point.up.left")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(session.trackpadWiped ? 0.8 : 0.4))
            }
            .frame(width: 290, height: 176)
            .scaleEffect(isTouched ? 0.985 : 1)
            .animation(.easeOut(duration: 0.3), value: isTouched)
            .animation(.easeOut(duration: 0.8), value: session.trackpadWiped)
            .task(id: session.trackpadTouchedAt) {
                guard session.trackpadTouchedAt != nil else { return }
                isTouched = true
                try? await Task.sleep(for: .milliseconds(260))
                if !Task.isCancelled { isTouched = false }
            }
    }
}
