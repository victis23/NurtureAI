import SwiftUI
import ImageIO
import UniformTypeIdentifiers

// MARK: - GIF Frame Model

private struct GIFFrames {
    let images: [UIImage]
    let duration: Double
}

// MARK: - GIF Loader

private enum GIFLoader {
    static func load(named name: String) -> GIFFrames? {
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "gif"),
            let data = try? Data(contentsOf: url),
            let source = CGImageSourceCreateWithData(data as CFData, nil)
        else { return nil }

        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var totalDuration: Double = 0

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }

            let frameProps = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any]
            let gifProps   = frameProps?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
            let delay      = (gifProps?[kCGImagePropertyGIFUnclampedDelayTime as String]
                           ?? gifProps?[kCGImagePropertyGIFDelayTime as String]) as? Double ?? 0.1

            images.append(UIImage(cgImage: cgImage))
            totalDuration += delay
        }

        guard !images.isEmpty else { return nil }
        return GIFFrames(images: images, duration: totalDuration)
    }
}

// MARK: - Preloader (Observable)

@MainActor
@Observable
final class GIFPreloader {
    fileprivate var cache: [CharacterAnimation: GIFFrames] = [:]
    private(set) var isReady: Bool = false

    func preloadAll() async {
        await withTaskGroup(of: (CharacterAnimation, GIFFrames?).self) { group in
            for state in CharacterAnimation.allCases {
                group.addTask {
                    let frames = await Task.detached(priority: .userInitiated) {
						await GIFLoader.load(named: state.rawValue)
                    }.value
                    return (state, frames)
                }
            }
            for await (state, frames) in group {
                if let frames { cache[state] = frames }
            }
        }
        isReady = true
    }

    fileprivate func frames(for state: CharacterAnimation) -> GIFFrames? {
        cache[state]
    }
}

// MARK: - UIImageView GIF Renderer

private struct GIFImageView: UIViewRepresentable {
    let frames: GIFFrames

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode       = .scaleAspectFit
        view.clipsToBounds     = true
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        return view
    }

    func updateUIView(_ uiView: UIImageView, context: Context) {
        // Stop first so the new animation always starts from frame 0
        uiView.stopAnimating()
        uiView.animationImages   = frames.images
        uiView.animationDuration = frames.duration
        uiView.animationRepeatCount = 0        // loop forever
        uiView.image             = frames.images.first
        uiView.startAnimating()
    }
}

// MARK: - CharacterView

struct CharacterView: View {
    @Binding var state: CharacterAnimation

    @State private var preloader = GIFPreloader()
    @State private var currentFrames: GIFFrames?

    var body: some View {
        ZStack {
            if let frames = currentFrames {
                GIFImageView(frames: frames)
                    .id(state)           // forces UIViewRepresentable to recreate on state change
            } else {
                ProgressView()
            }
        }
        .task {
            await preloader.preloadAll()
            currentFrames = preloader.frames(for: state)
        }
        .onChange(of: state) { _, newState in
            // Swap immediately from cache — no loading flash
            currentFrames = preloader.frames(for: newState)
        }
    }
}

// MARK: - Preview

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
