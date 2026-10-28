import AppKit
import MediaPlayer

/// Liga as teclas de mídia do Mac ao player da página e mostra a faixa atual no Now Playing.
final class MediaControls {
    private var artworkURL: String?
    private var artwork: MPMediaItemArtwork?

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

    /// Recebe o dicionário enviado por inject-media.js.
    func update(_ info: [String: Any]) {
        let center = MPNowPlayingInfoCenter.default()
        guard let title = info["title"] as? String, !title.isEmpty else {
            center.nowPlayingInfo = nil
            return
        }
        let playing = info["playing"] as? Bool ?? false
        var dict: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: info["artist"] as? String ?? "",
            MPMediaItemPropertyAlbumTitle: info["album"] as? String ?? "",
            MPNowPlayingInfoPropertyPlaybackRate: playing ? 1.0 : 0.0,
        ]
        if let d = info["duration"] as? Double, d.isFinite { dict[MPMediaItemPropertyPlaybackDuration] = d }
        if let p = info["position"] as? Double { dict[MPNowPlayingInfoPropertyElapsedPlaybackTime] = p }
        if let art = artwork { dict[MPMediaItemPropertyArtwork] = art }
        center.nowPlayingInfo = dict
        center.playbackState = playing ? .playing : .paused

        // Capa só é baixada quando a URL muda.
        if let url = info["artwork"] as? String, url != artworkURL, let u = URL(string: url) {
            artworkURL = url
            URLSession.shared.dataTask(with: u) { [weak self] data, _, _ in
                guard let data, let image = NSImage(data: data) else { return }
                let art = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                DispatchQueue.main.async {
                    self?.artwork = art
                    center.nowPlayingInfo?[MPMediaItemPropertyArtwork] = art
                }
            }.resume()
        }
    }
}
