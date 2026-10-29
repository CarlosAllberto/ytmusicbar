import AppKit
import MediaPlayer

/// Liga as teclas de mídia do Mac ao player da página.
final class MediaControls {
    /// Cada comando clica no botão equivalente do ytmusic-player-bar.
    init(run: @escaping (String) -> Void) {
        let c = MPRemoteCommandCenter.shared()
        func bind(_ cmd: MPRemoteCommand, _ js: String) {
            cmd.isEnabled = true
            cmd.addTarget { _ in run(js); return .success }
        }
        let toggle = "document.querySelector('ytmusic-player-bar .play-pause-button')?.click()"
        bind(c.playCommand, toggle)
        bind(c.pauseCommand, toggle)
        bind(c.togglePlayPauseCommand, toggle)
        bind(c.nextTrackCommand, "document.querySelector('ytmusic-player-bar .next-button')?.click()")
        bind(c.previousTrackCommand, "document.querySelector('ytmusic-player-bar .previous-button')?.click()")
    }
}
