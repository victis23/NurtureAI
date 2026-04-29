import SwiftUI
import AVFoundation
import Lottie

struct CharacterView: View {
    @Binding var state: CharacterAnimation

    var body: some View {
        Group {
            switch resolvedAsset(for: state) {
            case .video(let name):
                LoopingVideoView(animationName: name)
            case .lottie(let name):
                LottieView(animation: .named(name))
                    .playing(loopMode: .loop)
            case .none:
                Color.clear
            }
        }
        .id(state)
    }

    // Prefer HEVC video (real alpha, smaller, faster); fall back to Lottie JSON.
    private func resolvedAsset(for state: CharacterAnimation) -> CharacterAsset {
        let name = state.rawValue
        if Bundle.main.url(forResource: name, withExtension: "mov") != nil {
            return .video(name: name)
        }
        if Bundle.main.url(forResource: name, withExtension: "json") != nil {
            return .lottie(name: name)
        }
        return .none
    }
}

private enum CharacterAsset {
    case video(name: String)
    case lottie(name: String)
    case none
}

private struct LoopingVideoView: UIViewRepresentable {
    let animationName: String

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.load(animationName: animationName)
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) { }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: PlayerView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 0, height: proposal.height ?? 0)
    }
}

private final class PlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    private var looper: AVPlayerLooper?

    func load(animationName: String) {
        guard let url = Bundle.main.url(forResource: animationName, withExtension: "mov") else { return }

        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 1.0

        let queuePlayer = AVQueuePlayer()
        queuePlayer.automaticallyWaitsToMinimizeStalling = false
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)

        playerLayer.player = queuePlayer
        playerLayer.videoGravity = .resizeAspect
        queuePlayer.isMuted = true
        queuePlayer.play()
    }
}

#Preview {
    @Previewable @State var state: CharacterAnimation = .relaxing

    VStack(spacing: 24) {
        CharacterView(state: $state)
            .frame(width: 220, height: 220)

        HStack(spacing: 12) {
            ForEach(CharacterAnimation.allCases, id: \.self) { s in
                Button(s.rawValue) { state = s }
                    .buttonStyle(.bordered)
                    .tint(state == s ? .orange : .gray)
            }
        }
    }
    .padding()
}
