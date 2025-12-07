import { subscribeToGameFromDom } from "./game_channel"

// Auto-subscribe if the page includes a game root with data-game-id
document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('game-root')
  if (root && root.dataset && root.dataset.gameId) {
    const gid = root.dataset.gameId
    subscribeToGameFromDom(gid)
  }
})
