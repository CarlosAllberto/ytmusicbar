import AppKit
import CoreAudio
import MediaPlayer

/// Liga as teclas de mídia do Mac ao player da página.
final class MediaControls {
    /// Última troca de saída de áudio (fone conectado ou desconectado).
    private var lastRouteChange = Date.distantPast

    /// Cada comando clica no botão equivalente do ytmusic-player-bar.
    init(run: @escaping (String) -> Void) {
        let c = MPRemoteCommandCenter.shared()
        func bind(_ cmd: MPRemoteCommand, _ js: String, when: (() -> Bool)? = nil) {
            cmd.isEnabled = true
            cmd.addTarget { _ in
                if when?() ?? true { run(js) }
                return .success
            }
        }
        let button = "document.querySelector('ytmusic-player-bar .play-pause-button')"
        let video = "document.querySelector('video')"
        // play e pause não podem alternar: o sistema os manda sozinho ao conectar ou desconectar o fone,
        // e um pause com a música já pausada a retomava.
        // Após uma troca de saída o play do sistema é ignorado, para a música pausada continuar pausada.
        bind(c.playCommand, "if (\(video)?.paused) \(button)?.click()") { [weak self] in
            Date().timeIntervalSince(self?.lastRouteChange ?? .distantPast) > 3
        }
        bind(c.pauseCommand, "if (\(video) && !\(video).paused) \(button)?.click()")
        bind(c.togglePlayPauseCommand, "\(button)?.click()")
        bind(c.nextTrackCommand, "document.querySelector('ytmusic-player-bar .next-button')?.click()")
        bind(c.previousTrackCommand, "document.querySelector('ytmusic-player-bar .previous-button')?.click()")
        watchAudioRoute()
    }

    private func watchAudioRoute() {
        for selector in [kAudioHardwarePropertyDefaultOutputDevice, kAudioHardwarePropertyDevices] {
            var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
            AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, .main) { [weak self] _, _ in
                self?.lastRouteChange = Date()
            }
        }
    }
}
