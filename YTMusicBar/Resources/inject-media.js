// Envia o estado da faixa (navigator.mediaSession) para o app, que alimenta o Now Playing.
(() => {
  if (window.__ytmMedia) return; // guard: não rodar duas vezes
  window.__ytmMedia = true;

  let last = '';
  setInterval(() => {
    try {
      const m = navigator.mediaSession && navigator.mediaSession.metadata;
      const video = document.querySelector('video');
      const art = m && m.artwork && m.artwork.length ? m.artwork[m.artwork.length - 1].src : '';
      const info = {
        title: m ? m.title : '',
        artist: m ? m.artist : '',
        album: m ? m.album : '',
        artwork: art,
        playing: !!video && !video.paused,
        duration: video && isFinite(video.duration) ? video.duration : 0,
        position: video ? Math.floor(video.currentTime) : 0,
      };
      // Só envia quando algo muda (posição em passos de 1 s).
      const key = JSON.stringify(info);
      if (key === last) return;
      last = key;
      window.webkit.messageHandlers.nowplaying.postMessage(info);
    } catch (e) {}
  }, 1000);
})();
