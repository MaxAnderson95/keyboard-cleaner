import SwiftUI

/// The see-through tint over the desktop. It lightens on the way out so the desktop comes back first.
struct Backdrop: View {
    let session: CleaningSession

    var body: some View {
        let phase = session.phase
        ZStack {
            Color.black.opacity(phase == .finished ? 0.15 : 0.78)
            RadialGradient(
                colors: [.clear, .black.opacity(0.2)],
                center: .center, startRadius: 200, endRadius: 1300
            )
        }
        .ignoresSafeArea()
        .animation(.smooth(duration: 0.9), value: phase)
    }
}
